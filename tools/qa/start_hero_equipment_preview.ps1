param()
$ErrorActionPreference = 'Stop'
$previewRepo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$previewPage = Join-Path $previewRepo 'assets_src/characters/hero_identity/bran/preview.html'
if (-not (Test-Path -LiteralPath $previewPage)) { throw 'Bran equipment preview has not been packaged.' }
Start-Process -FilePath $previewPage
