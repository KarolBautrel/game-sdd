param()
$ErrorActionPreference='Stop'
$motionRepo=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$motionPage=Join-Path $motionRepo 'assets_src/characters/warden_motion_pilot/2026-11-03/preview.html'
if (-not (Test-Path -LiteralPath $motionPage)) { throw 'Motion preview is not packaged. See docs/design/character-art/WARDEN_MOTION_PILOT.md.' }
Start-Process -FilePath $motionPage
