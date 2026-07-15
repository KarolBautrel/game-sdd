param(
    [string] $ProjectRoot = "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game"
)

$ErrorActionPreference = "Stop"

$projectPath = Resolve-Path -LiteralPath $ProjectRoot
$encounterRoot = Join-Path $projectPath "resources\data\combat_encounters"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function New-FloorTiles([int] $width, [int] $height) {
    $tiles = @()
    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            $tiles += [ordered]@{ x = $x; y = $y; type = "floor" }
        }
    }
    return $tiles
}

function New-Stats([int] $hp, [int] $strength, [int] $defense, [int] $initiative, [int] $movePoints, [int] $ap) {
    return [ordered]@{
        max_hp = $hp
        strength = $strength
        defense = $defense
        initiative = $initiative
        move_points = $movePoints
        max_ap = $ap
        accuracy = 0
        evasion = 0
    }
}

function New-Unit(
    [string] $id,
    [string] $team,
    [int] $x,
    [int] $y,
    [hashtable] $stats,
    [string[]] $actions,
    [string] $visualCharacter
) {
    $unit = [ordered]@{
        id = $id
        team = $team
        position = [ordered]@{ x = $x; y = $y }
        stats = $stats
        resources = [ordered]@{ hp = $stats.max_hp; ap = $stats.max_ap; mp = $stats.move_points }
        statuses = @()
        available_actions = $actions
    }
    if ($visualCharacter -ne "") {
        $unit.visual = [ordered]@{ faction = $(if ($team -eq "player") { "heroes" } else { "villains" }); character = $visualCharacter }
    }
    return $unit
}

$showcases = @(
    @{ id = "debug_raw_goblin_spider_showcase"; label = "Raw Goblin + Spider"; first = "goblin_atlas"; second = "spider_atlas" },
    @{ id = "debug_raw_brute_ogre_showcase"; label = "Raw Brute + Ogre"; first = "armored_brute"; second = "ogre" },
    @{ id = "debug_raw_wolf_snake_showcase"; label = "Raw Wolf + Snake"; first = "wolf_atlas"; second = "giant_snake" },
    @{ id = "debug_raw_undead_showcase"; label = "Raw Undead"; first = "skeleton_warrior"; second = "wraith" },
    @{ id = "debug_raw_beasts_showcase"; label = "Raw Beasts"; first = "dire_boar"; second = "hell_hound" }
)

foreach ($showcase in $showcases) {
    $encounter = [ordered]@{
        id = $showcase.id
        seed = 3001
        background_path = "res://assets/combat/terrain/backgrounds/old_mine_meadow_00_lush.png"
        grid = [ordered]@{
            width = 12
            height = 7
            tiles = New-FloorTiles 12 7
        }
        units = @(
            (New-Unit -id "unit_player_001" -team "player" -x 4 -y 3 -stats (New-Stats 14 5 2 12 4 2) -actions @("move", "basic_attack", "defend", "end_turn") -visualCharacter "warrior"),
            (New-Unit -id "unit_enemy_001" -team "enemy" -x 7 -y 3 -stats (New-Stats 9 4 1 8 4 1) -actions @("move", "basic_attack", "defend", "end_turn") -visualCharacter $showcase.first),
            (New-Unit -id "unit_enemy_002" -team "enemy" -x 8 -y 4 -stats (New-Stats 8 3 1 7 4 1) -actions @("move", "basic_attack", "defend", "end_turn") -visualCharacter $showcase.second)
        )
        turn_state = [ordered]@{
            active_unit_id = "unit_player_001"
            round = 1
            turn_order = @("unit_player_001", "unit_enemy_001", "unit_enemy_002")
        }
        event_log = @()
    }

    $path = Join-Path $encounterRoot "$($showcase.id).json"
    [System.IO.File]::WriteAllText($path, ($encounter | ConvertTo-Json -Depth 12), $utf8NoBom)
    Write-Output $path
}
