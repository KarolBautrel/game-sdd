[CmdletBinding()]
param([string]$AsepritePath = 'C:/Program Files/Aseprite/Aseprite.exe')
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
if (-not (Test-Path -LiteralPath $AsepritePath)) { throw 'Aseprite executable missing' }
$stdout=Join-Path $repo 'artifacts/qa-runs/campaign-aseprite.stdout.log'
$stderr=Join-Path $repo 'artifacts/qa-runs/campaign-aseprite.stderr.log'
$process=Start-Process -FilePath $AsepritePath -ArgumentList @('-b','--script-param',('"root='+$repo+'"'),'--script',('"'+(Join-Path $repo 'tools/aseprite/campaign_ui_assets.lua')+'"')) -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
Get-Content -LiteralPath $stdout
if ($process.ExitCode -ne 0 -or (Select-String -LiteralPath $stdout,$stderr -Pattern '^Error' -Quiet)) { Get-Content -LiteralPath $stderr; throw ('Aseprite export failed: '+$process.ExitCode) }
