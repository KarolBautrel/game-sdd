# Background follow-up: stable actions and complete native contract

Latest user request: handle everything that does not require their own testing.
Completed the bounded background queue on master583ebc84. Changes are LOCAL,
uncommitted; no new commit/push or desktop takeover was requested. No OS input
was sent. Do not treat prior expired two-hour delegation as current permission.

Read ../qa/2026-11-05-background-followup.md for commands, failures/fixes and all
receipts. Portable evidence: ../design/background-polish/2026-11-05/index.html.

## Delivered

-85, presentation044/slice044: primary action slots retain membership, order,
  position and number across AP/MP depletion and cooldown. Disabled slots have
  muted icons/captions and actual shortage/cooldown reasons. Numeric1..9 matches
  its displayed primary slot, ignores disabled/developer/modifier/repeat input,
  and respects gallery/animation locks. Unavailable selection falls back to a
  usable action. No combat rule or character/art/motion change.
-86, dungeon presentation014/slice056: source/reroll/difficulty changes used to
  clear town_preparation and silently turn owned campaign prep into a sandbox.
  Preserve origin during preview reset. Existing begin_run still charges owned
  packing exactly once and rejects shortages without losing preparation.
- Native ordinary Painted Six victory,69commands,153pointer events,534checks,
  no rejected/forced command. Existing AI policy chooses commands for both teams;
  normal UI submits them. This does not close the third PHYSICAL desktop battle.
- Native full Large-region mine contract: accept, travel, owned authored-mine
  prep, actual guarded-room victory33commands, loot7g/12XP/rusty_key, exit,
  settlement, issuer report45g/20XP/+10League, duplicate-payment rejection, exact
  disk reload paused, mine stays cleared/unfarmable and raider departures stop.
 270checks/102clicks,0diagnostics. Both RMB/MMB camera gestures pass without
  changing course/time/resources. Uses fresh custom QA-directory profile and
  seed20261105/Marches/Large; never player saves. Production combat scene changes
  run normally, then the QA host adopts each into its offscreen viewport.

## Verification and preservation

- Full background-followup-final89/89 PASS,0errors/0warnings; completed
 2026-11-05T08:53:10Z. Source SHA256
 072abfea07accbc7cf1edcb51c75d23b04813fbf35158caefcff42f4f52fb5c0.
- Stable-action focused126, preparation-context32, route-preview31 PASS. Native
  stable tray105checks/18clicks/18keys/12captures at720p/1080p/1440p PASS.
- Six unchanged GPU captures, named native receipts, campaign commands/final
  state and full-source report are portable in the gallery folder. All16static
  gallery references and capture SHA256 values checked. No browser play claimed.
- Designer revision9 SHA a5d90d2ff4dbf36d0f3b46856fc30be0812767876cc407e72c3c0067a8a8f327
  and approved atlas SHA516bdc4ad1635f931c79fac9eaaaba0ac041607dc5aacc501593907cd41ea9a5
  are unchanged. No accepted character or runtime art assets were edited. Private
  packages/dark-fantasy-ui-workshop remains ignored. Existing player saves intact.

## Next

1. User review only: Large-map composition, stage82 pace/feet and stage83 props.
   Do not redesign accepted character poses or infer approval from native PASS.
2. When desktop controls are released, restart ordinary Painted Six and perform
   the complete physical L77-01 campaign loop; native tests are already done.
   Previous physical victories remain Forest/Mine, two total. Third desktop
   battle still interrupted; physical RMB/MMB and user feel remain distinct.
3. No further feature expansion is currently needed for this bounded request.
   Commit/push only if the user asks; work is validated locally and ready.

Later PowerShell commands from the repository:

```powershell
& .\tools\qa\start_game.ps1 -Scene combat -CombatScenario drawn_roster_skirmish
& .\tools\qa\start_game.ps1 -Scene regions
Start-Process .\docs\design\background-polish\2026-11-05\index.html
```

Never overwrite the user's terrain mask or player profile. Native QA runs require
fresh run ids and create their own QA-only profiles; do not reuse them as player
progress or as proof of physical/user acceptance.
