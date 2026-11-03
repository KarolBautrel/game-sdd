param()
$ErrorActionPreference='Stop'
$drawnRepo=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$drawnPage=Join-Path $drawnRepo 'assets_src/characters/drawn_animation/2026-11-03/refinements/preview.html'
if (-not (Test-Path -LiteralPath $drawnPage)) { throw 'Refinement preview is not packaged yet.' }
Start-Process -FilePath $drawnPage
