#Requires -Version 7
# Isolated rule generation only; no harness CLI or skill installation is run.
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$root = Join-Path ([System.IO.Path]::GetTempPath()) "build-targets-$([guid]::NewGuid())"
$paths = @('.claude/CLAUDE.md', '.claude-personal/CLAUDE.md', '.config/opencode/AGENTS.md', '.omp/agent/AGENTS.md', '.config/crush/CRUSH.md')

function Assert([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw $Message }
}

try {
  $cases = @(
    @{ Name = 'default'; Args = @{}; Expected = $paths[0, 2, 3, 4] },
    @{ Name = 'all'; Args = @{ Targets = @('claude', 'crush', 'omp', 'opencode') }; Expected = $paths[0, 2, 3, 4] },
    @{ Name = 'both'; Args = @{ Targets = @('omp', 'opencode') }; Expected = $paths[2..3] },
    @{ Name = 'claude'; Args = @{ Targets = @('claude') }; Expected = @($paths[0]) },
    @{ Name = 'personal'; Args = @{ Targets = @('claude'); ClaudeDir = '.claude-personal' }; Expected = @($paths[1]) },
    @{ Name = 'crush'; Args = @{ Targets = @('crush') }; Expected = @($paths[4]) },
    @{ Name = 'omp'; Args = @{ Targets = @('omp') }; Expected = @($paths[3]) },
    @{ Name = 'opencode'; Args = @{ Targets = @('opencode') }; Expected = @($paths[2]) }
  )
  foreach ($case in $cases) {
    $homeDir = Join-Path $root $case.Name
    $arguments = $case.Args
    & "$repo/build-rules.ps1" @arguments -TargetHome $homeDir -IncludeForeman false | Out-Null
    foreach ($rel in $paths) {
      $file = Join-Path $homeDir $rel
      Assert ((Test-Path $file) -eq ($rel -in $case.Expected)) "$($case.Name): unexpected output $rel"
      if ((Test-Path $file) -and $case.Name -ne 'default') {
        # Any Claude config folder gets the same content as the default .claude one.
        $reference = Join-Path "$root/default" ($rel -replace '^\.claude-personal/', '.claude/')
        Assert ((Get-FileHash $file).Hash -eq (Get-FileHash $reference).Hash) "changed content: $rel"
      }
    }
    foreach ($rel in @('project-rules.md', '.claudeignore', 'three-man-team/SOURCE', 'three-man-team/templates/project-folder/ROGER.md')) {
      Assert (Test-Path (Join-Path "$homeDir/.config/agent-rules" $rel)) "missing shared output: $rel"
    }
    Assert (-not (Test-Path "$homeDir/.agents")) 'isolated build installed skills'
    Write-Output "PASS: $($case.Name)"
  }

  # A non-selected harness must remain untouched, even if it already exists.
  $sentinel = Join-Path $root 'both/.config/crush/CRUSH.md'
  New-Item -ItemType Directory (Split-Path $sentinel) -Force | Out-Null
  Set-Content $sentinel 'keep'
  & "$repo/build-rules.ps1" -Targets omp,opencode -TargetHome "$root/both" -IncludeForeman false | Out-Null
  Assert ((Get-Content $sentinel -Raw).Trim() -eq 'keep') 'non-selected file was modified'
  Write-Output 'PASS: non-selected file preserved'

  $invalid = @(
    @{ Targets = @('typo') }, @{ Targets = @('omp', 'typo') }, @{ Targets = @() }, @{ Targets = @('') },
    @{ ClaudeDir = '' }, @{ ClaudeDir = 'a/b' }, @{ ClaudeDir = 'a\b' }, @{ ClaudeDir = '..' }, @{ ClaudeDir = '.' },
    @{ Targets = @('omp'); ClaudeDir = '.claude-personal' }
  )
  foreach ($arguments in $invalid) {
    $homeDir = Join-Path $root 'invalid'
    $failed = $false
    try { & "$repo/build-rules.ps1" @arguments -TargetHome $homeDir -IncludeForeman false | Out-Null }
    catch { $failed = $true }
    Assert $failed "invalid arguments accepted: $($arguments | ConvertTo-Json -Compress)"
    Assert (-not (Test-Path $homeDir)) 'invalid arguments wrote files'
  }
  Write-Output 'PASS: invalid arguments fail before writing'
} finally {
  if (Test-Path $root) { Remove-Item $root -Recurse -Force }
}
