param()
$ErrorActionPreference='Stop'
$drawnRepo=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
if (Test-Path -LiteralPath (Join-Path $drawnRepo 'assets_src/characters/drawn_animation/2026-11-03/refinements/motion_balance/rollback.json')) { throw 'This candidate was rejected and rolled back.' }
$drawnPage=Join-Path $drawnRepo 'assets_src/characters/drawn_animation/2026-11-03/refinements/motion_balance/preview.html'
if (-not (Test-Path -LiteralPath $drawnPage)) { throw 'Motion balance preview is not packaged yet.' }
Start-Process -FilePath $drawnPage
