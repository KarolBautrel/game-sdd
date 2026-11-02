# Final integrated acceptance

Status: implemented and accepted. Date: 2026-11-01.

This accepted status describes stage7 below. Current stages8..22 are a separate
user-authorized background batch with final live acceptance still pending.
Combat overview093/slice101 own its readiness matrix; live-test-scenarios.md
tracks all30 deferred actual-play cases. Stage22 adds the tooling002 exported
visual inventory/service/map probe and a fresh corrected build; its report is the latest
technical build identity. Stage12 below remains historical.

Acceptance evidence: source stage7-fixed-20261101 passes34/34 with zero
diagnostics; fresh stage7-release-fixed-20261101 export/probe passes. Actual play
found and repaired an empty-Tween Defend defect (combat074/slice096). The
corrected EXE passed two Defend actions, ordinary three-enemy victory in round3,
injury return, bandage,6/6 finish, settlement and process restart. The closed
interactive log has zero errors/warnings. Campaign75g/16XP/nine items, Bran7/14
and Torin10/10 persisted without duplicate rewards. A temporary capture failure
was recovered by resetting the automation session; the same battle continued.
Build identity, all named checks and exact observed route:
docs/qa/stages/2026-11-01-stage-7.md.

After stages0..6 pass, run the complete source verifier and scene checker, then
build a fresh Windows release with export_smoke.py --release. Record hashes,
engine identity, source fingerprint (including export_presets.cfg), diagnostics
and all five exported scene tokens. The runtime probe executes the exported EXE
outside the source directory and uses an in-memory campaign. It must not modify
the player's save. Keep the owned local monitor profile outside the PCK.

Actual release acceptance uses windowed DISPLAY1 and normal visible controls:
hub/town, preparation, exploration/event/hazard, ordinary tactical movement,
attack and victory, return, rewards and finish/settlement. No Debug Win or state
injection substitutes for gameplay. Any blocking defect reopens its owner and
requires targeted proof, full regression and a new export before acceptance.

Final report maps all stage gates, provides build/test locations, launch steps
and concrete scope limits. No automatic commit/push or external distribution.
Proof: tooling slice004, complete stage7 report.
