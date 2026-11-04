# Timed polish review guide

Run from the active repository:

```powershell
cd C:\Users\karol\Desktop\Gierka\game_dir\sdd-game
```

| Review | Command | Boundary |
| --- | --- | --- |
| Campaign: world, equipment and expedition | `& .\tools\qa\start_game.ps1 -Scene app -HeroEquipmentPilot` | Separate resumable QA campaign; original player save preserved |
| Illustrated dungeon UI | `& .\tools\qa\start_game.ps1 -Scene dungeon` | Free dungeon sandbox; Start, inspect a room, confirm passage |
| Forest battle | `& .\tools\qa\start_game.ps1 -Scene combat -CombatScenario painted_forest_ambush` | Independent battle; normal action/tile controls |
| Mine battle | `& .\tools\qa\start_game.ps1 -Scene combat -CombatScenario painted_mine_breach` | Independent battle; upper/lower crossings |
| Courtyard prototype | `& .\tools\qa\start_game.ps1 -Scene town-preview` | In-memory pilot; WASD/arrows, E/Enter, Escape; no campaign access |

Launchers target larger left DISPLAY1 and record PID/logs; do not close another
instance implicitly. Close the previous review normally when changing scenes.
Combat Tools exposes the existing scenario picker/reload. No Debug Win is needed
for acceptance. The courtyard is the first mechanical study, not the final city.

Current physical test gaps: L67..71 in live-test-scenarios.md. Automated source,
native engine-input and exported-build proofs are recorded separately. Sky/official
CUA activation failed; desktop permission is already granted for this session,
and no successful physical controls/playthrough were claimed.
