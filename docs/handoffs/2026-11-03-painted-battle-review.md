# Six painted roles: battle review prepared

Superseded next-task status: actual partial user feedback and implemented
corrections are in [stage57 handoff](2026-11-03-drawn-battle-feedback.md). The
preparation record below is historical; do not treat its pending feedback as current.

User selects point1: ordinary battle review of the current six roles. Stage56 is
IMPLEMENTED / AUTOMATED_PASS / AWAITING_INTERACTIVE, not visual acceptance.
Read [stage56](../qa/stages/2026-11-03-stage-56.md) and presentation022 before work.

New encounter `drawn_roster_skirmish`: four allies (knight, warrior, archer_1,
rogue_1) versus four enemies (two axe_bandit, two bandit_spearman), existing Old
Mine board and resolver. Explicit matching loadouts; daggers/spear use ordinary
adjacent melee, not new weapon mechanics. Sources/accepted art are unchanged.
Direct user command:

```powershell
& "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\tools\qa\start_game.ps1" -Scene combat -CombatScenario drawn_roster_skirmish
```

Control allies normally; End Turn, then Tools / Enemy AI once repeatedly during
enemy turns. Each click is one AI command. Move uses preview then second-click
confirmation. Tools / Painted Six - Old Mine / Load restarts. Win normally, then
test defeat by ending allied turns; report readability and role/action defects.

Automated301checks/0: each role movement/attack/hit/death, full final frames,
impact/MP/input/reset, loaded board sprites and opt-in/default paths. Full legal
Godot simulations reach victory69commands/3rounds and defeat96commands/4rounds,
without Debug Win. Drawn7368/0, equipment31/0, feedback179/0, lifecycle/combat
slices and validator PASS. Launcher ConfigureOnly/invalid-argument checks PASS,
previous ignored override restored exactly; DISPLAY1 mapping verified leftmost.
Ignored logs/report under artifacts/drawn-animation; stage56 has exact commands.

Active branch master. Changes remain local/uncommitted; no publication requested
by this task. Desktop input/visible agent launch still not released. The user can
run the command; an asynchronous question requests their battle result/defects.
No result has yet arrived. L56-01/L56-02 and prior L53/L54/61 physical cases remain
NOT_RUN. Do not infer acceptance or start weapon-system/full-roster production.

Next: incorporate user feedback from the actual battle, fix reproduced issues
within point1 and retest affected paths. Only after an explicit next-scope request
proceed to the proposed equipment/identity work, early human batch or creature
pilot. Reusable English workshop v1.0.1 remains published/installed; see the
[workshop handoff](2026-11-03-painted-workshop.md).
