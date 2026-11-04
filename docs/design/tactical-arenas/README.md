# Authored arena pilots

Two independent review scenarios share the accepted four allies and painted
bandit archer/shield fighter/wolf. Existing campaign encounter pools stay intact.

| Arena | Decision | Authored terrain |
| --- | --- | --- |
| Forest Ambush | Approach the northern ranged rise or take the wide lower flank | Broken log/stone belt, low brush, woodland floor |
| Mine Breach | Queue through the upper gap or use the two-cell lower passage | Sparse stone piers, crate/rubble cover, eastern rise |

Allies start in the lower-left with room to move. Existing4MP heroes can make a
normal opening approach; the archer's3MP and wolf's5MP retain role differences.
Highground costs2MP and uses existing ranged bonuses; low cover uses the existing
ranged hit modifier. Blockers stop walking; the current rules do not implement
wall line-of-sight. Avoid treating columns as bulletproof cover.

Canonical sources: resources/tiled/maps/painted_{forest_ambush,mine_breach}.tmx.
Edit there, then run `.venv/Scripts/python.exe tools/qa/build_painted_arenas.py
--export`. `--check` verifies derived maps/encounters without changing sources.
Spawns map onto the approved pilot actors; no stat/art/timing edits are allowed
through this builder. Catalogue registration is explicit; current default stays.

Source preview commands from the repository:

```powershell
& .\tools\qa\start_game.ps1 -Scene combat -CombatScenario painted_forest_ambush
& .\tools\qa\start_game.ps1 -Scene combat -CombatScenario painted_mine_breach
```

The720p fallback now compacts battle chrome to preserve floor area. Larger views
retain the approved brass/leather/parchment hierarchy. See presentation030 and
its slice for strict tests and separate physical acceptance.
