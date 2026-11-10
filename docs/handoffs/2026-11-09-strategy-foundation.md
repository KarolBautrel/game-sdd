# Strategy-world foundation, stage93

User's "To lecisz" authorizes implementation of the next foundation increment
after stage92's design. The selected direction remains a language model as
faction strategist over a complete classic baseline. Desktop controls are still
withheld: no OS input, window activation or visible game launch. No new commit /
push instruction. Everything remains local on master583ebc84.

## Implemented

[Owner world016](../specs/world/016_strategy_foundation.md),
[slice017](../specs/world/slices/017_strategy_foundation.md),
[QA and exact-source evidence](../qa/2026-11-09-strategy-foundation.md).

- `world_strategy.gd`: versioned dynamic registries, four-faction/six-town reference
  fixture, all six canonical diplomatic pairs, graph/reference/manpower checks,
  independent company reputation, budget reservations and bilateral pacts.
- Six strict command types. Pure copy/validate/publish resolution; rejected,
  duplicate/out-of-order commands leave all state unchanged. Successful sequence
  watermark rejects old replay even after the64receipt tail is pruned.
- `strategy_campaign_session.gd`: separate version1 strategy envelope containing
  companyv4 plus the new world, atomic QA-only writes and read-only load.
  Missing/legacy/corrupt/unsupported data never resets a file. Both temporary-file
  write and rename failures roll back; retry pays/accepts once. Legacy loader
  explicitly refuses strategy envelopes and reserved paths.
- JSON schema/reference validator in validate_all;252domain checks,93session
  checks and8Python negative/invariant tests. A fifth faction/seventh town use
  the same budget/pact APIs without extra actor slots.

The graph is `abstract_fixture`, not a terrain-routing implementation. The new
session is not an autoload or visible launcher. No clock, production, convoys,
war, military resolution, classic goal planner or LLM/network calls exist in
this increment. Current game still runs its accepted two-faction living pilot.
No player art/map/movement was replaced; no new visual sample is claimed.

## Next work

Stage94 under [world015](../specs/world/015_world_strategy.md): refine owning
rules and executable slices for deterministic time, economy/trade, faction
observations and classic long-term planning, with causal diplomatic decisions
and shared legality. Define real logistics/escrow and archive limits before a
long-run rollout; current reservations only hold stock and never transport it.
Follow with95native scene/contracts/consequences,96recorded model proposals then
configured provider,97comparison/balance. Provider and inference budget remain
unselected; do not activate a paid service or claim an AI demo exists.

Preserve all uncommitted85..93 and old saves/geography/art. Earlier L91-01 /
L91-02, remaining L77-01 and user map/motion/prop acceptance stay open. No controls
are released by this handoff, and the old two-hour autonomous queue remains
expired. The QA report records full checks and read-only preservation results.
