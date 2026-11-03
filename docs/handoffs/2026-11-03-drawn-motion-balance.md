# Natural gait and two-handed swordsman: candidate ready for retest

USER_REJECTED_AND_ROLLED_BACK. Follow
[rollback handoff](2026-11-03-drawn-rollback.md). The user rejects this model/posture
and requests the previous version and stopping; the record below is historical.

Latest user feedback rejects stage57's frantic foot cycling and requests broader
combat feet plus a lowered neutral sword for the two-handed knight (distinct from
the sword/shield warrior). No terminal battle result or next production batch is
given. Stage58 IMPLEMENTED / AUTOMATED_PASS / AWAITING_USER_RETEST. Read
[stage58](../qa/stages/2026-11-03-stage-58.md) and presentation022/slice022.

All96 walk sources now8x100ms=800ms cycle,160px stride: same200px/s root travel as57,
half the cycling. Do not restore57's50ms cels or the workshop's older80px stride.
Both source/runtime/preview calibration are updated. Knight neutral/combat idles
and neutral walks are redrawn in five views plus three reflections: wide/staggered
guard A and visibly lowered held neutral sword, including previously empty-hand
views.128 runtime PNGs change;2176 others and all non-walk timings unchanged.
The previous warrior/north sword occlusion is preserved. All artwork stays painted.

Sources/prompts/reference sheets and861 before identities are under
`assets_src/characters/drawn_animation/2026-11-03/refinements/motion_balance`.
Aseprite owns cleanup/export/idle planting/retiming and source reopen proof.
`balance_drawn_motion.py`, `verify_drawn_motion_balance.py` and the stage report
record reproduction. Current published workshopv1.0.1 is unchanged; this is a
game-specific candidate, not an automatically approved new reusable baseline.

Full native7386/0, battle307/0, original15679/0, equipment31/0, feedback179/0,
lifecycle/combat slices/import/offline3579/validator PASS.36-case native/enlarged
comparison with distance-aware floor is supplied. Static poses inspected; continuous
motion/user acceptance pending. Before/after viewer:

```powershell
& "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\tools\qa\start_drawn_motion_balance_preview.ps1"
```

Actual battle (new window; normal controls, Tools / Enemy AI once for enemy turns):

```powershell
& "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\tools\qa\start_game.ps1" -Scene combat -CombatScenario drawn_roster_skirmish
```

Next: user's retest of natural cadence and knight postures, then only fixes within
point1. L57-01 is partial with rejected cadence; L58-01 NOT_RUN. Terminal victory/
defeat, campaign and prior61 physical cases remain open. Current master changes
remain local/uncommitted. No desktop release, new character batch or publication
is inferred. Retain previous baselines and handoffs as historical evidence.
