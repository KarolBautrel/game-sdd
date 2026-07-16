param(
    [string] $ProjectRoot = "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game"
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

function Save-Crop([System.Drawing.Bitmap] $source, [string] $targetPath, [int] $x, [int] $y, [int] $w, [int] $h) {
    $dir = Split-Path -Parent $targetPath
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $output = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        for ($py = 0; $py -lt $h; $py++) {
            for ($px = 0; $px -lt $w; $px++) {
                $c = $source.GetPixel($x + $px, $y + $py)
                $isGreen = $c.G -ge 135 -and $c.R -le 110 -and $c.B -le 125 -and $c.G -gt ($c.R + 50) -and $c.G -gt ($c.B + 50)
                if ($isGreen) {
                    $output.SetPixel($px, $py, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
                } else {
                    $output.SetPixel($px, $py, [System.Drawing.Color]::FromArgb($c.A, $c.R, $c.G, $c.B))
                }
            }
        }
        $output.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $output.Dispose()
    }
}

function Save-Resize([string] $sourcePath, [string] $targetPath, [int] $w, [int] $h) {
    $dir = Split-Path -Parent $targetPath
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $source = [System.Drawing.Bitmap]::FromFile($sourcePath)
    $output = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($output)
        try {
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $graphics.DrawImage($source, 0, 0, $w, $h)
        } finally {
            $graphics.Dispose()
        }
        $output.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $output.Dispose()
        $source.Dispose()
    }
}

$projectPath = Resolve-Path -LiteralPath $ProjectRoot
$sourcePath = Join-Path $projectPath "assets\ui\combat\assets\call_9exrXDuBoixt7ysV19RVDrhl.png"
$outputRoot = Join-Path $projectPath "assets\ui\combat\processed"
if (Test-Path -LiteralPath $outputRoot) {
    Remove-Item -LiteralPath $outputRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null

$crops = @(
    @{ id = "bar_hp"; file = "bars/bar_hp.png"; x = 52; y = 42; w = 687; h = 101 },
    @{ id = "bar_ap"; file = "bars/bar_ap.png"; x = 52; y = 174; w = 686; h = 100 },
    @{ id = "bar_mp"; file = "bars/bar_mp.png"; x = 52; y = 310; w = 686; h = 99 },
    @{ id = "slot_bar"; file = "frames/slot_bar.png"; x = 797; y = 45; w = 691; h = 101 },
    @{ id = "panel_small"; file = "frames/panel_small.png"; x = 798; y = 184; w = 247; h = 229 },
    @{ id = "panel_large"; file = "frames/panel_large.png"; x = 1093; y = 184; w = 398; h = 605 },
    @{ id = "slot_normal"; file = "slots/slot_normal.png"; x = 55; y = 458; w = 173; h = 184 },
    @{ id = "slot_selected"; file = "slots/slot_selected.png"; x = 256; y = 458; w = 177; h = 185 },
    @{ id = "slot_disabled"; file = "slots/slot_disabled.png"; x = 457; y = 461; w = 174; h = 181 },
    @{ id = "slot_end"; file = "slots/slot_end.png"; x = 661; y = 461; w = 173; h = 185 },
    @{ id = "slot_dark"; file = "slots/slot_dark.png"; x = 868; y = 461; w = 178; h = 182 },
    @{ id = "corner_gold"; file = "corners/corner_gold.png"; x = 56; y = 690; w = 116; h = 108 },
    @{ id = "corner_iron"; file = "corners/corner_iron.png"; x = 223; y = 691; w = 104; h = 107 },
    @{ id = "corner_wood_iron"; file = "corners/corner_wood_iron.png"; x = 390; y = 690; w = 126; h = 108 },
    @{ id = "corner_wood"; file = "corners/corner_wood.png"; x = 583; y = 690; w = 154; h = 108 },
    @{ id = "icon_heart"; file = "icons/icon_heart.png"; x = 63; y = 843; w = 129; h = 129 },
    @{ id = "icon_shield"; file = "icons/icon_shield.png"; x = 244; y = 842; w = 132; h = 130 },
    @{ id = "icon_boot"; file = "icons/icon_boot.png"; x = 422; y = 842; w = 132; h = 130 },
    @{ id = "icon_sword"; file = "icons/icon_sword.png"; x = 604; y = 842; w = 132; h = 130 },
    @{ id = "icon_bow"; file = "icons/icon_bow.png"; x = 782; y = 842; w = 132; h = 130 },
    @{ id = "icon_hourglass"; file = "icons/icon_hourglass.png"; x = 962; y = 842; w = 132; h = 130 },
    @{ id = "icon_bag"; file = "icons/icon_bag.png"; x = 1140; y = 842; w = 132; h = 130 },
    @{ id = "icon_settings"; file = "icons/icon_settings.png"; x = 1320; y = 842; w = 132; h = 130 },
    @{ id = "icon_heart_inner"; file = "icons/inner/icon_heart.png"; x = 88; y = 872; w = 80; h = 72 },
    @{ id = "icon_shield_inner"; file = "icons/inner/icon_shield.png"; x = 280; y = 862; w = 62; h = 82 },
    @{ id = "icon_boot_inner"; file = "icons/inner/icon_boot.png"; x = 454; y = 856; w = 56; h = 88 },
    @{ id = "icon_sword_inner"; file = "icons/inner/icon_sword.png"; x = 638; y = 854; w = 70; h = 88 },
    @{ id = "icon_bow_inner"; file = "icons/inner/icon_bow.png"; x = 810; y = 860; w = 76; h = 82 },
    @{ id = "icon_hourglass_inner"; file = "icons/inner/icon_hourglass.png"; x = 1000; y = 854; w = 62; h = 88 },
    @{ id = "icon_bag_inner"; file = "icons/inner/icon_bag.png"; x = 1173; y = 854; w = 76; h = 88 },
    @{ id = "icon_settings_inner"; file = "icons/inner/icon_settings.png"; x = 1348; y = 856; w = 76; h = 82 }
)

$source = [System.Drawing.Bitmap]::FromFile($sourcePath)
try {
    foreach ($crop in $crops) {
        $targetPath = Join-Path $outputRoot $crop.file
        Save-Crop $source $targetPath $crop.x $crop.y $crop.w $crop.h
        Write-Output ("{0}: {1}" -f $crop.id, $crop.file)
    }
} finally {
    $source.Dispose()
}

$miniBars = @(
    @{ id = "mini_bar_hp"; source = "bars/bar_hp.png"; file = "bars/mini_bar_hp.png"; w = 384; h = 56 },
    @{ id = "mini_bar_ap"; source = "bars/bar_ap.png"; file = "bars/mini_bar_ap.png"; w = 384; h = 56 },
    @{ id = "mini_bar_mp"; source = "bars/bar_mp.png"; file = "bars/mini_bar_mp.png"; w = 384; h = 56 }
)

foreach ($miniBar in $miniBars) {
    $miniSource = Join-Path $outputRoot $miniBar.source
    $miniTarget = Join-Path $outputRoot $miniBar.file
    Save-Resize $miniSource $miniTarget $miniBar.w $miniBar.h
    Write-Output ("{0}: {1}" -f $miniBar.id, $miniBar.file)
}

$manifest = [ordered]@{
    generated_by = "tools/ui/extract_combat_ui_assets.ps1"
    source = "assets/ui/combat/assets/call_9exrXDuBoixt7ysV19RVDrhl.png"
    output_root = "assets/ui/combat/processed"
    crops = $crops
    derived = $miniBars
}
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $outputRoot "manifest.json"), ($manifest | ConvertTo-Json -Depth 8), $utf8NoBom)

$readme = @(
    '# Processed Combat UI Assets',
    '',
    'Generated from `assets/ui/combat/assets/call_9exrXDuBoixt7ysV19RVDrhl.png`.',
    '',
    'Regenerate with:',
    '',
    '```powershell',
    '.\tools\ui\extract_combat_ui_assets.ps1',
    '```'
)
[System.IO.File]::WriteAllText((Join-Path $outputRoot "README.md"), ($readme -join [Environment]::NewLine), $utf8NoBom)
