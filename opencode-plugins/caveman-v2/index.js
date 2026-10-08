// caveman — opencode plugin (V2)
//
// Writes the configured default mode to the flag file and injects the filtered
// ruleset into the system prompt while a mode is active.
//
// V1 -> V2 mapping:
//   - export default async (ctx) => ({ event, 'chat.message',
//     'experimental.chat.system.transform' })   ← V1 hook keys, dropped in V2
//       → export default { id, setup(ctx) } with ctx.event.subscribe and
//         ctx.session.hook('context' | 'compaction' | 'generate' | 'title')
//   - output.system was string[]; V2 event.system is a list of
//     { type: 'text', text } entries.
//
// Deliberate omission: the V1 plugin parsed user prompts for `/caveman <level>`
// in a 'chat.message' hook. V2 routes that through
// ctx.session.hook('prompt', ...). This patch does not register it — dynamic
// mid-session mode switching is not used on this machine, and the always-on
// ruleset in ~/.config/opencode/AGENTS.md covers the base mode. Re-add the hook
// if per-session switching comes back.
//
// Layout:
//   ~/.config/opencode/plugins/caveman/
//   ├── package.json
//   ├── index.js              ← this file (V2 entrypoint)
//   ├── plugin.js             ← upstream V1 plugin, kept for reference
//   ├── caveman-config.cjs    ← upstream, loaded below
//   └── caveman-parse.cjs     ← upstream, not needed by this patch

import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join } from 'node:path';
import { readFileSync, unlinkSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));

// Bun-compiled opencode rejects require() of on-disk files, so evaluate the
// CommonJS helper by hand. Same pattern as the ponytail V2 patch, and required
// for the same reason: this is a real file on disk, not a bundled module.
function loadCJS(target) {
  const code = readFileSync(target, 'utf8').replace(/^#![^\n]*\n/, '');
  const mod = { exports: {} };
  const targetRequire = createRequire(pathToFileURL(target).href);
  new Function('module', 'exports', 'require', '__dirname', '__filename', code)(
    mod, mod.exports, targetRequire, dirname(target), target
  );
  return mod.exports;
}

const config = loadCJS(join(here, 'caveman-config.cjs'));
const { getDefaultMode, safeWriteFlag, readFlag } = config;
// See the note in the upstream V1 plugin: recordModeChange is the newest export
// and an installed caveman-config.cjs may predate it. History logging is
// best-effort, so a no-op stub is the honest fallback.
const recordModeChange = config.recordModeChange || function () {};

// opencode resolves its config dir from $XDG_CONFIG_HOME, else ~/.config/opencode
// on every platform — including Windows, where it is %USERPROFILE%\.config\opencode
// (NOT %APPDATA%).
const opencodeDir = process.env.XDG_CONFIG_HOME
  ? path.join(process.env.XDG_CONFIG_HOME, 'opencode')
  : path.join(os.homedir(), '.config', 'opencode');
const flagPath = path.join(opencodeDir, '.caveman-active');

function removeFlag() {
  try {
    unlinkSync(flagPath);
  } catch (error) {
    if (process.env.CAVEMAN_DEBUG === '1' && error.code !== 'ENOENT') {
      console.error(`caveman: failed to remove flag ${flagPath}: ${error.message}`);
    }
  }
}

function reinforcementBanner(mode) {
  return 'CAVEMAN MODE ACTIVE (' + mode + ') — session ruleset applies.';
}

// The shared loader probes <base>/../../skills and <base>/../skills. opencode has
// no CLAUDE_PLUGIN_ROOT, and two layouts must be covered: `here` resolves the
// installed tree (~/.config/opencode/plugins/caveman → ~/.config/opencode/skills)
// and the parent resolves the upstream source tree (src/plugins/opencode →
// repo-root skills).
function loadFilteredRuleset(mode) {
  if (typeof config.loadFilteredRuleset !== 'function') return null;
  for (const base of [here, join(here, '..')]) {
    const ruleset = config.loadFilteredRuleset(mode, base);
    if (ruleset) return ruleset;
  }
  return null;
}

function reinforcementLine(mode) {
  const banner = reinforcementBanner(mode);
  const ruleset = loadFilteredRuleset(mode);
  return ruleset ? banner + '\n\n' + ruleset : banner;
}

// Re-assert the flag for each new session, so a new session in a long-lived
// server process picks up the configured default rather than inheriting nothing.
function assertFlag() {
  const mode = getDefaultMode();
  if (mode === 'off') {
    recordModeChange(opencodeDir, null);
    removeFlag();
    return;
  }
  recordModeChange(opencodeDir, mode);
  safeWriteFlag(flagPath, mode);
}

export default {
  id: 'caveman',

  async setup(ctx) {
    // Same race the V1 plugin covered with a factory-time write: in one-shot
    // `opencode run` the first session event can publish before the event
    // subscription is wired.
    assertFlag();

    // ── Event stream: re-assert the flag per session ───────────────────────
    const controller = new AbortController();
    void (async () => {
      try {
        for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
          if (event && event.type === 'session.created') assertFlag();
        }
      } catch (e) {
        if (process.env.CAVEMAN_DEBUG === '1') {
          console.error(`caveman: event subscription ended: ${e.message}`);
        }
      }
    })();

    // ── System prompt injection ────────────────────────────────────────────
    const injectRuleset = (event) => {
      if (!event || !Array.isArray(event.system)) return;
      const active = readFlag(flagPath);
      if (!active || active === 'off') return;
      const line = reinforcementLine(active);
      const last = event.system[event.system.length - 1];
      if (last && last.type === 'text') {
        last.text += '\n\n' + line;
      } else {
        event.system.push({ type: 'text', text: line });
      }
    };

    // V1 only injected on the agent loop. V2 splits the agent loop
    // ('context') from compaction, transient generate, and title requests, and a
    // hook registered for one kind does not fire for the others.
    await ctx.session.hook('context', injectRuleset);

    return () => controller.abort();
  },
};
