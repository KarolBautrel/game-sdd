param()
$ErrorActionPreference = 'Stop'
$previewRepo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$previewPage = Join-Path $previewRepo 'assets_src/characters/tactical_batch/2026-11-03/preview.html'
if (-not (Test-Path -LiteralPath $previewPage)) { throw 'Painted enemy preview is not packaged.' }
Start-Process -FilePath $previewPage -WindowStyle Normal
