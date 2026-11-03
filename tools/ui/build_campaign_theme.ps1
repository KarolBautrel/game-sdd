[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$godot=Join-Path (Split-Path -Parent (Split-Path -Parent $repo)) 'installers/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe'
$stdout=Join-Path $repo 'artifacts/qa-runs/campaign-theme-builder.stdout.log'
$stderr=Join-Path $repo 'artifacts/qa-runs/campaign-theme-builder.stderr.log'
$process=Start-Process -FilePath $godot -ArgumentList @('--headless','--editor','--path',('"'+$repo+'"'),'--','--build-campaign-theme') -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
$processHandle=$process.Handle
if (-not $process.WaitForExit(30000)) { Stop-Process -Id $process.Id; throw 'ThemeGen editor build timed out' }
$process.WaitForExit()
Get-Content -LiteralPath $stdout | Select-String 'ThemeGen|exported'
if ($process.ExitCode -ne 0 -or (Select-String -LiteralPath $stderr -Pattern 'ERROR:|WARNING:' -Quiet)) { Get-Content -LiteralPath $stderr; throw 'ThemeGen build failed diagnostics' }
