# Stage62: SE/SW tactical battle view

User explicitly requests only south_east/south_west in tactical combat, including
when the opponent is above. Preserve the other drawings for future possibilities;
city movement is not planned/implemented. IMPLEMENTED / AUTOMATED_PASS /
AWAITING_USER_VISUAL_REVIEW. Changes remain local with the earlier stage61 work.

The existing battle renderer reduces displayed direction to a front three-quarter
view. Left/right geographic directions choose SW/SE; exactly vertical or absent
targets use player SE/enemy SW. This applies to both teams, every legacy/painted
family and the Bran equipment variant, through idle, walk, attack, reaction and
final corpse. Battle preloads only those two views. Full geographic events and
raw art lookups remain; domain logic, trajectories and timing/stride are unchanged.

`tactical_facing_tests.gd`:4751checks/0. Tests load actual textures for all renderer
families/aliases, both teams and all raw facing requests; nearest enemies above/
below/left/right; ordinary HUD startup, a two-tile north walk and above-left/right
bow attacks to resolver victory/final death. Every observed displayed sprite is
SE/SW and animation unlocks. A one-cell fixture initially expected a full walk
cycle incorrectly; the fixture was extended to a real two-cell route, preserving
the accepted gait/travel relationship. Geographic movement-state tests also PASS.

`run_hero_equipment_checks.py`: full drawn runtime7386/0, battle313/0, tactical
4751/0, original15679/0, equipment31/0, feedback179/0, lifecycle/domain combat
PASS; identity1046/0, campaign gear50/0, campaign session/trade48/0 and validator
PASS. Source proof: all2304 accepted PNG hashes unchanged and all seven painted
families still have eight authored views. No PNG/Aseprite file was edited/deleted.
Logs/reports: artifacts/tactical-facing and artifacts/drawn-animation.

Source players and art galleries still expose eight views as archives. No
automatic broad art acceptance is inferred. L62-01 ordinary visual play remains
open; no desktop input or visible game launch was used by the agent.

User command, larger left DISPLAY1:

```powershell
& "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\tools\qa\start_game.ps1" -Scene combat -CombatScenario drawn_roster_skirmish
```

For the campaign equipment pilot with the same two-view battle rule, use
`tools/qa/start_hero_equipment_pilot.ps1`. Keep the separate pilot save and actual
player save. No new commit/push or next roster work is authorized by this change.
