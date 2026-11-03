[CmdletBinding()]
param([switch]$ConfigureOnly)
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'start_game.ps1') -Scene combat -CombatScenario painted_enemy_pilot -ConfigureOnly:$ConfigureOnly
