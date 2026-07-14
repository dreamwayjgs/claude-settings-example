#!/bin/bash
# statusLine for Claude Code — bash+jq port of statusline.ps1
# Segments: [caveman badge] | model | dir | Ctx:N%
# Registered in settings.json:
#   "statusLine": { "type": "command", "command": "bash /path/to/statusline.sh" }

ESC=$'\033'
RESET="${ESC}[0m"
DIM="${ESC}[2m"

# --- Read stdin JSON (session/context/cwd info) ---
raw="$(cat)"
[ -z "$raw" ] && raw="{}"

j() { printf '%s' "$raw" | jq -r "$1" 2>/dev/null; }

# --- Caveman badge (preserved: keep as first segment if script present, else omit) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAVEMAN_SCRIPT="$SCRIPT_DIR/hooks/caveman-statusline.sh"
caveman_badge=""
if [ -f "$CAVEMAN_SCRIPT" ]; then
  caveman_badge="$(bash "$CAVEMAN_SCRIPT" 2>/dev/null)"
fi

# --- Current working directory (prefer workspace.current_dir, then cwd) ---
cwd="$(j '.workspace.current_dir // .cwd // empty')"
[ -z "$cwd" ] && cwd="$PWD"
dir_name="$(basename "$cwd")"
[ -z "$dir_name" ] && dir_name="$cwd"

# --- Remaining context window percentage ---
# Prefer pre-calculated context_window fields; fall back to transcript usage.
remaining=""
rp="$(j '.context_window.remaining_percentage // empty')"
up="$(j '.context_window.used_percentage // empty')"
if [ -n "$rp" ]; then
  remaining="$rp"
elif [ -n "$up" ]; then
  remaining="$(awk -v u="$up" 'BEGIN{print 100-u}')"
fi

if [ -z "$remaining" ]; then
  # Fallback: compute from transcript_path jsonl (last usage-bearing message).
  tp="$(j '.transcript_path // empty')"
  tokens=""
  if [ -n "$tp" ] && [ -f "$tp" ]; then
    tokens="$(tail -n 400 "$tp" 2>/dev/null | jq -rs '
      [ .[] | .message.usage | select(.input_tokens != null)
        | (.input_tokens + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)) ]
      | last // empty' 2>/dev/null)"
  fi
  if [ -n "$tokens" ]; then
    limit=200000
    mid="$(j '.model.id // empty') $(j '.model.display_name // empty')"
    case "$mid" in *1m*) limit=1000000 ;; esac
    remaining="$(awk -v t="$tokens" -v l="$limit" 'BEGIN{print (l-t)/l*100}')"
  fi
fi

ctx_text=""
if [ -n "$remaining" ]; then
  ctx_text="$(awk -v r="$remaining" 'BEGIN{ if(r<0)r=0; printf "Ctx:%.0f%%", r}')"
fi

# --- Model name ---
model_name="$(j '.model.display_name // empty')"

# --- Rate limit usage (Pro/Max only; absent otherwise) ---
rl_five_pct="$(j '.rate_limits.five_hour.used_percentage // empty')"
rl_five_reset="$(j '.rate_limits.five_hour.resets_at // empty')"
rl_week_pct="$(j '.rate_limits.seven_day.used_percentage // empty')"
rl_week_reset="$(j '.rate_limits.seven_day.resets_at // empty')"
now="$(date +%s)"

five_text=""
if [ -n "$rl_five_pct" ] && [ -n "$rl_five_reset" ]; then
  five_text="$(awk -v p="$rl_five_pct" -v reset="$rl_five_reset" -v now="$now" 'BEGIN{
    rem=reset-now; if(rem<0)rem=0
    h=int(rem/3600); m=int((rem%3600)/60)
    printf "%.0f%%(%dh%dm)", p, h, m
  }')"
fi

week_text=""
if [ -n "$rl_week_pct" ] && [ -n "$rl_week_reset" ]; then
  week_text="$(awk -v p="$rl_week_pct" -v reset="$rl_week_reset" -v now="$now" 'BEGIN{
    rem=reset-now; if(rem<0)rem=0
    d=int((rem+43200)/86400)
    printf "%.0f%% (%dd)", p, d
  }')"
fi

rl_text=""
if [ -n "$five_text" ] && [ -n "$week_text" ]; then
  rl_text="${five_text} / ${week_text}"
else
  rl_text="${five_text}${week_text}"
fi

# --- Assemble ---
segments=()
[ -n "$caveman_badge" ] && segments+=("$caveman_badge")
[ -n "$model_name" ] && segments+=("${DIM}${model_name}${RESET}")
segments+=("${DIM}${dir_name}${RESET}")
[ -n "$ctx_text" ] && segments+=("${DIM}${ctx_text}${RESET}")
[ -n "$rl_text" ] && segments+=("${DIM}${rl_text}${RESET}")

sep=" ${DIM}|${RESET} "
out=""
for i in "${!segments[@]}"; do
  if [ "$i" -eq 0 ]; then out="${segments[$i]}"; else out="${out}${sep}${segments[$i]}"; fi
done
printf '%s' "$out"
