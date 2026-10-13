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

# Skills are installed with the `skills` CLI via npx; without it the build would
# leave ~/.agents/skills stale, so fail before writing anything.
if ! command -v npx >/dev/null; then
  echo "npx (node) is required to install agent skills; nothing written" >&2
  exit 1
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

for dest in "$HOME/.claude/CLAUDE.md" "$HOME/.claude-personal/CLAUDE.md" "$HOME/.config/opencode/AGENTS.md"; do
  write "$OUT" "$dest"
done
for dest in "$HOME/.omp/agent/AGENTS.md" "$HOME/.config/crush/CRUSH.md"; do
  write "$ACT" "$dest"
done

for template in project-rules.md .claudeignore; do
  for dir in "$HOME/.claude/templates" "$HOME/.config/opencode/templates" "$HOME/.omp/agent/templates" "$HOME/.config/crush/templates"; do
    write "$REPO/templates/$template" "$dir/$template"
  done
done

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
