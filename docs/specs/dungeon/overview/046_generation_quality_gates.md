# Generated dungeon quality gates

Status: implemented and accepted. Date: 2026-11-01.

Templates explicitly declare acceptance_state=candidate or accepted. Runtime
selection uses accepted templates only, including fallback selection. Missing
or candidate-only pools fail closed (empty draft) rather than starting an empty
or experimental expedition. Promotion is an explicit data edit after proofs;
tests/reports never promote content automatically.

Both authored template validation and runtime graph checks reject duplicate room
ids/positions, invalid/self/duplicate edges, disconnected rooms, missing entrance
or exit, no treasure/combat, and deep-mine layouts with fewer than three combats.
Template pacing counts for treasure/combat/planned hazards match actual slots.
Route length is existing authored pacing guidance, not a computed shortest path.
Generated encounters and event/hazard references must resolve to existing content.

Generation remains seed deterministic; accepted pool ordering remains stable.
QA sweeps seeds1..100 for each profile, checks deterministic full materialization,
connectivity, encounter paths, hazards and template diversity. It emits a JSON
report with individual seeds, template ids and failures. This structural gate
does not prove final combat/economy balance or replace hands-on play.

Proof: slice054, generation quality tests, Python template negative tests,
full regression and actual D1/D2/D3 preparation/reroll/exploration on DISPLAY1.
