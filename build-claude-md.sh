#!/usr/bin/env bash
# Regenerate Claude Code, OpenCode, omp, and Crush global rules from fragments/.
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

# Claude plugin skills -> ~/.agents/skills (read by omp and Crush by default).
# Re-run after a Claude plugin update: install paths carry the version.
PLUGINS="$HOME/.claude/plugins/installed_plugins.json"
SKIP_SKILLS=" qmd@qmd/release "
if [[ -f "$PLUGINS" ]] && command -v jq >/dev/null; then
  while IFS=$'\t' read -r plugin path; do
    for skill in "$path"/skills/*/; do
      [[ -f "$skill/SKILL.md" ]] || continue
      name="$(basename "$skill")"
      [[ "$SKIP_SKILLS" == *" $plugin/$name "* ]] && continue
      rm -rf "$HOME/.agents/skills/$name"
      mkdir -p "$HOME/.agents/skills"
      cp -r "$skill" "$HOME/.agents/skills/$name"
      echo "wrote $HOME/.agents/skills/$name"
    done
  done < <(jq -r '.plugins | to_entries[] | "\(.key)\t\(.value[0].installPath)"' "$PLUGINS")
else
  echo "skip skills: need $PLUGINS and jq"
fi
