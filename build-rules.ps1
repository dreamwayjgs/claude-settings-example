#Requires -Version 7
[CmdletBinding()]
param(
  [ValidateSet('true', 'false')]
  [string]$IncludeForeman,
  [string]$TargetHome = $HOME
)

$ErrorActionPreference = 'Stop'

$repo = $PSScriptRoot
$config = Join-Path $repo '.claude-settings.local'

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

# Claude plugin skills -> ~/.agents/skills (read by omp and Crush by default).
# Re-run after a Claude plugin update: install paths carry the version.
$plugins = Join-Path $TargetHome '.claude/plugins/installed_plugins.json'
$skipSkills = @('qmd@qmd/release')
if (Test-Path -LiteralPath $plugins) {
  $skillsRoot = Join-Path $TargetHome '.agents/skills'
  $installed = (Get-Content -LiteralPath $plugins -Raw -Encoding utf8 | ConvertFrom-Json).plugins
  foreach ($plugin in $installed.PSObject.Properties) {
    $skillsDir = Join-Path $plugin.Value[0].installPath 'skills'
    if (-not (Test-Path -LiteralPath $skillsDir)) { continue }
    foreach ($skill in Get-ChildItem -LiteralPath $skillsDir -Directory) {
      if (-not (Test-Path -LiteralPath (Join-Path $skill.FullName 'SKILL.md'))) { continue }
      if ($skipSkills -contains "$($plugin.Name)/$($skill.Name)") { continue }
      $dest = Join-Path $skillsRoot $skill.Name
      if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
      New-Item -ItemType Directory -Force -Path $skillsRoot | Out-Null
      Copy-Item -LiteralPath $skill.FullName -Destination $dest -Recurse
      "wrote $dest"
    }
  }
} else {
  "skip skills: $plugins not found"
}
