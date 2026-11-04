# Living mercenary region / stage77

Status: IMPLEMENTED / AUTOMATED_PASS / AWAITING_INTERACTIVE. Final74/74 source
checks PASS, zero errors/warnings and exact checked-source fingerprint match.
Native146checks/48pointer actions/18captures PASS. Ordinary physical mine victory
and player review remain pending.
User authorizes the living-world proposal after requiring preservation of the
approved art. Stage76 snapshot/style and the ordinary campaign remain intact.
Work is local on master; no commit/push is requested or performed.

## Delivered scope

The first region uses the accepted authored world illustration, with continuous
land/road travel, visible interpolated company/caravan/patrol/raider positions,
pause/1x/2x/4x, named keyboard actions and company food/wages/fatigue/camp.
Three settlements expose actual supply/security and prices. Nearby friendly
patrols protect caravans; raiders reduce stock, deliveries restore it. Rivalry
extends the Iron patrol's route into the border; actual patrol contact causes
skirmish losses and journal feedback. This is the small living-region proof,
before seeded geography/modular terrain and wider campaign-content production.

Three condition-created contracts: mine restoration, border reconnaissance and
food delivery. Actual issuer/location, objective and stock gate acceptance/report;
payment and faction relations occur once. A completed managed mine with a cleared
combat room restores supplies/security and stops mine raiders. Retreat, bypassed
defenders, failed/duplicate returns do not grant this objective. The cleared
mine stays cleared, with no re-entry loot farm in the pilot.

Existing owned equipment/training/trading, dungeon packing/exploration/combat,
road ambush and atomic receipts are reused. New room/camp checkpoint counts
charge strategic time once; dungeon time does not also consume surface food.
The optional version1 `living_world` block extends v4 without migration/reset of
legacy saves. Serialization preserves full floating-point actor positions.

## Evidence

- Living domain28/0, campaign integration41/0, UI97/0 and three Python
  reference/schema tests PASS. Connected land routes, sea rejection, equal-tick
  determinism, actual raids/deliveries/upkeep, real faction contact, contract
  progression/rewards, full-precision save/reload, rollback and corrupt state are
  covered. Surface proximity also exercises existing ambush/toll/battle snapshots.
- Positive mine settlement uses explicitly labelled trusted saved-state boundary
  fixtures. These establish the bridge and its guards; they are not a played
  victory or physical acceptance. Existing dungeon/combat suites own legal wins.
- Native preliminary `living-layout-fixed`:132checks/44engine-local pointer
  actions/16captures at1280x720 and1920x1080 PASS, zero diagnostics. Actual
  contract acceptance, course without teleport, Space/pause, sea rejection,
  provision transaction, equipment round trip, normal owned packing/Start and
  ordinary retreat back to the living company are exercised.
- The first native `living-first` fixture missed a wrapping stock-label layout
  problem. Visual inspection caught it; explicit stock width plus header/map
  geometry assertions repair it. Preserve that initial evidence as superseded.
- Final native extended world/faction fixture:
  `artifacts/qa-runs/living-world-native-final/native-review.json`:146checks/
  48pointer actions/18captures PASS at both resolutions, zero diagnostics.
  Simulated days produce actual patrol contact, strength loss and raids/delivery
  messages. The last presentation pass keeps all three tabs visible at720p and
  whole-number stock/reward text after JSON reload.
- Final complete source verification:
  `artifacts/qa-runs/living-world-payroll-final/report.json`:74/74 PASS,
  zero diagnostics, checked source fingerprint matches. Tracked compact receipt:
  `docs/design/living-world/2026-11-04/verification-receipt.json`.
  Earlier complete source sweep `living-world-complete` passed74/74. The final
  payroll refinement charges daily wages inside the dungeon while avoiding
  duplicate food consumption; two new boundary checks prove it charges once.
  It does not change the already-captured native scenarios.
- All119approved campaign art/font files still match the saved baseline hashes;
  the preservation ZIP and external backup remain unchanged. Native gallery and
  compact receipts are retained under docs/design/living-world/2026-11-04/.

Native fixtures use an isolated minimized/no-focus GPU host, a memory-only
company and native pointer/key events. An embedded scene host runs the same
navigation targets/ordinary Controls inside the SubViewport; production uses
normal scene changes. No OS input or player-save access occurs. The independent
pilot profile used by the player is resumable `user://qa_living_world_v1.json`.

## Player review

[Native screenshot gallery](../design/living-world/2026-11-04/index.html).

Close the previous preview and run from the game root:

```powershell
& .\tools\qa\start_game.ps1 -Scene living-world
```

1. Starts paused in Ravenford. Inspect prices/supply/security, then Contracts ->
   accept Reopen the Old Mine. Opening Contracts pauses time.
2. Click Old Mine or passable land; use Space and1/2/4 or toolbar controls.
   Observe the company and independent caravan/patrol/raider banners. Sea clicks
   are rejected. Company & gear opens existing equipment; Back/Map returns paused.
3. At the actual mine, Prepare -> pack owned supplies -> Start Expedition.
   Complete a normal generated/authored mine, clearing at least one defended
   room, then finish/return. The mine should remain restored and raiders disperse.
   An ordinary retreat must leave the objective unfinished and retryable.
4. Travel back to Ravenford and report for45gold/20XP/+10League relation exactly
   once. Compare real stock/security and food price, then restart remotely or
   mid-course to confirm exact persistent state (load resumes paused).
5. In Saltwatch accept/deliver3owned food. In Black Keep accept reconnaissance,
   visit High Pass, return/report; inspect Iron support and changing rivalry.
   Camp/4x time lets caravans, raids and eventually border clashes unfold.
6. Back to atlas leaves the separate pilot and reads the ordinary profile;
   relaunching the pilot resumes it. No automatic reset or player-save replacement.

Physical L77-01: AWAITING_INTERACTIVE. Next after review: seeded geography,
modular rendering in this art family, further dungeon objectives and contracts.
