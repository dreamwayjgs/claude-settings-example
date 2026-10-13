#Requires -Version 7
[CmdletBinding()]
param(
  [ValidateSet('true', 'false')]
  [string]$IncludeForeman,
  # Rule files and templates go under -TargetHome. Agent skills are installed by the
  # `skills` CLI, which only targets the real $HOME; when -TargetHome differs the
  # skills step is skipped and reported, so an isolated run never touches $HOME.
  [string]$TargetHome = $HOME
)

$ErrorActionPreference = 'Stop'

$repo = $PSScriptRoot
$config = Join-Path $repo '.claude-settings.local'

# Skills are installed with the `skills` CLI via npx; without it the build would
# leave ~/.agents/skills stale, so fail before writing anything (including the
# first-run config file).
if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
  throw 'npx (node) is required to install agent skills; nothing written'
}

if (Test-Path -LiteralPath $config) {
  $setting = (Get-Content -LiteralPath $config -Raw -Encoding utf8).Trim()
  if ($setting -notmatch '^INCLUDE_FOREMAN=(true|false)$') {
    throw "invalid ${config}: expected INCLUDE_FOREMAN=true|false"
  }
  $IncludeForeman = $Matches[1]
} elseif (-not $IncludeForeman) {
  $IncludeForeman = if ((Read-Host 'Include Foreman integration? [y/N]') -match '^(y|yes)$') { 'true' } else { 'false' }
}

if ($IncludeForeman -eq 'true' -and -not (Get-Command foreman -ErrorAction SilentlyContinue)) {
  throw 'Foreman is not installed; install it or choose IncludeForeman false'
}

if (-not (Test-Path -LiteralPath $config)) {
  [System.IO.File]::WriteAllText($config, "INCLUDE_FOREMAN=$IncludeForeman`n", [System.Text.UTF8Encoding]::new($false))
}

$fragments = @(
  (Join-Path $repo 'fragments/00-core.md')
)
if ($IncludeForeman -eq 'true') {
  $fragments += Join-Path $repo 'fragments/05-foreman.md'
}
$fragments += Join-Path $repo 'fragments/10-three-man-team.md'

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$content = ($fragments | ForEach-Object { [System.IO.File]::ReadAllText($_, $utf8NoBom).TrimEnd("`r", "`n") }) -join "`n`n"
$content += "`n"
# omp and Crush have no session-start hook: append activation block (default off).
$activation = $content + "`n" + [System.IO.File]::ReadAllText((Join-Path $repo 'fragments/90-activation.md'), $utf8NoBom)

function Write-Out([string]$Destination, [string]$Text) {
  [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($Destination)) | Out-Null
  [System.IO.File]::WriteAllText($Destination, $Text, $utf8NoBom)
  "wrote $Destination"
}

foreach ($rel in @('.claude/CLAUDE.md', '.claude-personal/CLAUDE.md', '.config/opencode/AGENTS.md')) {
  Write-Out (Join-Path $TargetHome $rel) $content
}
foreach ($rel in @('.omp/agent/AGENTS.md', '.config/crush/CRUSH.md')) {
  Write-Out (Join-Path $TargetHome $rel) $activation
}

foreach ($template in @('project-rules.md', '.claudeignore')) {
  $text = [System.IO.File]::ReadAllText((Join-Path $repo "templates/$template"), $utf8NoBom)
  foreach ($dir in @('.claude/templates', '.config/opencode/templates', '.omp/agent/templates', '.config/crush/templates')) {
    Write-Out (Join-Path $TargetHome "$dir/$template") $text
  }
}

# Agent skills -> ~/.agents/skills (read by OpenCode v2, omp, and Crush; Claude Code
# uses its own plugins). Source = agent-skills.txt, fetched at the pinned ref with the
# `skills` CLI (needs node + network). Provenance: ~/.agents/.skill-lock.json.
$skillsCli = 'skills@1.7.2'
$isolated = [System.IO.Path]::GetFullPath($TargetHome).TrimEnd('\', '/') -ne [System.IO.Path]::GetFullPath($HOME).TrimEnd('\', '/')
if ($isolated) {
  "skip skills: -TargetHome '$TargetHome' differs from HOME; the skills CLI only installs to the real HOME"
} else {
  foreach ($line in Get-Content -LiteralPath (Join-Path $repo 'agent-skills.txt') -Encoding utf8) {
    $line = $line.Trim()
    if (-not $line -or $line.StartsWith('#')) { continue }
    $parts = $line -split '\s+'
    $source = $parts[0]; $ref = $parts[1]; $names = $parts[2..($parts.Length - 1)]
    $skillArgs = @($names | ForEach-Object { '-s'; $_ })
    $log = & npx -y $skillsCli add "https://github.com/$source/tree/$ref" -g -a pi @skillArgs -y 2>&1
    if ($LASTEXITCODE -ne 0) { $log | Write-Host; throw "skills add failed for $source@$ref" }
    "installed $source@${ref}: $($names -join ' ')"
  }
}
