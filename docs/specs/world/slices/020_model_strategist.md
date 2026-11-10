# Strategist protocol and persistence proof

Owner [world019](../019_model_strategist.md), stage96. Implemented; automated
proof [QA](../../../qa/2026-11-09-strategist-adapter.md), physical L96-01 deferred.

- Finite privacy-preserving observations/capabilities, strict request/reply schema,
  exact JSON continuation and rejection of fabricated IDs/events/operators.
- Actual accepted goal and lawful candidate effects at fixed boundary; classic
  remains active before reply and on missing/stale/deadline/budget/timeout faults.
- Bilateral consent, resource conservation and changed-precondition rejection.
- Mode-generation cancellation, duplicate/out-of-order replies, journal pruning
  watermarks, stagger/coalescing, real-time rate and world-day token/call limits.
- Atomic dispatch/reply/boundary save failure, cached retry, restart interruption,
  stale callback isolation and checkpoint-plus-command-tail replay without calls.
- Native distinct classic/recorded labels and seed-specific save isolation;
  existing region/managed dungeon and v1/v2/v3 remain unchanged.

Proof suites and executed results are recorded in the stage96 QA report. No live
model, physical appearance/input or strategy balance is inferred from fixtures.
Focused suites: strategist_adapter_tests184, strategist_session_tests67,
strategist_expedition_tests131 and strategist_interface_tests54checks. Seven
Python tests validate schemas/negative references. The inherited native managed
chain uses31ordinary resolver commands, real loot/return/report and write retry.
The portable checkpoint/tail fixture also runs through strategist_replay.gd.
