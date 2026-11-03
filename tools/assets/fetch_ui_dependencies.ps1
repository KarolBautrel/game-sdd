[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$vendor = Join-Path $repo 'assets_src/vendor'
New-Item -ItemType Directory -Path $vendor -Force | Out-Null
Set-Content -LiteralPath (Join-Path $vendor '.gdignore') -Value '' -Encoding ASCII
$records = @()
$lockPath=Join-Path $PSScriptRoot 'ui_dependencies.json'
$existingLock=if (Test-Path -LiteralPath $lockPath) { Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json } else { $null }
function Save-Pack([string]$Name, [string]$Url, [string]$Page, [string]$License) {
    $zip = Join-Path $vendor ($Name + '.zip')
    $folder = Join-Path $vendor $Name
    if (-not (Test-Path -LiteralPath $zip)) { Invoke-WebRequest -Uri $Url -OutFile $zip -UseBasicParsing }
    if (-not (Test-Path -LiteralPath $folder)) { Expand-Archive -LiteralPath $zip -DestinationPath $folder }
    return [ordered]@{name=$Name; source=$Page; license=$License; archive=('assets_src/vendor/' + $Name + '.zip'); sha256=(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()}
}
foreach ($slug in @('fantasy-ui-borders','pixel-ui-pack')) {
    $page = 'https://kenney.nl/assets/' + $slug
    $html = (Invoke-WebRequest -Uri $page -UseBasicParsing -SessionVariable downloadSession).Content
    $id = [regex]::Match($html,"data-download-id='([^']+)'").Groups[1].Value
    if (-not $id) { throw ('Missing download identifier: ' + $page) }
    $signed = Invoke-RestMethod -Uri ('https://kenney.nl/download-link/' + $id) -WebSession $downloadSession -Headers @{Referer=$page; 'X-Requested-With'='XMLHttpRequest'; Accept='application/json'}
    $records += Save-Pack ('kenney_' + $slug.Replace('-','_')) $signed.url $page 'CC0-1.0'
}
$page = 'https://shikashipx.itch.io/shikashis-fantasy-icons-pack'
$html = (Invoke-WebRequest -Uri ($page + '/purchase') -UseBasicParsing -SessionVariable iconSession).Content
$csrf = [regex]::Match($html,'name="csrf_token" value="([^"]+)"').Groups[1].Value
$downloadPage = Invoke-RestMethod -Uri ($page + '/download_url') -Method Post -WebSession $iconSession -Body @{csrf_token=$csrf} -Headers @{Referer=($page + '/purchase')}
$html = (Invoke-WebRequest -Uri $downloadPage.url -WebSession $iconSession -UseBasicParsing).Content
$csrf = [regex]::Match($html,'name="csrf_token" value="([^"]+)"').Groups[1].Value
$download = Invoke-RestMethod -Uri ($page + '/file/2140234') -Method Post -WebSession $iconSession -Body @{csrf_token=$csrf} -Headers @{Referer=$downloadPage.url}
if (-not $download.url) { throw 'Shikashi free download URL missing' }
$records += Save-Pack 'shikashi_fantasy_icons' $download.url $page 'CC-BY-3.0 in downloaded archive; author page now CC-BY-4.0; credit Matt Firth (shikashipx) and game-icons.net'
$themeSha=if ($existingLock.themegen_commit) { $existingLock.themegen_commit } else { (Invoke-RestMethod -Uri 'https://api.github.com/repos/Inspiaaa/ThemeGen/commits/master').sha }
$records += Save-Pack 'themegen' ('https://codeload.github.com/Inspiaaa/ThemeGen/zip/' + $themeSha) 'https://github.com/Inspiaaa/ThemeGen' 'MIT'
$themeRoot = Get-ChildItem -LiteralPath (Join-Path $vendor 'themegen') -Directory | Select-Object -First 1
foreach ($name in @('theme_gen','theme_gen_save_sync')) {
    $target = Join-Path $repo ('addons/' + $name)
    if (-not (Test-Path -LiteralPath $target)) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $themeRoot.FullName ('addons/' + $name)) -Destination $target -Recurse
    }
}
$fonts = Join-Path $repo 'assets/ui/fonts'
New-Item -ItemType Directory -Path $fonts -Force | Out-Null
foreach ($font in @(@{Folder='cinzel';Name='Cinzel';File='Cinzel[wght].ttf'},@{Folder='sourcesans3';Name='SourceSans3';File='SourceSans3[wght].ttf'})) {
    $base = 'https://raw.githubusercontent.com/google/fonts/main/ofl/' + $font.Folder + '/'
    $fontPath = Join-Path $fonts ($font.Name + '.ttf')
    if (-not (Test-Path -LiteralPath $fontPath)) { Invoke-WebRequest -Uri ($base + [uri]::EscapeDataString($font.File)) -OutFile $fontPath -UseBasicParsing }
    $licensePath = Join-Path $fonts ($font.Name + '-OFL.txt')
    if (-not (Test-Path -LiteralPath $licensePath)) { Invoke-WebRequest -Uri ($base + 'OFL.txt') -OutFile $licensePath -UseBasicParsing }
    $records += [ordered]@{name=$font.Name;source=('https://github.com/google/fonts/tree/main/ofl/' + $font.Folder);license='OFL-1.1';file=('assets/ui/fonts/' + $font.Name + '.ttf');sha256=(Get-FileHash -LiteralPath $fontPath -Algorithm SHA256).Hash.ToLowerInvariant()}
}
$staticFont=Join-Path $fonts 'SourceSans3-Semibold.ttf'
$staticUrl='https://raw.githubusercontent.com/adobe-fonts/source-sans/release/TTF/SourceSans3-Semibold.ttf'
if (-not (Test-Path -LiteralPath $staticFont)) { Invoke-WebRequest -Uri $staticUrl -OutFile $staticFont -UseBasicParsing }
$records += [ordered]@{name='SourceSans3 Semibold';source=$staticUrl;license='OFL-1.1';file='assets/ui/fonts/SourceSans3-Semibold.ttf';sha256=(Get-FileHash -LiteralPath $staticFont -Algorithm SHA256).Hash.ToLowerInvariant()}
$manifest = [ordered]@{schema='sdd.ui-dependencies-v1'; downloaded_utc=[DateTime]::UtcNow.ToString('o'); themegen_commit=$themeSha; dependencies=$records}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'ui_dependencies.json') -Encoding UTF8
$records | ForEach-Object { Write-Output ('Installed ' + $_.name + ' / ' + $_.license) }
