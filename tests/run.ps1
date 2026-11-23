<#
  Offline tests for eq-autocomplete: runs tests\test_engine.lua (tokenizer, grammar, suggestions,
  learning) against a fake game.

  No Lua install needed: it uses the Lua inside the VS Code Lua extension (sumneko), which is a
  newer Lua than MacroQuest's LuaJIT, so this proves the logic, not LuaJIT compatibility.

    powershell -NoProfile -ExecutionPolicy Bypass -File tests\run.ps1
#>
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$repo = Split-Path -Parent $here
$parent = Split-Path -Parent $repo   # so require('eq-autocomplete.lib.x') finds <parent>\eq-autocomplete\lib\x.lua

$lua = Get-ChildItem "$env:USERPROFILE\.vscode\extensions\sumneko.lua-*\server\bin\lua-language-server.exe" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime | Select-Object -Last 1
if (-not $lua) { Write-Output 'Cannot find lua-language-server.exe (VS Code Lua extension by sumneko).'; exit 1 }

$out = Join-Path $env:TEMP 'eq-autocomplete-test'
if (Test-Path $out) { Remove-Item -Recurse -Force $out }
[void](New-Item -ItemType Directory -Force $out)
$env:EQAC_OUT = $out

$p = ($parent -replace '\\', '/')
$t = ((Join-Path $here 'test_engine.lua') -replace '\\', '/')
$code = "package.path='$p/?.lua;$p/?/init.lua;'..package.path; dofile('$t')"
$output = & $lua.FullName -e $code 2>&1 | ForEach-Object { "$_" }
$output | ForEach-Object { Write-Output $_ }

$result = @($output | Where-Object { $_ -like 'RESULT:*' })
if ($result.Count -eq 0) { Write-Output 'RESULT: TEST ERROR (no result line)'; exit 1 }
if ($result[-1] -notmatch ', 0 failed') { exit 1 }
exit 0
