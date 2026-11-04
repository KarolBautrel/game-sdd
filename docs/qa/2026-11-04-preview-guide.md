# Timed polish review guide

Current authorized world stage77: `& .\tools\qa\start_game.ps1 -Scene living-world`.
Separate resumable pilot save, continuous map, contextual contracts and mine
consequences. Read [living-region review](2026-11-04-living-world.md). Old atlas
remains available/visually approved; physical mine victory is still pending.

Current ordered player review and feedback:
[six-step checklist](2026-11-04-player-review-checklist.md). Step1(dungeon) is
now visually accepted after native stage75. The user explicitly reprioritized
step3: world/province atlas, stage76. Launch App and click World atlas; see
[world atlas review](2026-11-04-world-atlas.md). Equipment and the remaining
steps stay pending. Detailed physical full-flow actions were not reported.
[Correction evidence and screenshots](2026-11-04-dungeon-visual-cohesion.md).

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
The dungeon starts with generated content by default. Choose **Use Old Mine**
before **Start Expedition** to inspect the illustrated authored map.
Combat Tools exposes the existing scenario picker/reload. No Debug Win is needed
for acceptance. The courtyard is the first mechanical study, not the final city.

Current physical test gaps: L67..71 in live-test-scenarios.md. Automated source,
native engine-input and exported-build proofs are recorded separately. Sky/official
CUA activation failed; desktop permission is already granted for this session,
and no successful physical controls/playthrough were claimed.
