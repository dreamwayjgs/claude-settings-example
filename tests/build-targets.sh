#!/usr/bin/env bash
# Isolated rule generation; npx is stubbed, no harness CLI is invoked.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT
mkdir -p "$ROOT/dev-base/settings" "$ROOT/dev-base/three-man-team/templates"
touch "$ROOT/dev-base/repos.txt"
cp "$REPO/build-claude-md.sh" "$REPO/agent-skills.txt" "$ROOT/dev-base/settings/"
cp -R "$REPO/fragments" "$REPO/templates" "$ROOT/dev-base/settings/"
printf 'INCLUDE_FOREMAN=false\n' > "$ROOT/dev-base/settings/.claude-settings.local"
git -C "$ROOT/dev-base/three-man-team" init -q
git -C "$ROOT/dev-base/three-man-team" -c user.name=Test -c user.email=test@example.invalid commit -q --allow-empty -m fixture
npx() { return 0; }
export -f npx
BUILD="$ROOT/dev-base/settings/build-claude-md.sh"
paths=(.claude/CLAUDE.md .claude-personal/CLAUDE.md .config/opencode/AGENTS.md .omp/agent/AGENTS.md .config/crush/CRUSH.md)

for name in default both omp opencode; do
  args=()
  case "$name" in
    default) expected='0 1 2 3 4' ;;
    both) args=(--targets omp,opencode); expected='2 3' ;;
    omp) args=(--targets omp); expected='3' ;;
    opencode) args=(--targets opencode); expected='2' ;;
  esac
  HOME="$ROOT/$name" bash "$BUILD" "${args[@]}" > /dev/null
  for i in "${!paths[@]}"; do
    file="$ROOT/$name/${paths[$i]}"
    if [[ " $expected " == *" $i "* ]]; then
      [[ -f "$file" ]]
      [[ "$name" == default ]] || cmp "$file" "$ROOT/default/${paths[$i]}"
    else
      [[ ! -e "$file" ]]
    fi
  done
  [[ -f "$ROOT/$name/.config/agent-rules/three-man-team/SOURCE" ]]
  echo "PASS: $name"
done
mkdir -p "$ROOT/both/.config/crush"
printf keep > "$ROOT/both/.config/crush/CRUSH.md"
HOME="$ROOT/both" bash "$BUILD" --targets omp,opencode > /dev/null
[[ "$(cat "$ROOT/both/.config/crush/CRUSH.md")" == keep ]]
echo 'PASS: non-selected file preserved'
for value in typo omp,claude crush '' omp,; do
  if HOME="$ROOT/invalid" bash "$BUILD" --targets "$value" > /dev/null 2>&1; then
    echo "invalid target accepted: $value" >&2; exit 1
  fi
  [[ ! -e "$ROOT/invalid" ]]
done
if HOME="$ROOT/invalid" bash "$BUILD" --targets > /dev/null 2>&1; then
  echo 'missing targets accepted' >&2; exit 1
fi
echo 'PASS: invalid and deferred targets fail before writing'
