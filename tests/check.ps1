<#
  Type-checks eq-autocomplete's Lua against MacroQuest's definitions (a clone of
  https://github.com/macroquest/mq-definitions next to this folder),
  using the Lua language server inside the VS Code Lua extension (no Lua install on this PC).
  This is what catches a misspelled ImGui or TLO call in lib\ui.lua and lib\sources.lua, which the
  offline tests can't run. Takes about a minute. Prints "no problems found" when clean.

    powershell -NoProfile -ExecutionPolicy Bypass -File tests\check.ps1
#>
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$defs = Join-Path (Split-Path -Parent $repo) 'mq-definitions'
$lls = Get-ChildItem "$env:USERPROFILE\.vscode\extensions\sumneko.lua-*\server\bin\lua-language-server.exe" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime | Select-Object -Last 1
if (-not $lls) { Write-Output 'Cannot find lua-language-server.exe (VS Code Lua extension by sumneko).'; exit 1 }
if (-not (Test-Path $defs)) { Write-Output "Cannot find mq-definitions at $defs"; exit 1 }

$work = Join-Path $env:TEMP 'eq-autocomplete-check'
[void](New-Item -ItemType Directory -Force (Join-Path $work 'log'), (Join-Path $work 'meta'))
$rc = Join-Path $work 'luarc.json'
@{ 'runtime.version' = 'LuaJIT'; 'workspace.library' = @($defs -replace '\\', '/'); 'workspace.ignoreDir' = @('tests', 'tools') } |
    ConvertTo-Json | Set-Content -Encoding ascii $rc
& $lls.FullName --check $repo --configpath $rc --logpath (Join-Path $work 'log') --metapath (Join-Path $work 'meta') --checklevel=Warning 2>&1 |
    ForEach-Object { "$_" -split "`r" } | Where-Object { $_ -match 'Warning|Error|Diagnosis|\^|no problems' -or $_ -match '^\s{4}\S' }
