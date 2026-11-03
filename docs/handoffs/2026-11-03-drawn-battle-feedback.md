# Brisk walking and rear stance correction: ready for user retest

Superseded: user rejects the fast foot cadence. Follow the
[stage58 motion balance handoff](2026-11-03-drawn-motion-balance.md) for current
800ms/160px gait and two-handed knight poses. Preserve this record as history.

User reviewed the actual Painted Six battle: movement is much too slow; exact
rear view of the one-handed warrior has narrow feet. They explicitly clarify
the sword should be more occluded by the body. Remaining animation/movement looks
good to them. No victory/defeat result was reported. This is partial live feedback,
not permission for another roster batch or full acceptance of terminal cases.

Stage57 IMPLEMENTED / AUTOMATED_PASS / AWAITING_USER_RETEST. Read
[stage57](../qa/stages/2026-11-03-stage-57.md), presentation022/slice022/milestone017.
Current six-role walks are2x faster:8x50ms=400ms at unchanged80px stride. All96
editable source clips/manifests/runtime/player timings agree; all non-walk timings
and combat rules unchanged. Warrior/north has wider standing feet and held sword
concealed in front of torso, inner shield retained. Exactly36 runtime PNG changes;
all other facings/roles and the accepted north death source/exports are unchanged.

Built-in imagegen raw/prompt plus Aseprite cleanup/export/idle planting retained;
313 baseline files with hashes under refinements/battle_feedback/before. New
walk_timing_report proves all768 walk frames reopen unchanged apart from timing.
verify_drawn_battle_feedback.py proves unchanged non-walk timings and narrow scope.
Full player3579 checks, native7386/0, battle307/0, original15679/0, equipment31/0,
feedback179/0, lifecycle/combat slices/import/validator PASS. Actual104px movement
fixtures0.555..0.562s against0.52s declared. Current batch summary updated.

Review samples (18 before/after clips, native/2x, normal speed and pause/step):

```powershell
& "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\tools\qa\start_drawn_battle_feedback_preview.ps1"
```

Battle (new window; Tools / Enemy AI once during enemy turns):

```powershell
& "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\tools\qa\start_game.ps1" -Scene combat -CombatScenario drawn_roster_skirmish
```

Next: collect the user's visual retest of speed and rear stance/sword, fix any
reproduced issue within point1. L57-01 NOT_RUN; L56-01 partial with defects;
ordinary victory/defeat and prior campaign/61 physical cases stay open. Current
master changes are local/uncommitted. No desktop release, new production batch,
Git publication or workshop release is inferred. Published English workshopv1.0.1
remains unchanged; these are game-specific candidates until user review.
