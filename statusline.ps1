[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Esc = [char]27
$Reset = "${Esc}[0m"
$Dim = "${Esc}[2m"

# --- Read stdin JSON (session/context/cwd info) ---
$rawInput = (New-Object System.IO.StreamReader([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)).ReadToEnd()
$data = $null
if ($rawInput) {
    try { $data = $rawInput | ConvertFrom-Json } catch {}
}

# --- Caveman badge (preserved from existing plugin hook) ---
$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }
$CavemanScript = Join-Path $ClaudeDir "plugins\cache\caveman\caveman\25d22f864ad6\src\hooks\caveman-statusline.ps1"
$cavemanBadge = ""
if (Test-Path $CavemanScript) {
    try {
        $cavemanBadge = (& pwsh -NoProfile -ExecutionPolicy Bypass -File $CavemanScript) -join ""
    } catch {}
}

# --- Current working directory ---
$cwd = $null
if ($data) {
    if ($data.workspace -and $data.workspace.current_dir) { $cwd = $data.workspace.current_dir }
    elseif ($data.cwd) { $cwd = $data.cwd }
}
if (-not $cwd) { $cwd = (Get-Location).Path }
$dirName = Split-Path -Leaf $cwd
if ([string]::IsNullOrEmpty($dirName)) { $dirName = $cwd }

# --- Remaining context window percentage ---
# Prefer pre-calculated context_window fields (docs); fall back to transcript usage.
$ctxText = ""
$remaining = $null
if ($data -and $data.context_window) {
    if ($null -ne $data.context_window.remaining_percentage) {
        $remaining = [double]$data.context_window.remaining_percentage
    }
    elseif ($null -ne $data.context_window.used_percentage) {
        $remaining = 100 - [double]$data.context_window.used_percentage
    }
}
if ($null -eq $remaining) {
    # Fallback: compute from transcript_path jsonl (last usage-bearing message).
    $tokens = $null
    $tp = if ($data) { $data.transcript_path } else { $null }
    if ($tp -and (Test-Path -LiteralPath $tp)) {
        try {
            $lines = Get-Content -LiteralPath $tp -Tail 400
            for ($i = $lines.Count - 1; $i -ge 0; $i--) {
                try { $o = $lines[$i] | ConvertFrom-Json } catch { continue }
                $u = $o.message.usage
                if ($u -and $null -ne $u.input_tokens) {
                    $tokens = [double]$u.input_tokens + [double]$u.cache_read_input_tokens + [double]$u.cache_creation_input_tokens
                    break
                }
            }
        } catch {}
    }
    if ($null -ne $tokens) {
        $limit = 200000
        $mid = "$($data.model.id) $($data.model.display_name)"
        if ($mid -match '1m') { $limit = 1000000 }
        $remaining = ($limit - $tokens) / $limit * 100
    }
}
if ($null -ne $remaining) {
    if ($remaining -lt 0) { $remaining = 0 }
    $ctxText = "Ctx:{0:N0}%" -f $remaining
}

# --- Model name (first 4 chars only) ---
$modelName = if ($data -and $data.model -and $data.model.display_name) { $data.model.display_name } else { $null }
if ($modelName) { $modelName = $modelName.Substring(0, [Math]::Min(4, $modelName.Length)) }

# --- Rate limit usage (Pro/Max only; absent otherwise) ---
$rlText = ""
if ($data -and $data.rate_limits) {
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $fiveText = ""
    $fh = $data.rate_limits.five_hour
    if ($fh -and $null -ne $fh.used_percentage -and $null -ne $fh.resets_at) {
        $rem = [double]$fh.resets_at - $now
        if ($rem -lt 0) { $rem = 0 }
        $h = [math]::Floor($rem / 3600)
        $m = [math]::Floor(($rem % 3600) / 60)
        $fiveText = "{0:N0}%({1}h{2}m)" -f [double]$fh.used_percentage, $h, $m
    }
    $weekText = ""
    $sd = $data.rate_limits.seven_day
    if ($sd -and $null -ne $sd.used_percentage -and $null -ne $sd.resets_at) {
        $rem = [double]$sd.resets_at - $now
        if ($rem -lt 0) { $rem = 0 }
        $d = [math]::Floor(($rem + 43200) / 86400)
        $weekText = "{0:N0}%({1}d)" -f [double]$sd.used_percentage, $d
    }
    if ($fiveText -and $weekText) { $rlText = "$fiveText/$weekText" }
    else { $rlText = "$fiveText$weekText" }
}

# --- Assemble ---
$segments = @()
if ($cavemanBadge) { $segments += $cavemanBadge }
if ($modelName) { $segments += "${Dim}${modelName}${Reset}" }
$segments += "${Dim}${dirName}${Reset}"
if ($ctxText) { $segments += "${Dim}${ctxText}${Reset}" }
if ($rlText) { $segments += "${Dim}${rlText}${Reset}" }

[Console]::Write(($segments -join "${Dim}|${Reset}"))
