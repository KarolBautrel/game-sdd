# Background contract and combat-preview work

2026-11-09. Local master583ebc84; preserve all earlier stages85..89. User requests
only work without desktop takeover. No OS input, window activation, visible game
launch or computer-use tool was used. No commit/push request.

## Delivered behavior

Living-world contracts now have one read-only domain availability query shared
by commands, campaign feedback and native cards. Delivery progress shows actual
carried food versus3. Recon progress names its unvisited target and issuer;
completed objectives explain where to report. Disabled Accept/Report tooltips
explain missing stock, actual stopped issuer, incomplete objective, active
expedition/encounter or already paid/closed jobs. Refresh preserves existing card
nodes. Prices, rewards, upkeep, accepted artwork and animations are unchanged.

Owners: world010/slice015, presentation036/slice036. Shared save schema is
unchanged; failure still publishes no candidate state or partial reward.

## Combat-preview investigation

Combat presentation068/slice107 has a real headless HUD/animation regression:
475checks/40cases PASS. Real action controls and number shortcut switching,
rendered target Labels, unchanged preview inputs and actual animated commits
agree for Torin basic/Aimed, Rogue, Bran and Knight, three ordinary command
indices plus a deterministic basic-shot miss and near-death targets.

Torin basic2/Aimed3 and Rogue melee3 are correctly distinguished. The tentative
earlier2preview/3applied observation was not reproduced; no damage or animation
"fix" is claimed. This isolates the common transitions, not every possible
interception/status/physical timing condition. Revisit only with a concrete
reproduction. Existing blocked/clear LOS and domain tests remain intact.

## Contract and upkeep proof

- Session151checks PASS: absent/duplicate offers, unknown jobs, insufficient /
  exactly3food, wrong/stale/moving issuer, supply/relation caps, real accepted
  High Pass visit, premature and duplicate reporting, pre-acceptance visit,
  pending event/managed expedition gates, exact shared rejection reasons.
- Fresh QA-only disk file: failed write preserves the accepted snapshot/file;
  retry pays exactly once, paid disk reload is exact, duplicate attempt changes
  no bytes. The owned QA file is removed afterwards; player profiles untouched.
- Food32tick/wage96tick boundaries and batched simulation match. Camp recovers
  fatigue without movement and still pays food/wages at their boundary. Empty
  food or gold does not prevent legal travel.
- Native interface157checks PASS at1280x720/1920x1080/2560x1440: progress/reasons,
  command/UI parity, enablement after stock/location/stage changes, paid refresh,
  repeated UI signal protection, card identity and status text bounds.

The following automated service chains use normal course/tick/purchase/accept /
report calls from the fresh80g/16Food company. They do not teleport to an
objective. Raiders are handled by ordinary paid tolls, not a fake battle result.
Each completes Saltwatch delivery, Black Keep reconnaissance via High Pass and
return; buys one food at the actual2g quote; earns32g/8XP total; ends with River
League+2 and Iron March+6. Gold independently reconciles payouts minus wages,
actual purchase invoices and recorded toll deductions.

| Geography | Strategic time | Final gold | Final food | Wages | Provisions | Tolls |
| --- | --- | --- | --- | --- | --- | --- |
| Authored Marches | 121ticks /30h15m | 107 | 11 | 3 | 2 | 0 |
| Large Marches2087 | 306ticks /76h30m | 96 | 5 | 9 | 2 | 5 |
| Large Marches20261107 | 337ticks /84h15m | 91 | 4 | 9 | 2 | 10 |

All chains finish at fatigue100 because they deliberately do not camp. These
are reproducible technical diagnostics, not a judgment that fatigue/travel pace
or economy feels good. No balance values were changed.

## Verification

Focused commands use the existing Godot4.7 console binary with --headless:

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script res://scripts/presentation/combat_preview_consistency_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script res://scripts/session/living_contract_regression_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script res://scripts/presentation/living_world_interface_tests.gd
```

Final full-run receipt and focused logs are retained under
docs/design/background-polish/2026-11-09/. Automated results do not close the
remaining ordinary desktop cases; full verification result is appended below
after completion.

## Deferred work

- L91-01: ordinary delivery and recon in the visible game, including shopping,
  camp/return costs, actual report controls and restart.
- L91-02: user/readability review of new progress and disabled-control reasons.
- Remaining L77-01 camp/speeds/raids/conflict and user art/movement review.
- Broader contract pools, new faction mechanics and balance tuning remain later
  scoped work. No desktop takeover until user releases controls.

## Final verification result

```powershell
.\.venv\Scripts\python.exe tools/qa/verify_project.py --run-id background-contracts-20261109-final
```

Final92/92 PASS,0errors/0warnings,75Python tests, every discovered Godot suite
and nine scene boots. Includes475preview /151contract /157interface checks,
combat slices and existing living-world/domain/session coverage. Started
2026-11-09T10:03:46.856653+00:00; finished 2026-11-09T10:11:23.168833+00:00. Source SHA256
`350a9e4d534dc6b96923a35d3752c9ca5116a7c159c593808fed306ef6f9eb99` matches after the run and evidence copy.
[Complete report](../design/background-polish/2026-11-09/verification.json),
[preview cases](../design/background-polish/2026-11-09/preview-cases.json),
[service-chain metrics](../design/background-polish/2026-11-09/economy-chains.json),
[preservation](../design/background-polish/2026-11-09/preservation.json).
Eight preexisting profiles and the designer terrain/atlas remain byte-identical
to their established baselines. `git diff --check` passes. No desktop interaction,
visible launch, commit or push. Stage91 remains AWAITING_INTERACTIVE.
