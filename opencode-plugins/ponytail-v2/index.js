// ponytail — opencode plugin (V2)
//
// Injects the ponytail ruleset into every chat's system prompt at the active
// intensity, persists /ponytail mode switches, and registers slash commands.
//
// V1 -> V2 mapping:
//   - config hook (ctx.config.command / ctx.config.skills mutation)
//       → ctx.command.transform + ctx.skill.transform (V2 has no ctx.config)
//   - experimental.chat.system.transform → ctx.session.hook('context', ...)
//   - command.execute.before   → owned command execute() + prompt-hook parsing
//
// Layout:
//   ~/.config/opencode/plugins/ponytail/
//   ├── package.json
//   └── index.js              ← this file

import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));

// Bun-compiled opencode rejects require() of on-disk files, so load the
// CommonJS helpers by evaluating them by hand (same pattern as caveman).
function loadCJS(target) {
  const code = readFileSync(target, 'utf8').replace(/^#![^\n]*\n/, '');
  const mod = { exports: {} };
  const targetRequire = createRequire(target);
  new Function('module', 'exports', 'require', '__dirname', '__filename', code)(
    mod, mod.exports, targetRequire, dirname(target), target
  );
  return mod.exports;
}

const pkgRoot = join(here, 'node_modules', '@dietrichgebert', 'ponytail');
const { getPonytailInstructions } = loadCJS(join(pkgRoot, 'hooks', 'ponytail-instructions.js'));
const { getDefaultMode, normalizePersistedMode } = loadCJS(join(pkgRoot, 'hooks', 'ponytail-config.js'));

// OpenCode has no flag-file convention of its own; keep mode beside its config.
const statePath = path.join(
  process.env.XDG_CONFIG_HOME || path.join(os.homedir(), '.config'),
  'opencode',
  '.ponytail-active',
);

function readMode() {
  try {
    return normalizePersistedMode(readFileSync(statePath, 'utf8').trim()) || getDefaultMode();
  } catch (e) {
    return getDefaultMode();
  }
}

function writeMode(mode) {
  try {
    mkdirSync(path.dirname(statePath), { recursive: true });
    writeFileSync(statePath, mode);
  } catch (e) {}
}

// Bare /ponytail (upstream #639): already on -> keep the level (null = no write);
// off -> the default level, or full when the default is off too.
function bareMode() {
  if (readMode() !== 'off') return null;
  const fallback = getDefaultMode();
  return fallback === 'off' ? 'full' : fallback;
}

// Parse a prompt for /ponytail commands. Returns the new mode to write, or null.
function parseModeChange(promptRaw) {
  let prompt = (promptRaw || '').trim();
  const wrapped = /^(["'`])([\s\S]*)\1$/.exec(prompt);
  if (wrapped) prompt = wrapped[2].trim();
  prompt = prompt.toLowerCase();
  if (!prompt) return null;

  if (prompt.startsWith('/ponytail')) {
    const parts = prompt.split(/\s+/);
    const arg = parts[1] || '';
    if (!arg) return bareMode();
    if (arg === 'off' || arg === 'stop' || arg === 'disable') return 'off';
    const mode = normalizePersistedMode(arg);
    return mode || null;
  }
  return null;
}

function parseCommandFile(filePath) {
  const content = readFileSync(filePath, 'utf8');
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n([\s\S]*)$/);
  if (!match) return null;
  const description = match[1].match(/description:\s*(.+)/)?.[1]?.trim();
  return { description, template: match[2].trim() };
}

function loadCommandDefs() {
  const candidates = [
    join(here, 'node_modules', '@dietrichgebert', 'ponytail', '.opencode', 'command'),
    join(here, '..', '..', 'node_modules', '@dietrichgebert', 'ponytail', '.opencode', 'command'),
  ];
  const dir = candidates.find((d) => existsSync(d));
  if (!dir) return [];
  const defs = [];
  try {
    for (const file of readdirSync(dir).filter((f) => f.endsWith('.md'))) {
      try {
        const parsed = parseCommandFile(join(dir, file));
        if (parsed && parsed.template) {
          defs.push({ name: path.basename(file, '.md'), ...parsed });
        }
      } catch (e) {}
    }
  } catch (e) {}
  return defs;
}

function loadSkillDefs() {
  const skillsRoot = join(pkgRoot, 'skills');
  let dirs = [];
  try {
    dirs = readdirSync(skillsRoot, { withFileTypes: true })
      .filter((d) => d.isDirectory())
      .map((d) => d.name);
  } catch (e) {
    return [];
  }
  const defs = [];
  for (const dir of dirs) {
    const file = join(skillsRoot, dir, 'SKILL.md');
    try {
      if (!existsSync(file)) continue;
      const content = readFileSync(file, 'utf8');
      const fm = content.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/);
      const head = fm ? fm[1] : '';
      const id = head.match(/^name:\s*(\S+)/m)?.[1]?.trim() || dir;
      const descMatch = head.match(/^description:\s*>?\s*\n?((?:[ ]+.+\n?)+)/m) || head.match(/^description:\s*(.+)/m);
      const description = descMatch ? descMatch[1].replace(/\n\s+/g, ' ').trim() : undefined;
      defs.push({ id, name: id, description, location: file, content });
    } catch (e) {}
  }
  return defs;
}

function argsFromPrompt(promptText, commandName) {
  const raw = String(promptText || '').trim().replace(/^["'`]|["'`]$/g, '').trim();
  const withoutSlash = raw.replace(new RegExp('^/' + commandName + '\\b', 'i'), '').trim();
  return withoutSlash;
}

export default {
  id: 'ponytail',

  async setup(ctx) {
    // ── 1. Slash commands via domain transform (no ctx.config in V2) ──────
    const defs = loadCommandDefs();
    if (defs.length && ctx.command && typeof ctx.command.transform === 'function') {
      await ctx.command.transform((editor) => {
        for (const d of defs) {
          editor.add({
            name: d.name,
            description: d.description,
            execute: async ({ sessionID, prompt, delivery }) => {
              const args = argsFromPrompt(prompt && prompt.text, d.name);
              if (d.name === 'ponytail') {
                const mode = args ? normalizePersistedMode(args) : bareMode();
                if (mode) writeMode(mode);
              }
              const text = d.template.replaceAll('$ARGUMENTS', args);
              await ctx.session.prompt({ sessionID, text, delivery });
            },
          });
        }
      });
    }

    // ── 2. Skills via domain transform ─────────────────────────────────────
    const skills = loadSkillDefs();
    if (skills.length && ctx.skill && typeof ctx.skill.transform === 'function') {
      await ctx.skill.transform((editor) => {
        for (const s of skills) {
          try {
            if (!editor.get(s.id)) editor.add(s);
          } catch (e) {}
        }
      });
    }

    // ── 3. Prompt hook: parse /ponytail commands ──────────────────────────
    await ctx.session.hook('prompt', (event) => {
      const change = parseModeChange(event.prompt && event.prompt.text);
      if (change) writeMode(change);
    });

    // ── 4. System prompt injection ─────────────────────────────────────────
    const injectRuleset = (event) => {
      if (!event || !Array.isArray(event.system)) return;
      const mode = readMode();
      if (mode === 'off') return;
      const instructions = getPonytailInstructions(mode);
      if (event.system.length > 0) {
        const last = event.system[event.system.length - 1];
        if (last && last.type === 'text') {
          last.text += '\n\n' + instructions;
        } else {
          event.system.push({ type: 'text', text: instructions });
        }
      } else {
        event.system.push({ type: 'text', text: instructions });
      }
    };

    for (const kind of ['context', 'compaction', 'generate', 'title']) {
      await ctx.session.hook(kind, injectRuleset);
    }
  },
};
