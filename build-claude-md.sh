#!/usr/bin/env bash
# Regenerate identical Claude Code and OpenCode global rules from fragments/.
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
trap 'rm -f "$OUT"' EXIT

for i in "${!FRAGMENTS[@]}"; do
  [[ "$i" -gt 0 ]] && echo >> "$OUT"
  cat "${FRAGMENTS[$i]}" >> "$OUT"
done

for dest in "$HOME/.claude/CLAUDE.md" "$HOME/.claude-personal/CLAUDE.md" "$HOME/.config/opencode/AGENTS.md"; do
  mkdir -p "$(dirname "$dest")"
  cp "$OUT" "$dest"
  echo "wrote $dest"
done

for template in project-rules.md OPERATOR.md; do
  for dest in "$HOME/.claude/templates/$template" "$HOME/.config/opencode/templates/$template"; do
    mkdir -p "$(dirname "$dest")"
    cp "$REPO/templates/$template" "$dest"
    echo "wrote $dest"
  done
done
