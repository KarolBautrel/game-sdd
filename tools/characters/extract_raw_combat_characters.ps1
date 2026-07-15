param(
    [string] $RawRoot = "C:\Users\karol\Desktop\Gierka\game_dir\raw_assety\combat\characters",
    [string] $ProjectRoot = "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game",
    [int] $BackgroundThreshold = 8,
    [int] $Padding = 6,
    [int] $MinWidth = 24,
    [int] $MinHeight = 24,
    [int] $MinArea = 140
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies "System.Drawing" -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Text;

public static class RawCombatCharacterExtractor {
    private struct Box {
        public int MinX;
        public int MinY;
        public int MaxX;
        public int MaxY;
        public int Area;
    }

    public static string Extract(string sourcePath, string outputDir, string outputPrefix, int threshold, int padding, int minWidth, int minHeight, int minArea) {
        Directory.CreateDirectory(outputDir);
        using (Bitmap source = new Bitmap(sourcePath)) {
            bool[,] solid = BuildSolidMask(source, threshold);
            bool[,] mask = Dilate(solid, source.Width, source.Height, 2);
            List<Box> boxes = Components(mask, source.Width, source.Height);
            boxes.Sort((a, b) => {
                int rowA = ((a.MinY + a.MaxY) / 2) / 96;
                int rowB = ((b.MinY + b.MaxY) / 2) / 96;
                if (rowA != rowB) return rowA.CompareTo(rowB);
                if (a.MinX != b.MinX) return a.MinX.CompareTo(b.MinX);
                return a.MinY.CompareTo(b.MinY);
            });

            StringBuilder json = new StringBuilder();
            json.Append("[\n");
            int saved = 0;
            foreach (Box component in boxes) {
                Box tight = Tighten(component, solid, source.Width, source.Height);
                int width = tight.MaxX - tight.MinX + 1;
                int height = tight.MaxY - tight.MinY + 1;
                if (width < minWidth || height < minHeight || tight.Area < minArea) continue;

                int x = Math.Max(0, tight.MinX - padding);
                int y = Math.Max(0, tight.MinY - padding);
                int right = Math.Min(source.Width - 1, tight.MaxX + padding);
                int bottom = Math.Min(source.Height - 1, tight.MaxY + padding);
                int cropWidth = right - x + 1;
                int cropHeight = bottom - y + 1;

                string fileName = outputPrefix + "_frame_" + saved.ToString("D3") + ".png";
                string outputPath = Path.Combine(outputDir, fileName);
                SaveTransparentCrop(source, outputPath, x, y, cropWidth, cropHeight, threshold);

                if (saved > 0) json.Append(",\n");
                json.Append("  {");
                json.Append("\"file\":\"").Append(fileName.Replace("\\", "\\\\")).Append("\",");
                json.Append("\"x\":").Append(x).Append(",");
                json.Append("\"y\":").Append(y).Append(",");
                json.Append("\"width\":").Append(cropWidth).Append(",");
                json.Append("\"height\":").Append(cropHeight).Append(",");
                json.Append("\"source_width\":").Append(source.Width).Append(",");
                json.Append("\"source_height\":").Append(source.Height);
                json.Append("}");
                saved++;
            }
            json.Append("\n]\n");
            return json.ToString();
        }
    }

    private static bool[,] BuildSolidMask(Bitmap source, int threshold) {
        bool[,] solid = new bool[source.Width, source.Height];
        for (int y = 0; y < source.Height; y++) {
            for (int x = 0; x < source.Width; x++) {
                Color c = source.GetPixel(x, y);
                solid[x, y] = Math.Max(c.R, Math.Max(c.G, c.B)) > threshold;
            }
        }
        return solid;
    }

    private static bool[,] Dilate(bool[,] solid, int width, int height, int radius) {
        bool[,] mask = new bool[width, height];
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                if (!solid[x, y]) continue;
                for (int dy = -radius; dy <= radius; dy++) {
                    int ny = y + dy;
                    if (ny < 0 || ny >= height) continue;
                    for (int dx = -radius; dx <= radius; dx++) {
                        int nx = x + dx;
                        if (nx < 0 || nx >= width) continue;
                        mask[nx, ny] = true;
                    }
                }
            }
        }
        return mask;
    }

    private static List<Box> Components(bool[,] mask, int width, int height) {
        bool[,] visited = new bool[width, height];
        List<Box> boxes = new List<Box>();
        int[] qx = new int[width * height];
        int[] qy = new int[width * height];
        int[] dx = new int[] {-1, 0, 1, -1, 1, -1, 0, 1};
        int[] dy = new int[] {-1, -1, -1, 0, 0, 1, 1, 1};

        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                if (!mask[x, y] || visited[x, y]) continue;
                Box box = new Box { MinX = x, MinY = y, MaxX = x, MaxY = y, Area = 0 };
                int head = 0;
                int tail = 0;
                qx[tail] = x;
                qy[tail] = y;
                tail++;
                visited[x, y] = true;

                while (head < tail) {
                    int cx = qx[head];
                    int cy = qy[head];
                    head++;
                    box.Area++;
                    if (cx < box.MinX) box.MinX = cx;
                    if (cy < box.MinY) box.MinY = cy;
                    if (cx > box.MaxX) box.MaxX = cx;
                    if (cy > box.MaxY) box.MaxY = cy;

                    for (int i = 0; i < dx.Length; i++) {
                        int nx = cx + dx[i];
                        int ny = cy + dy[i];
                        if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;
                        if (!mask[nx, ny] || visited[nx, ny]) continue;
                        visited[nx, ny] = true;
                        qx[tail] = nx;
                        qy[tail] = ny;
                        tail++;
                    }
                }
                boxes.Add(box);
            }
        }
        return boxes;
    }

    private static Box Tighten(Box component, bool[,] solid, int width, int height) {
        Box tight = new Box { MinX = width - 1, MinY = height - 1, MaxX = 0, MaxY = 0, Area = 0 };
        for (int y = component.MinY; y <= component.MaxY; y++) {
            for (int x = component.MinX; x <= component.MaxX; x++) {
                if (!solid[x, y]) continue;
                if (x < tight.MinX) tight.MinX = x;
                if (y < tight.MinY) tight.MinY = y;
                if (x > tight.MaxX) tight.MaxX = x;
                if (y > tight.MaxY) tight.MaxY = y;
                tight.Area++;
            }
        }
        if (tight.Area == 0) return component;
        return tight;
    }

    private static void SaveTransparentCrop(Bitmap source, string outputPath, int x, int y, int width, int height, int threshold) {
        bool[,] edgeBackground = EdgeConnectedBackground(source, x, y, width, height, threshold);
        using (Bitmap output = new Bitmap(width, height, PixelFormat.Format32bppArgb)) {
            for (int py = 0; py < height; py++) {
                for (int px = 0; px < width; px++) {
                    Color c = source.GetPixel(x + px, y + py);
                    if (edgeBackground[px, py] && !TouchesSpritePixel(source, x, y, width, height, px, py, threshold)) {
                        output.SetPixel(px, py, Color.FromArgb(0, 0, 0, 0));
                    } else {
                        output.SetPixel(px, py, Color.FromArgb(255, c.R, c.G, c.B));
                    }
                }
            }
            output.Save(outputPath, ImageFormat.Png);
        }
    }

    private static bool[,] EdgeConnectedBackground(Bitmap source, int x, int y, int width, int height, int threshold) {
        bool[,] visited = new bool[width, height];
        int[] qx = new int[width * height];
        int[] qy = new int[width * height];
        int head = 0;
        int tail = 0;

        Action<int, int> enqueue = (px, py) => {
            if (px < 0 || py < 0 || px >= width || py >= height) return;
            if (visited[px, py]) return;
            Color c = source.GetPixel(x + px, y + py);
            if (Math.Max(c.R, Math.Max(c.G, c.B)) > threshold) return;
            visited[px, py] = true;
            qx[tail] = px;
            qy[tail] = py;
            tail++;
        };

        for (int px = 0; px < width; px++) {
            enqueue(px, 0);
            enqueue(px, height - 1);
        }
        for (int py = 0; py < height; py++) {
            enqueue(0, py);
            enqueue(width - 1, py);
        }

        int[] dx = new int[] {-1, 0, 1, 0};
        int[] dy = new int[] {0, -1, 0, 1};
        while (head < tail) {
            int cx = qx[head];
            int cy = qy[head];
            head++;
            for (int i = 0; i < dx.Length; i++) {
                enqueue(cx + dx[i], cy + dy[i]);
            }
        }

        return visited;
    }

    private static bool TouchesSpritePixel(Bitmap source, int x, int y, int width, int height, int px, int py, int threshold) {
        for (int dy = -1; dy <= 1; dy++) {
            int ny = py + dy;
            if (ny < 0 || ny >= height) continue;
            for (int dx = -1; dx <= 1; dx++) {
                int nx = px + dx;
                if (nx < 0 || nx >= width) continue;
                Color c = source.GetPixel(x + nx, y + ny);
                if (Math.Max(c.R, Math.Max(c.G, c.B)) > threshold) {
                    return true;
                }
            }
        }
        return false;
    }
}
"@

function Convert-ToSlug([string] $name) {
    $lower = $name.ToLowerInvariant()
    $normalized = $lower -replace '[^a-z0-9]+', '_'
    return $normalized.Trim('_')
}

function Get-CombatAtlasCharacter([double] $centerX, [double] $centerY) {
    $left = $centerX -lt 768
    if ($centerY -lt 135) { return $(if ($left) { "armored_brute" } else { "spider_atlas" }) }
    if ($centerY -lt 270) { return $(if ($left) { "wolf_atlas" } else { "giant_snake" }) }
    if ($centerY -lt 415) { return $(if ($left) { "goblin_atlas" } else { "skeleton_warrior" }) }
    if ($centerY -lt 560) { return $(if ($left) { "ogre" } else { "bat" }) }
    if ($centerY -lt 710) { return $(if ($left) { "skeleton_archer" } else { "lizardman" }) }
    if ($centerY -lt 855) { return $(if ($left) { "dire_boar" } else { "wraith" }) }
    return $(if ($left) { "bandit" } else { "hell_hound" })
}

function Save-FlippedPng([string] $sourcePath, [string] $targetPath) {
    $image = [System.Drawing.Bitmap]::FromFile($sourcePath)
    try {
        $flipped = $image.Clone()
        try {
            $flipped.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX)
            $flipped.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)
        } finally {
            $flipped.Dispose()
        }
    } finally {
        $image.Dispose()
    }
}

$rawPath = Resolve-Path -LiteralPath $RawRoot
$projectPath = Resolve-Path -LiteralPath $ProjectRoot
$outputRoot = Join-Path $projectPath "assets\combat\characters\villains\raw_extracted"
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null

$files = Get-ChildItem -Path $rawPath -Recurse -Include *.png,*.jpg,*.jpeg,*.webp | Sort-Object FullName
$manifestItems = @()

foreach ($file in $files) {
    $parentName = $file.Directory.Name
    if ($parentName -in @("pose", "move", "walk", "attack", "hurt", "die")) {
        $parentName = $file.Directory.Parent.Name
    }
    if ($file.Name -like "*combat zbiorczy*") {
        $characterSlug = "combat_atlas"
        $actionSlug = "frames"
    } else {
        $characterSlug = Convert-ToSlug $parentName
        $actionSlug = "pose"
    }

    $characterRoot = Join-Path $outputRoot $characterSlug
    $frameRoot = Join-Path $characterRoot $actionSlug
    New-Item -ItemType Directory -Force -Path $frameRoot | Out-Null
    $prefix = "raw_${characterSlug}_${actionSlug}"
    $framesJson = [RawCombatCharacterExtractor]::Extract($file.FullName, $frameRoot, $prefix, $BackgroundThreshold, $Padding, $MinWidth, $MinHeight, $MinArea)
    $framesObject = $framesJson | ConvertFrom-Json
    if ($framesObject.PSObject.Properties.Name -contains "value") {
        $frames = @($framesObject.value)
    } else {
        $frames = @($framesObject)
    }

    if ($characterSlug -eq "combat_atlas") {
        $groupCounters = @{}
        foreach ($frame in $frames) {
            $centerX = [double]$frame.x + ([double]$frame.width / 2.0)
            $centerY = [double]$frame.y + ([double]$frame.height / 2.0)
            $atlasCharacter = Get-CombatAtlasCharacter $centerX $centerY
            if (-not $groupCounters.ContainsKey($atlasCharacter)) {
                $groupCounters[$atlasCharacter] = 0
            }
            $groupRoot = Join-Path $outputRoot $atlasCharacter
            $groupFrameRoot = Join-Path $groupRoot "atlas_frames"
            $groupRightRoot = Join-Path $groupRoot "atlas_frames_right"
            $groupLeftRoot = Join-Path $groupRoot "atlas_frames_left"
            New-Item -ItemType Directory -Force -Path $groupFrameRoot | Out-Null
            New-Item -ItemType Directory -Force -Path $groupRightRoot | Out-Null
            New-Item -ItemType Directory -Force -Path $groupLeftRoot | Out-Null
            $sourceFrame = Join-Path $frameRoot $frame.file
            $targetFrameName = "raw_${atlasCharacter}_atlas_frame_$('{0:D3}' -f $groupCounters[$atlasCharacter]).png"
            Copy-Item -LiteralPath $sourceFrame -Destination (Join-Path $groupFrameRoot $targetFrameName) -Force
            Copy-Item -LiteralPath $sourceFrame -Destination (Join-Path $groupRightRoot $targetFrameName) -Force
            Save-FlippedPng $sourceFrame (Join-Path $groupLeftRoot $targetFrameName)
            $groupCounters[$atlasCharacter] += 1
        }
    } else {
        $rightRoot = Join-Path $characterRoot "${actionSlug}_right"
        $leftRoot = Join-Path $characterRoot "${actionSlug}_left"
        New-Item -ItemType Directory -Force -Path $rightRoot | Out-Null
        New-Item -ItemType Directory -Force -Path $leftRoot | Out-Null
        foreach ($frame in $frames) {
            $sourceFrame = Join-Path $frameRoot $frame.file
            Copy-Item -LiteralPath $sourceFrame -Destination (Join-Path $rightRoot $frame.file) -Force
            Save-FlippedPng $sourceFrame (Join-Path $leftRoot $frame.file)
        }
    }

    $relativeSource = Resolve-Path -LiteralPath $file.FullName
    $manifestItems += [ordered]@{
        character = $characterSlug
        action = $actionSlug
        source = $relativeSource.Path
        output = $frameRoot
        frame_count = @($frames).Count
        frames = $frames
    }
    Write-Output ("{0}: {1} frames" -f $file.FullName, @($frames).Count)
}

$manifest = [ordered]@{
    generated_by = "tools/characters/extract_raw_combat_characters.ps1"
    raw_root = $rawPath.Path
    output_root = $outputRoot
    background_threshold = $BackgroundThreshold
    padding = $Padding
    items = $manifestItems
}

$manifestPath = Join-Path $outputRoot "manifest.json"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 12), $utf8NoBom)

$readmePath = Join-Path $outputRoot "README.md"
$readme = @(
    '# Raw Extracted Combat Characters',
    '',
    'Generated from `game_dir/raw_assety/combat/characters`.',
    '',
    'The extractor removes near-black background pixels, crops detected sprite components, and writes transparent PNG frames plus `manifest.json`.',
    '',
    'Near-black pixels are removed only when they belong to edge-connected background, so dark outlines and interior shadow pixels stay opaque.',
    '',
    'Large single-character sheets are written as `<character>/pose/raw_<character>_pose_frame_###.png` and mirrored into `<character>/pose_right` plus `<character>/pose_left`.',
    '',
    'The combined combat atlas is written twice: once as `combat_atlas/frames` and once grouped into `<monster>/atlas_frames` folders for easier sandbox browsing.',
    '',
    'Atlas monsters also get `atlas_frames_right` and mirrored `atlas_frames_left` folders, so combat can pick facing-specific sprites without runtime flipping.',
    '',
    'Regenerate with:',
    '',
    '```powershell',
    '.\tools\characters\extract_raw_combat_characters.ps1',
    '```'
)
[System.IO.File]::WriteAllText($readmePath, ($readme -join [Environment]::NewLine), $utf8NoBom)

Write-Output ("Manifest: {0}" -f $manifestPath)
