param(
    [string] $ProjectRoot = "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game",
    [int] $Padding = 6,
    [int] $DilateRadius = 5,
    [int] $MinWidth = 34,
    [int] $MinHeight = 42,
    [int] $MinArea = 900
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

public static class MercenaryCombatHeroExtractor {
    private struct Box {
        public int MinX;
        public int MinY;
        public int MaxX;
        public int MaxY;
        public int Area;
    }

    public static string Extract(string sourcePath, string outputDir, string outputPrefix, int padding, int dilateRadius, int minWidth, int minHeight, int minArea) {
        Directory.CreateDirectory(outputDir);
        using (Bitmap source = new Bitmap(sourcePath)) {
            bool[,] solid = BuildSolidMask(source);
            bool[,] mask = Dilate(solid, source.Width, source.Height, dilateRadius);
            List<Box> boxes = Components(mask, source.Width, source.Height);
            List<Box> kept = new List<Box>();
            foreach (Box component in boxes) {
                Box tight = Tighten(component, solid, source.Width, source.Height);
                int width = tight.MaxX - tight.MinX + 1;
                int height = tight.MaxY - tight.MinY + 1;
                if (width < minWidth || height < minHeight || tight.Area < minArea) continue;
                kept.Add(tight);
            }

            kept.Sort((a, b) => {
                int centerYA = (a.MinY + a.MaxY) / 2;
                int centerYB = (b.MinY + b.MaxY) / 2;
                if (Math.Abs(centerYA - centerYB) > 72) return centerYA.CompareTo(centerYB);
                if (a.MinX != b.MinX) return a.MinX.CompareTo(b.MinX);
                return a.MinY.CompareTo(b.MinY);
            });

            StringBuilder json = new StringBuilder();
            json.Append("[\n");
            int saved = 0;
            int rowIndex = -1;
            int currentRowCenter = -9999;
            int frameInRow = 0;
            foreach (Box tight in kept) {
                int centerY = (tight.MinY + tight.MaxY) / 2;
                if (rowIndex < 0 || Math.Abs(centerY - currentRowCenter) > 96) {
                    rowIndex++;
                    currentRowCenter = centerY;
                    frameInRow = 0;
                } else {
                    currentRowCenter = (currentRowCenter + centerY) / 2;
                }

                int x = Math.Max(0, tight.MinX - padding);
                int y = Math.Max(0, tight.MinY - padding);
                int right = Math.Min(source.Width - 1, tight.MaxX + padding);
                int bottom = Math.Min(source.Height - 1, tight.MaxY + padding);
                int cropWidth = right - x + 1;
                int cropHeight = bottom - y + 1;

                string action = ActionForRow(rowIndex);
                string rightFileName = outputPrefix + "_right_" + action + "_" + frameInRow.ToString("D3") + ".png";
                string leftFileName = outputPrefix + "_left_" + action + "_" + frameInRow.ToString("D3") + ".png";
                string rightPath = Path.Combine(outputDir, action, rightFileName);
                string leftPath = Path.Combine(outputDir, action, leftFileName);
                Directory.CreateDirectory(Path.GetDirectoryName(rightPath));
                SaveTransparentCrop(source, rightPath, x, y, cropWidth, cropHeight);
                SaveFlippedPng(rightPath, leftPath);

                if (saved > 0) json.Append(",\n");
                json.Append("  {");
                json.Append("\"action\":\"").Append(action).Append("\",");
                json.Append("\"row\":").Append(rowIndex).Append(",");
                json.Append("\"frame\":").Append(frameInRow).Append(",");
                json.Append("\"right\":\"").Append((action + "/" + rightFileName).Replace("\\", "\\\\")).Append("\",");
                json.Append("\"left\":\"").Append((action + "/" + leftFileName).Replace("\\", "\\\\")).Append("\",");
                json.Append("\"x\":").Append(x).Append(",");
                json.Append("\"y\":").Append(y).Append(",");
                json.Append("\"width\":").Append(cropWidth).Append(",");
                json.Append("\"height\":").Append(cropHeight).Append(",");
                json.Append("\"source_width\":").Append(source.Width).Append(",");
                json.Append("\"source_height\":").Append(source.Height);
                json.Append("}");
                saved++;
                frameInRow++;
            }
            json.Append("\n]\n");
            return json.ToString();
        }
    }

    private static string ActionForRow(int rowIndex) {
        switch (rowIndex) {
            case 0: return "pose";
            case 1: return "walk";
            case 2: return "combat";
            case 3: return "hit";
            default: return "death";
        }
    }

    private static bool[,] BuildSolidMask(Bitmap source) {
        bool[,] solid = new bool[source.Width, source.Height];
        for (int y = 0; y < source.Height; y++) {
            for (int x = 0; x < source.Width; x++) {
                Color c = source.GetPixel(x, y);
                solid[x, y] = c.A > 16 && !IsGreenBackground(c);
            }
        }
        return solid;
    }

    private static bool IsGreenBackground(Color c) {
        return c.G >= 135 && c.R <= 105 && c.B <= 120 && c.G > c.R + 55 && c.G > c.B + 55;
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

    private static void SaveTransparentCrop(Bitmap source, string outputPath, int x, int y, int width, int height) {
        using (Bitmap output = new Bitmap(width, height, PixelFormat.Format32bppArgb)) {
            for (int py = 0; py < height; py++) {
                for (int px = 0; px < width; px++) {
                    Color c = source.GetPixel(x + px, y + py);
                    if (IsGreenBackground(c)) {
                        output.SetPixel(px, py, Color.FromArgb(0, 0, 0, 0));
                    } else {
                        output.SetPixel(px, py, Color.FromArgb(c.A, c.R, c.G, c.B));
                    }
                }
            }
            output.Save(outputPath, ImageFormat.Png);
        }
    }

    private static void SaveFlippedPng(string sourcePath, string targetPath) {
        using (Bitmap source = new Bitmap(sourcePath)) {
            using (Bitmap flipped = (Bitmap)source.Clone()) {
                flipped.RotateFlip(RotateFlipType.RotateNoneFlipX);
                flipped.Save(targetPath, ImageFormat.Png);
            }
        }
    }
}
"@

function Convert-ToSlug([string] $name) {
    $lower = $name.ToLowerInvariant()
    $normalized = $lower -replace '[^a-z0-9]+', '_'
    return $normalized.Trim('_')
}

function Get-MercenaryId([System.IO.FileInfo] $file, [string] $sourceRoot, [bool] $nestedByClass) {
    $relative = $file.FullName.Substring($sourceRoot.Length).TrimStart('\', '/')
    $parts = $relative -split '[\\/]'
    if ($nestedByClass -and $parts.Length -ge 3) {
        return Convert-ToSlug $parts[1]
    }
    if ($parts.Length -ge 2) {
        return Convert-ToSlug $parts[0]
    }
    return Convert-ToSlug $file.Directory.Name
}

$projectPath = Resolve-Path -LiteralPath $ProjectRoot
$sourceGroups = @(
    [ordered]@{
        Category = "hero_mercenaries"
        Root = (Join-Path $projectPath "assets\combat\characters\heroes\mercenaries")
        ProcessedRoot = (Join-Path $projectPath "assets\combat\characters\heroes\mercenaries\processed")
        ProcessedRootRelative = "assets\combat\characters\heroes\mercenaries\processed"
        NestedByClass = $true
    },
    [ordered]@{
        Category = "npc"
        Root = (Join-Path $projectPath "assets\combat\characters\npc")
        ProcessedRoot = (Join-Path $projectPath "assets\combat\characters\npc\processed")
        ProcessedRootRelative = "assets\combat\characters\npc\processed"
        NestedByClass = $false
    },
    [ordered]@{
        Category = "villain_bandits"
        Root = (Join-Path $projectPath "assets\combat\characters\villains\bandits")
        ProcessedRoot = (Join-Path $projectPath "assets\combat\characters\villains\bandits\processed")
        ProcessedRootRelative = "assets\combat\characters\villains\bandits\processed"
        NestedByClass = $false
    }
)

$globalManifestItems = @()
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

foreach ($group in $sourceGroups) {
    if (-not (Test-Path -LiteralPath $group.Root)) {
        continue
    }

    $processedRoot = $group.ProcessedRoot
    New-Item -ItemType Directory -Force -Path $processedRoot | Out-Null

    $sourceItems = Get-ChildItem -Path $group.Root -Recurse -File -Filter *.png |
        Where-Object { $_.FullName -notlike "*\processed\*" } |
        ForEach-Object {
            [ordered]@{
                File = $_
                Root = $group.Root
                NestedByClass = [bool]$group.NestedByClass
            }
        } |
        Sort-Object { $_.File.FullName }

    $manifestItems = @()
    foreach ($sourceItem in $sourceItems) {
        $file = $sourceItem.File
        $mercenaryId = Get-MercenaryId $file $sourceItem.Root $sourceItem.NestedByClass
        $outputDir = Join-Path $processedRoot $mercenaryId
        if (Test-Path -LiteralPath $outputDir) {
            Remove-Item -LiteralPath $outputDir -Recurse -Force
        }
        New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

        $framesJson = [MercenaryCombatHeroExtractor]::Extract($file.FullName, $outputDir, $mercenaryId, $Padding, $DilateRadius, $MinWidth, $MinHeight, $MinArea)
        $framesObject = $framesJson | ConvertFrom-Json
        if ($framesObject.PSObject.Properties.Name -contains "value") {
            $frames = @($framesObject.value)
        } else {
            $frames = @($framesObject)
        }

        $manifest = [ordered]@{
            generated_by = "tools/characters/extract_mercenary_combat_heroes.ps1"
            category = $group.Category
            source = $file.FullName.Replace($projectPath.Path + "\", "")
            character_id = $mercenaryId
            output = (Join-Path $group.ProcessedRootRelative $mercenaryId)
            direction_contract = @{
                source = "right"
                mirrored = "left"
            }
            row_action_contract = @{
                "0" = "pose"
                "1" = "walk"
                "2" = "combat"
                "3" = "hit"
                "4_plus" = "death"
            }
            frames = $frames
        }
        [System.IO.File]::WriteAllText((Join-Path $outputDir "manifest.json"), ($manifest | ConvertTo-Json -Depth 12), $utf8NoBom)
        $manifestItem = [ordered]@{
            category = $group.Category
            character_id = $mercenaryId
            source = $manifest.source
            output = $manifest.output
            frame_count = @($frames).Count
        }
        $manifestItems += $manifestItem
        $globalManifestItems += $manifestItem
        Write-Output ("{0}/{1}: {2} frames" -f $group.Category, $mercenaryId, @($frames).Count)
    }

    $index = [ordered]@{
        generated_by = "tools/characters/extract_mercenary_combat_heroes.ps1"
        category = $group.Category
        processed_root = $group.ProcessedRootRelative
        items = $manifestItems
    }
    [System.IO.File]::WriteAllText((Join-Path $processedRoot "manifest.json"), ($index | ConvertTo-Json -Depth 12), $utf8NoBom)

    $readme = @(
        '# Processed Combat Character Sheets',
        '',
        ('Generated category: `{0}`.' -f $group.Category),
        '',
        'The extractor chroma-keys green backgrounds, crops detected sprite components, assigns rows to coarse action groups, and writes mirrored left/right PNG variants.',
        '',
        'Current action row contract:',
        '',
        '- row 1: `pose`',
        '- row 2: `walk`',
        '- row 3: `combat`',
        '- row 4: `hit`',
        '- row 5+: `death`',
        '',
        'Regenerate with:',
        '',
        '```powershell',
        '.\tools\characters\extract_mercenary_combat_heroes.ps1',
        '```'
    )
    [System.IO.File]::WriteAllText((Join-Path $processedRoot "README.md"), ($readme -join [Environment]::NewLine), $utf8NoBom)
    Write-Output ("Manifest: {0}" -f (Join-Path $processedRoot "manifest.json"))
}

$globalIndex = [ordered]@{
    generated_by = "tools/characters/extract_mercenary_combat_heroes.ps1"
    items = $globalManifestItems
}
[System.IO.File]::WriteAllText((Join-Path $projectPath "assets\combat\characters\processed_character_sheets_manifest.json"), ($globalIndex | ConvertTo-Json -Depth 12), $utf8NoBom)
