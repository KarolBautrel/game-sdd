[CmdletBinding()]
param(
    [string]$GodotPath = '',
    [ValidateSet('dungeon', 'combat', 'map-editor', 'app', 'styles')]
    [string]$Scene = 'dungeon',
    [ValidateRange(800, 2560)][int]$Width = 1920,
    [ValidateRange(600, 1440)][int]$Height = 1080,
    [switch]$TraceInput,
    [switch]$ConfigureOnly,
    [ValidateRange(0, 2147483647)][int]$CombatSeed = 0
)

$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    $GodotPath = Join-Path (Split-Path -Parent (Split-Path -Parent $repoRoot)) 'installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe'
}
if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw "Godot executable not found: $GodotPath"
}
$qaDisplays = @(& (Join-Path $PSScriptRoot 'get_displays.ps1'))
$qaDisplay = @($qaDisplays | Where-Object { $_.DeviceName.EndsWith('DISPLAY1') })
if ($qaDisplay.Count -ne 1) { throw 'DISPLAY1 is unavailable; launch cancelled.' }
$qaDisplay = $qaDisplay[0]
if ($qaDisplay.X -ne ($qaDisplays | Measure-Object -Property X -Minimum).Minimum) {
    throw 'DISPLAY1 is no longer the leftmost screen; verify Godot screen mapping before launch.'
}
if ($Width -gt $qaDisplay.WorkingWidth -or $Height + 40 -gt $qaDisplay.WorkingHeight) {
    throw 'Requested window does not fit DISPLAY1 working area, including title bar.'
}
$qaX = $qaDisplay.WorkingX + [int][Math]::Floor(($qaDisplay.WorkingWidth - $Width) / 2)
$qaY = $qaDisplay.WorkingY + [int][Math]::Floor(($qaDisplay.WorkingHeight - $Height - 40) / 2)
$scenes = @{
    'dungeon' = 'res://scenes/dungeon/DungeonDebug.tscn'
    'combat' = 'res://scenes/combat/CombatDebug.tscn'
    'map-editor' = 'res://scenes/combat/CombatMapEditor.tscn'
    'app' = 'res://scenes/app/App.tscn'
    'styles' = 'res://scenes/combat/CharacterStylePreview.tscn'
}
$overridePath = Join-Path $repoRoot 'override.cfg'
$profileMarker = '; sdd QA launcher local profile'
if ((Test-Path -LiteralPath $overridePath) -and -not ((Get-Content -LiteralPath $overridePath -Raw).StartsWith($profileMarker))) {
    throw 'Existing override.cfg is not owned by the QA launcher; refusing to replace it.'
}
@"
$profileMarker
[application]
run/main_scene="$($scenes[$Scene])"
[display]
window/size/mode=0
window/size/initial_position_type=3
window/size/initial_screen=0
window/size/window_width_override=$Width
window/size/window_height_override=$Height
[debug]
qa/combat_seed=$CombatSeed
"@ | Set-Content -LiteralPath $overridePath -Encoding UTF8
$runId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffffffZ')
$evidenceDir = Join-Path $repoRoot "artifacts\qa-runs\launch-$runId"
New-Item -ItemType Directory -Path $evidenceDir | Out-Null
$arguments = @('--path', ('"' + $repoRoot + '"'), '--windowed', '--screen', '0', '--resolution', "${Width}x${Height}", $scenes[$Scene])
if ($TraceInput) { $arguments += @('--', '--qa-input-trace') }
$qaProcess = $null
$startupState = 'configured_only'
$startupExitCode = $null
if (-not $ConfigureOnly) {
    $qaProcess = Start-Process -FilePath $GodotPath -ArgumentList $arguments -WorkingDirectory $repoRoot -WindowStyle Normal -PassThru -RedirectStandardOutput (Join-Path $evidenceDir 'stdout.log') -RedirectStandardError (Join-Path $evidenceDir 'stderr.log')
    $qaProcessHandle = $qaProcess.Handle
    $startupState = 'running'
    if ($qaProcess.WaitForExit(2000)) {
        $qaProcess.WaitForExit()
        $startupState = 'exited'
        $startupExitCode = $qaProcess.ExitCode
    }
}
$launch = [ordered]@{
    schema = 'sdd.interactive-launch-v1'
    process_id = $qaProcess.Id
    scene = $scenes[$Scene]
    requested_display = $qaDisplay.DeviceName
    display_primary = $qaDisplay.Primary
    physical_resolution = @($qaDisplay.Width, $qaDisplay.Height)
    working_area = @($qaDisplay.WorkingX, $qaDisplay.WorkingY, $qaDisplay.WorkingWidth, $qaDisplay.WorkingHeight)
    requested_position = @($qaX, $qaY)
    godot_screen = 0
    placement = 'Godot other-screen center; mixed DPI handled by engine'
    configure_only = [bool]$ConfigureOnly
    startup_state = $startupState
    startup_exit_code = $startupExitCode
    window_style = 'Normal'
    requested_window_size = @($Width, $Height)
    requested_mode = 'windowed'
    trace_input = [bool]$TraceInput
    combat_seed = $CombatSeed
    interactive_acceptance = 'NOT_RUN'
}
$launch | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $evidenceDir 'launch.json') -Encoding UTF8
$launch | ConvertTo-Json -Depth 4
if ($startupState -eq 'exited') {
    throw "Godot closed during startup (exit $startupExitCode). Logs: $evidenceDir"
}
