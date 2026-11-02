# Combat readiness review for dungeon

Status: technical review/source/export PASS; live acceptance pending.
Date:2026-11-01. Stage12 / queue19.

## Readiness contract

Review the existing milestone exit criteria against current owning specs and
named proofs. Do not treat historical Done labels, prior builds, headless scene
loads or Debug Win as evidence of new visual/actual-play acceptance.

Required technical gates: authored encounters/maps/archetypes/loadouts validate;
current presentation/target/animation/HUD tests and combat/dungeon/campaign suites
pass; all five scenes load; strict scene checker passes; fresh Windows release
exports and runs from its own directory without source dependencies. Preserve
player saves and local monitor-profile exclusion from the PCK.

Export probe additionally loads clearing_crossfire through the actual scenario
picker controller and checks its map, four units and numeric resource UI, then
executes a normal confirmed move and verifies state/MP/input unlock. Emit
`SDD_EXPORT_ENCOUNTER_PASS clearing_crossfire` only after those checks pass.
External smoke requires that token, every scene token and final probe token;
partial/ignored execution must fail. The probe remains opt-in/headless and does
not access the player's campaign. This is automation, not actual visible play.

The review report maps each milestone criterion to owner/slice/test and deferred
live scenarios. Stages8..12 stay AWAITING_INTERACTIVE until every required live
case passes on the final code/build, with log audit and reproducible evidence.
Record failures and reopen their owners before fixes. The user's current batch
override permits ordered automated implementation, not automatic acceptance.

## Scope limits

No claim of final art/feel/balance, full region travel, inventory/equipment UI,
blacksmith/progression, new3D models or mid-turn tactical save. Existing debug
preview can expose the simulated roll/outcome; changing that information policy
is a separate design task, not an undocumented change in this review.

Proof: chronological slice101, stage12 report and live-test-scenarios.md.
