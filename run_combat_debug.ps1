$ErrorActionPreference = "Stop"

$projectPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$godotPath = "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"

if (-not (Test-Path -LiteralPath $godotPath)) {
    throw "Godot executable not found: $godotPath"
}

if (-not (Test-Path -LiteralPath (Join-Path $projectPath "project.godot"))) {
    throw "project.godot not found in: $projectPath"
}

Set-Location -LiteralPath $projectPath
& $godotPath --path $projectPath --scene "res://scenes/combat/CombatDebug.tscn"
