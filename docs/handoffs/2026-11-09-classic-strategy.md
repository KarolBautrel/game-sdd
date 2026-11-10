# Classic faction simulation, stage94

User explicitly asks to implement the next stage. This implements the classic
simulation backend after foundation93. Desktop remains withheld; no OS input,
visible launch or activation. No commit/push request. Local master583ebc84 with
all earlier85..93 preserved uncommitted.

## Delivered

[Owner world017](../specs/world/017_classic_strategy.md),
[slice018](../specs/world/slices/018_classic_strategy.md),
[QA and final-source evidence](../qa/2026-11-09-classic-strategy.md).

`classic_world_state.gd` owns strict composition/validation, config, ledger,
journeys and deterministic hashing. `classic_world.gd` resolves every explicit /
planner intent through the same authority and handles clock, logistics, economy,
war, battles, aid, peace, observations and bounded archival. `faction_planner.gd`
consumes observations only: scored long plans, local logistics, treaty replies
and conditional war/peace decisions. Seeded premises vary actual starting needs /
relations, never scripted dates for outcomes.

Four factions/six towns use conserved stocks, real cargo/escrow, counterpart
consent, weighted movement, paid/time-bound mobilization, actual casualty / total
manpower reconciliation, direct defensive aid, physical retreats and14day
ceasefires. Economic sources/sinks/losses are explicit. Company inventory and
other factions' private plans/policies do not leak into observations. Plans
have3day commitments, weekly reviews and14day horizons, with recorded scores.

The dedicated session explicitly creates classic campaignv2. It still creates /
loads v1 foundation separately, without conversion. Missing/corrupt/version /
write failures preserve files. A failed week rolls back all decisions, time,
stock, consent, troops and receipts; retry/reload is deterministic. V2 company
hours track world time; its player supplies/wages/expeditions are not wired yet.
Strict JSON schemas, reference fixture export and Python validators are included.

Focused checks and16x180day plus two720day campaigns feed the full headless run;
the QA report records actual final-source results, diagnostic tables and save /
art hashes. Existing live acceptance is unchanged. No paid/network inference.

## Next unfinished stage

95: opt-in native strategic scene and genuine company consequences. Existing
approved Large-region rendering/navigation remains authoritative; the backend's
graph is explicitly abstract and cannot be substituted for terrain-safe movement.
Place the additional settlements/faction roles on a fresh versioned geography,
connect real route/navigation evidence, then native faction inspector/chronicle /
causal contract generation with budget reservation and actual expedition results.
Preserve canonical Old Mine restoration and already accepted/paid old jobs.
No conquest/elimination or player joining abstract clashes is implemented.

96follows with recorded model proposals, bounded adapter and classic fallback;
provider/budget still require configuration before real inference.97compares
matched campaigns and balances them. Do not skip95 to expose an ungrounded model
story. Existing L91/L77/user appearance/motion review remain open. No controls
are released here and the old autonomous two-hour queues remain expired.
