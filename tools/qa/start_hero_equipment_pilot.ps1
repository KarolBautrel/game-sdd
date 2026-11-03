[CmdletBinding()]
param([switch]$ConfigureOnly)
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'start_game.ps1') -Scene app -HeroEquipmentPilot -ConfigureOnly:$ConfigureOnly
