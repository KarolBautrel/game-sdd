# 001 Vertical Slice

Status: draft  
Date: 2026-07-14

## Scenario

The player starts in Ravenford, chooses the Old Mine from the world map, explores a small dungeon, enters combat, defeats one enemy, receives loot, and returns to the world map.

## Required modes

- Town mode
- World map mode
- Dungeon exploration mode
- Turn-based combat mode

## Acceptance Criteria

### Town entry

- Given the game starts from a clean state
- When the initial save state is created
- Then the active town is `town_ravenford`
- And town services include `inn`, `blacksmith`, and `market`

### World travel

- Given the player is on `region_001`
- When the player selects the edge from `town_ravenford` to `dungeon_old_mine`
- Then travel is allowed
- And the travel cost is exactly 6 hours and 1 food

### Dungeon entry

- Given the player enters `dungeon_old_mine`
- Then the dungeon data must reference a map path
- And the dungeon must reference an encounter table id
- And retreat is allowed

### Combat action

- Given a unit has at least 1 AP
- When it performs `basic_attack` against an adjacent enemy
- Then 1 AP is consumed
- And damage is at least 1
- And the action emits a combat event

### Reproducibility

- Given the same RNG seed and command list
- When the vertical slice is replayed
- Then combat and loot outcomes are identical

## Data references

- `resources/data/world_regions/region_001.json`
- `resources/data/towns/town_ravenford.json`
- `resources/data/dungeons/dungeon_old_mine.json`
- `resources/data/combat_actions/basic_attack.json`

