#!/usr/bin/env bash
# Regenerate ~/.claude/CLAUDE.md and ~/.claude-personal/CLAUDE.md from fragments/.
# Source of truth = fragments/*.md in this repo. Do NOT hand-edit the generated
# CLAUDE.md files directly -- edit a fragment here and re-run this script.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAGMENTS=(
  "$REPO/fragments/00-core.md"
  "$REPO/fragments/10-three-man-team.md"
)

OUT="$(mktemp)"
trap 'rm -f "$OUT"' EXIT

for i in "${!FRAGMENTS[@]}"; do
  [[ "$i" -gt 0 ]] && echo >> "$OUT"
  cat "${FRAGMENTS[$i]}" >> "$OUT"
done

for dest in "$HOME/.claude/CLAUDE.md" "$HOME/.claude-personal/CLAUDE.md"; do
  cp "$OUT" "$dest"
  echo "wrote $dest"
done
