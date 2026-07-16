# Slice 086: Combat UI Asset Pipeline V1

Status: active

Owner spec: `docs/specs/combat/presentation/086_combat_ui_asset_pipeline_v1.md`

## Scenario

Given source character sheets under:

- `assets/combat/characters/heroes/mercenaries/`
- `assets/combat/characters/npc/`
- `assets/combat/characters/villains/bandits/`

When the asset extraction pipeline runs

Then each source sheet is converted into transparent processed PNG frames

And each processed frame has a source-facing right variant plus a mirrored left variant

And `CombatUnitArt` can resolve a processed mercenary frame for the debug combat player

And the combat debug board uses a 2.5D tactical scale rather than an isometric/diamond projection.

And movement cycles through extracted `walk` frames while the unit travels between tiles.

And attack, hit, and death beats cycle through extracted combat-state frames.

And moved units return to facing the nearest living opponent after movement.

And debug showcase combatants use weapon/loadout data that matches their visible source model.

And enemy visuals resolve by archetype role before numeric unit id fallback.

And defeated units play death frames and remain on board as non-blocking corpse visuals.

## Acceptance Checks

- `tools/characters/extract_mercenary_combat_heroes.ps1` produces processed character folders and manifests for mercenaries, NPCs, and bandits.
- The processed output includes `pose`, `walk`, `combat`, `hit`, and `death` action assignments when source rows are detected.
- `unit_player_001` resolves to a processed mercenary warrior sprite in the debug showcase.
- `unit_enemy_001` and `unit_enemy_002` resolve to processed bandit sprites in the debug showcase.
- The debug combat scene loads headlessly after the tile/unit scale change.
- `CombatUnitArt` resolves frame-suffixed movement actions such as `walk:1` to real processed walk frames.
- `CombatUnitArt` resolves frame-suffixed combat actions such as `combat:1`, `hit:1`, and `death:1` to real processed frames.
- Combat debug uses 140x104 movement cells and foot-anchored unit positioning.
- Unit HP/AP/MP labels are raised above the sprite head at normal board positions.
- The bandit archer keeps a bow/ranged profile, while the axe bandit uses a melee axe profile.
- `raider_archer` resolves to an archer visual even if its generated unit id is not `unit_enemy_002`.
- `raider_swordsman` and `raider_shieldman` resolve to melee/shield visuals even if their generated unit ids are not `unit_enemy_001`.
- A defeated processed unit resolves to its final death frame for corpse rendering.

## Automated Proof

- `scripts/presentation/combat_mercenary_asset_pipeline_tests.gd`

## Manual Review Gap

Automated tests can prove path resolution and scene loading, but sprite quality still needs manual review:

- confirm the green background is gone;
- confirm left/right facing is correct;
- confirm the warrior scale looks right against the 2.5D board;
- confirm the board does not look isometric.
