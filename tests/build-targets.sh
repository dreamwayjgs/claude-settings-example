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

for name in default all both claude personal crush omp opencode; do
  args=()
  case "$name" in
    default) expected='0 2 3 4' ;;
    all) args=(--targets claude,crush,omp,opencode); expected='0 2 3 4' ;;
    both) args=(--targets omp,opencode); expected='2 3' ;;
    claude) args=(--targets claude); expected='0' ;;
    personal) args=(--targets claude --claude-dir .claude-personal); expected='1' ;;
    crush) args=(--targets crush); expected='4' ;;
    omp) args=(--targets omp); expected='3' ;;
    opencode) args=(--targets opencode); expected='2' ;;
  esac
  HOME="$ROOT/$name" bash "$BUILD" "${args[@]}" > /dev/null
  for i in "${!paths[@]}"; do
    file="$ROOT/$name/${paths[$i]}"
    if [[ " $expected " == *" $i "* ]]; then
      [[ -f "$file" ]]
      # Any Claude config folder gets the same content as the default .claude one.
      [[ "$name" == default ]] || cmp "$file" "$ROOT/default/${paths[$i]/.claude-personal/.claude}"
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
invalid=(
  "--targets typo" "--targets omp,typo" "--targets ''" "--targets omp," "--targets"
  "--claude-dir" "--claude-dir ''" "--claude-dir a/b" "--claude-dir .." "--claude-dir ."
  "--targets omp --claude-dir .claude-personal" "--unknown"
)
for value in "${invalid[@]}"; do
  eval "args=($value)"
  if HOME="$ROOT/invalid" bash "$BUILD" "${args[@]}" > /dev/null 2>&1; then
    echo "invalid arguments accepted: $value" >&2; exit 1
  fi
  [[ ! -e "$ROOT/invalid" ]]
done
echo 'PASS: invalid arguments fail before writing'
