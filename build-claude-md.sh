#!/usr/bin/env bash
# Regenerate Claude Code, OpenCode, omp, and Crush global rules from fragments/,
# and install the pinned agent skills from agent-skills.txt into ~/.agents/skills.
# omp and Crush have no session-start hook, so their copy also gets the
# activation block (caveman/Ponytail off by default, role table loads them).
# Source of truth = fragments/*.md in this repo. Do NOT hand-edit generated
# rule files directly -- edit a fragment here and re-run this script.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$REPO/.claude-settings.local"

# Omit --targets for every harness whose CLI is on PATH (skipped ones are printed).
# --claude-dir picks the one Claude config folder under HOME written per run
# (default .claude); run again for another account folder.
TARGETS=
CLAUDE_DIR=
usage() {
  echo "usage: $0 [--targets claude,crush,omp,opencode] [--claude-dir .claude]" >&2
  exit 1
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --targets)
      [[ $# -ge 2 && "$2" =~ ^(claude|crush|omp|opencode)(,(claude|crush|omp|opencode))*$ ]] || usage
      TARGETS="$2"; shift 2 ;;
    --claude-dir)
      [[ $# -ge 2 && -n "$2" && "$2" != */* && "$2" != . && "$2" != .. ]] || usage
      CLAUDE_DIR="$2"; shift 2 ;;
    *) usage ;;
  esac
done
if [[ -z "$TARGETS" ]]; then
  for t in claude crush omp opencode; do
    if command -v "$t" >/dev/null || [[ $t == claude && -n "$CLAUDE_DIR" ]]; then
      TARGETS+="${TARGETS:+,}$t"
    else
      echo "skip $t (not on PATH)"
    fi
  done
fi
has() { [[ ",$TARGETS," == *,"$1",* ]]; }
if [[ -n "$CLAUDE_DIR" ]] && ! has claude; then
  echo "--claude-dir requires the claude target" >&2
  exit 1
fi
CLAUDE_DIR="${CLAUDE_DIR:-.claude}"

# Skills are installed with the `skills` CLI via npx; without it the build would
# leave ~/.agents/skills stale, so fail before writing anything (including the
# first-run config file).
if ! command -v npx >/dev/null; then
  echo "npx (node) is required to install agent skills; nothing written" >&2
  exit 1
fi

# The three-man-team fork is cloned next to this repo by dev-base (repos.txt +
# bootstrap.sh); its templates are deployed to a harness-neutral path below.
DEVBASE="$(dirname "$REPO")"
TMT="$DEVBASE/three-man-team"
if [[ ! -f "$DEVBASE/repos.txt" || ! -d "$TMT/templates" ]]; then
  echo "this repo must sit in dev-base next to three-man-team (run dev-base/bootstrap.sh); nothing written" >&2
  exit 1
fi

if [[ -f "$CONFIG" ]]; then
  read -r setting < "$CONFIG"
  if [[ "$setting" != INCLUDE_FOREMAN=* ]]; then
    echo "invalid $CONFIG: expected INCLUDE_FOREMAN=true|false" >&2
    exit 1
  fi
  INCLUDE_FOREMAN="${setting#INCLUDE_FOREMAN=}"
elif [[ -z "${INCLUDE_FOREMAN:-}" ]]; then
  if [[ ! -t 0 ]]; then
    echo "first build requires INCLUDE_FOREMAN=true|false" >&2
    exit 1
  fi
  read -r -p "Include Foreman integration? [y/N] " answer
  case "$answer" in
    y|Y|yes|YES) INCLUDE_FOREMAN=true ;;
    *) INCLUDE_FOREMAN=false ;;
  esac
fi

case "$INCLUDE_FOREMAN" in
  true)
    if ! command -v foreman >/dev/null 2>&1; then
      echo "Foreman is not installed; install it or choose INCLUDE_FOREMAN=false" >&2
      exit 1
    fi
    ;;
  false) ;;
  *)
    echo "INCLUDE_FOREMAN must be true or false" >&2
    exit 1
    ;;
esac

if [[ ! -f "$CONFIG" ]]; then
  printf 'INCLUDE_FOREMAN=%s\n' "$INCLUDE_FOREMAN" > "$CONFIG"
fi

FRAGMENTS=(
  "$REPO/fragments/00-core.md"
)
[[ "$INCLUDE_FOREMAN" == true ]] && FRAGMENTS+=("$REPO/fragments/05-foreman.md")
FRAGMENTS+=("$REPO/fragments/10-three-man-team.md")

OUT="$(mktemp)"
ACT="$(mktemp)"
trap 'rm -f "$OUT" "$ACT"' EXIT

for i in "${!FRAGMENTS[@]}"; do
  [[ "$i" -gt 0 ]] && echo >> "$OUT"
  cat "${FRAGMENTS[$i]}" >> "$OUT"
done
{ cat "$OUT"; echo; cat "$REPO/fragments/90-activation.md"; } > "$ACT"

write() { mkdir -p "$(dirname "$2")"; cp "$1" "$2"; echo "wrote $2"; }

if has claude; then write "$OUT" "$HOME/$CLAUDE_DIR/CLAUDE.md"; fi
if has opencode; then write "$OUT" "$HOME/.config/opencode/AGENTS.md"; fi
if has omp; then write "$ACT" "$HOME/.omp/agent/AGENTS.md"; fi
if has crush; then write "$ACT" "$HOME/.config/crush/CRUSH.md"; fi

# Templates -> ~/.config/agent-rules (harness-neutral, like ~/.config/machine-context).
# three-man-team is a plain copy of the fork's templates/ (no .git); SOURCE records
# the clone path and commit so sync prompts can diff against the git clone.
RULES="$HOME/.config/agent-rules"
for template in project-rules.md .claudeignore; do
  write "$REPO/templates/$template" "$RULES/$template"
done
rm -rf "$RULES/three-man-team"
mkdir -p "$RULES/three-man-team"
cp -R "$TMT/templates" "$RULES/three-man-team/templates"
printf 'clone=%s\ncommit=%s\n' "$TMT" "$(git -C "$TMT" rev-parse --short HEAD)" > "$RULES/three-man-team/SOURCE"
echo "wrote $RULES/three-man-team (templates + SOURCE)"

# Agent skills -> ~/.agents/skills (read by OpenCode v2, omp, and Crush; Claude Code
# uses its own plugins). Source = agent-skills.txt, fetched at the pinned ref with the
# `skills` CLI (needs node + network). Provenance: ~/.agents/.skill-lock.json.
SKILLS_CLI="skills@1.7.2"
while read -r repo ref names; do
  [[ -z "$repo" || "$repo" == \#* ]] && continue
  args=()
  for n in $names; do args+=(-s "$n"); done
  if ! npx -y "$SKILLS_CLI" add "https://github.com/$repo/tree/$ref" -g -a pi "${args[@]}" -y >"$OUT" 2>&1 </dev/null; then
    cat "$OUT" >&2; echo "skills add failed for $repo@$ref" >&2; exit 1
  fi
  echo "installed $repo@$ref: $names"
done < "$REPO/agent-skills.txt"
