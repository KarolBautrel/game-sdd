# Background combat and campaign follow-up

User request: finish work that does not need their own testing. Work remains
local on master, base583ebc84; no commit/push or new desktop takeover requested.
No OS input was sent. Accepted character artwork, poses, motion and designer r9
remain intact. User art/pace approval and physical desktop cases stay separate.

## Delivered behavior

- Stage85, presentation044/slice044: granted actions retain their slot/number
  when AP/MP runs out or a skill is cooling down. Unavailable actions stay muted
  with a truthful reason. Disabled clicks/numbers are inert; number1..9 uses only
  its displayed primary action, never a developer command. Repeat/modified keys,
  gallery input suspension and animation locks are respected. An unavailable
  selected action falls back to a usable action. Domain rules stay unchanged.
- Stage86, dungeon presentation014/slice056: changing source, rerolling or
  changing difficulty during owned preparation previously cleared
  town_preparation, so Start could silently enter a sandbox. Preview resets now
  preserve their campaign origin. Start still uses the existing atomic packing
  transaction; rejected packing retains preparation and spends nothing.

## Focused and native proof

- stable_combat_actions_tests.gd:126checks/0failures, four distinct player kits,
  resource/cooldown order, equipment costs, inert disabled input, fallback,
  real Shield wall cooldown and next-turn refresh.
- combat_hud_layout_tests.gd, combat_slice_tests.gd: PASS.
- dungeon_preparation_context_tests.gd:32checks/0failures, source/reroll/difficulty,
  managed and sandbox origins, insufficient-owned-stock failure, exact packing
  charges and equipped snapshot. Existing dungeon_route_preview_tests.gd:31/0.
- stable-actions-native-final:105checks,18clicks,18key events,12captures at
  1280x720/1920x1080/2560x1440,0errors/0warnings. Captures visually inspected for
  disabled controls, stable order, readable captions and responsive bounds.
- painted-six-native-background: normal drawn_roster_skirmish victory after
  69commands,153pointer events,534checks,1capture,0errors/0warnings. Full walk,
  attack/hit/death frames sampled by the renderer. Actual controls match the
  unchanged resolver. Existing AI policy chooses allied/enemy commands; no
  combat-state boost, fake terminal payload or Debug Win. This is native input,
  not a third physical desktop victory.
- living-contract-native-final:270checks,102pointer events,6captures,0errors/
  0warnings. Fresh seed20261105/Marches/Large company in a unique QA-only disk
  profile. Accept issuer contract, normal surface travel, owned authored-mine
  preparation,33ordinary tactical commands to guarded-room victory, loot7g/12XP/
  rusty_key, exit, real settlement, return and report45g/20XP/+10League relation.
  Paid state is domain `completed`; UI displays Paid. Duplicate reporting and
  settlement are rejected without changes; exact disk reload resumes paused;
  revisiting the restored mine disables preparation. Raider departures stop.
  Both RMB/MMB pan/release change only camera position, not time/course/resources.

The native host is minimized/unfocused, with engine-local pointer/key events.
Its isolated Godot user directory contains the unique campaign profile. Production
combat scene changes actually run; the harness then adopts each new scene into
the GPU viewport without replacing its session/transaction callbacks. Physical
input and player profiles are untouched.

## Failures found and corrected

- stable-actions-native-first referenced the pre-command actor Dictionary after
  the resolver replaced the state. All three MP assertions were stale test
  references; the final harness reads the current committed actor. No runtime
  movement change was needed.
- living-contract-native-first exercised pan on authored geography, where the
  large-map camera is intentionally unavailable. Move the gesture/contract test
  to an actual Large generated region. It also exposed the genuine preparation
  origin defect fixed under dungeon slice056. Its battle was aborted after prior
  failures, so it is not a lost/played-victory receipt.
- living-contract-native-fixed completed the real campaign successfully, but
  its final assertion expected stage `paid`; the existing domain uses
  `completed`. Correct the test expectation, leave the domain unchanged and run
  the whole fresh-profile loop again. Final run passes all270checks.

## Final source verification

Full run `background-followup-final`:89/89 PASS,0errors/0warnings, including
Python validation/tests, all discovered Godot suites and nine scene boots.
Started2026-11-05T08:46:30Z; finished08:53:10Z. Source SHA256:
`072abfea07accbc7cf1edcb51c75d23b04813fbf35158caefcff42f4f52fb5c0`.
[Complete check receipt](../design/background-polish/2026-11-05/source-verification.json).
Final source fingerprint rechecked unchanged after documentation/evidence capture.
Designer r9 and approved atlas match their previously published SHA256 values.
`git diff --check` passes; existing CRLF-to-LF notices are not content errors.

## Evidence and retained checks

[Portable gallery and native receipts](../design/background-polish/2026-11-05/index.html).
Six unchanged GPU captures, all named native checks and the full campaign
command/final-state receipt are preserved there. Static gallery files are
validated; no browser playback or new user visual acceptance is claimed.

Native commands, from the repository:

```powershell
.\.venv\Scripts\python.exe tools/qa/render_campaign.py --run-id stable-actions-native-final --suite play --views stableactions --sizes 1280x720,1920x1080,2560x1440 --exercise --timeout 180
.\.venv\Scripts\python.exe tools/qa/render_campaign.py --run-id painted-six-native-background --suite play --views paintedsix --sizes 1920x1080 --exercise --timeout 400
.\.venv\Scripts\python.exe tools/qa/render_campaign.py --run-id living-contract-native-final --suite play --views livingcontract --sizes 1920x1080 --exercise --timeout 400
.\.venv\Scripts\python.exe tools/qa/verify_project.py --run-id background-followup-final
```

Run ids are immutable: use fresh names for a repeat. Physical L84-03 and L77-01
remain open; neither native victory closes their desktop acceptance. User review
of stage81 larger-map composition and stage82/83 movement/props is still pending.
No further feature expansion is inferred from this background follow-up.

Later interactive launch:

```powershell
& .\tools\qa\start_game.ps1 -Scene combat -CombatScenario drawn_roster_skirmish
& .\tools\qa\start_game.ps1 -Scene regions
```
