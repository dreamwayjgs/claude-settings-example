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

$content = ($fragments | ForEach-Object { [System.IO.File]::ReadAllText($_, [System.Text.UTF8Encoding]::new($false)).TrimEnd("`r", "`n") }) -join "`n`n"
$content += "`n"
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

$destinations = @(
  (Join-Path $TargetHome '.claude/CLAUDE.md'),
  (Join-Path $TargetHome '.claude-personal/CLAUDE.md'),
  (Join-Path $TargetHome '.config/opencode/AGENTS.md')
)

foreach ($destination in $destinations) {
  [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($destination)) | Out-Null
  [System.IO.File]::WriteAllText($destination, $content, $utf8NoBom)
  "wrote $destination"
}

foreach ($template in @('project-rules.md', 'OPERATOR.md')) {
  $source = Join-Path $repo "templates/$template"
  foreach ($destination in @(
    (Join-Path $TargetHome ".claude/templates/$template"),
    (Join-Path $TargetHome ".config/opencode/templates/$template")
  )) {
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($destination)) | Out-Null
    [System.IO.File]::WriteAllText($destination, [System.IO.File]::ReadAllText($source, $utf8NoBom), $utf8NoBom)
    "wrote $destination"
  }
}
