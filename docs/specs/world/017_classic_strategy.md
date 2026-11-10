# Classic strategic simulation v1

Stage94,2026-11-09. Implements the isolated classic part of world015, on the
world016 foundation. Proof: [slice018](slices/018_classic_strategy.md).
Native geography/scene/company consequences remain stage95; model planning96.

Stage96 extension: world019 supplies an optional host-only planner callback.
Review receives same-boundary copied observations; intent overrides and actual
operator outcomes use the same seeded order/legality/accounting. Overrides cannot
break the existing commitment. No callback is accepted from command JSON. The
default omitted callback preserves standalone classic behavior and all v1/v2/v3
files. The v4 composition owns adapter persistence and bounded reply lifecycle.

## Version, authority and isolation

`sdd.classic-world`v1 wraps the existing authoritative `core` strategy-worldv1
registries. Core owns stocks, manpower, party headcounts and canonical peace/war
and pact facts; extension registries own logistics, policies/plans, directional
trust/grievance, war metadata, ceasefire offers, aid requests and accounting.
There are no duplicate treasuries or alternative diplomatic stances.
The dedicated session explicitly creates a fresh strategy-campaignv2. Its v1
creation/load remains unchanged; no implicit conversion. Both formats use the
same restricted QA filenames and atomic publication. No autoload/default switch.

Outer versioned commands use monotonic successful sequences and64receipts,
including clock advances. The core's existing sequence covers its six primitive
commands only; the outer sequence is the classic replay authority. Unknown
actors/actions/fields, stale sequences, invalid references and unsupported
versions reject without changes. All planner actions use the same operator
gate as explicit commands; a decision is not an applied effect.

## Clock, phase order and reproducibility

96ticks/day,15minutes/tick. Advance1..672ticks explicitly; no wall-clock catchup.
Movement advances each tick, logistics/replies every24ticks, production/upkeep
daily. First review at tick0; then weekly, or on a war/peace invalidation
after a three-day commitment. Plans have a14day horizon and record goal, target, scores,
reason, selected tick, commitment/review ticks and up to two supporting goals.
All observations at a decision boundary use the same post-economy snapshot;
operators then recheck in a seeded rotating faction order. No global combat RNG,
frame timing or dictionary insertion order participates in decisions.

Tick phases: move parties/shipments; resolve local clashes; daily production /
upkeep and exhaustion; review plans and gather replies/intents from a shared
snapshot; validate/execute intents; archive closed records and append receipts.
The whole requested advance is one durable transaction. Failure rolls back time,
stock, cargo/escrow, decisions, consent, armies, accounting and receipts together.
World018 may supply a native host-only per-tick callback inside that transaction
to settle company travel/economy. It is never a command JSON field, and the parent
owns final company/world validation and publication. Default v2 has no callback.

The isolated company's hour counter follows this clock; company supplies,
wages, movement and expedition consequences retain their stage95 integration
boundary. This stage simulates factions, not a second player loop.

## Economy and actual logistics

Configuration defines faction production, consumption, target reserves,
personalities/homes, claims, prices and three seed-selected opening premises.
Strategic stock units remain distinct from company supplies. Production is an
explicit source, actual upkeep an explicit sink; warehouse cap1000per resource
counts only actual production. Food upkeep includes committed troops. Consumption
cannot spend foundation reservations. No passive manpower creation. Persist
opening total manpower; current total plus cumulative casualties must match it.

Trade offers have immutable seller/buyer/resource/quantity/price/source/target,
one proposer's signature and one-day validity. Only the counterpart may accept
or reject. Acceptance rechecks quantities, money and a route, removes seller
cargo and buyer coin into a real persisted shipment/escrow. Arrival transfers
cargo/payment once. A proposal does not move goods. At most32live shipments and
two pending proposals per proposer prevent unbounded orders.

Use shortest weighted paths on the explicitly abstract fixture graph. Civilian
access excludes settlements owned by enemies of either trading party. This is
not a terrain adapter; no claim of river-safe paths on the approved map. An
already traversed edge finishes before replanning; blocked shipments wait at
their actual node with cargo/escrow intact. Peace allows resumption. An actual
hostile supplied force at a shipment's actual node can intercept: cargo is destroyed and
recorded as loss, escrow refunded, exactly once. The originator never intercepts
its own shipment. A ready supplied escort from
either trading faction, itself at war with the interceptor and at the same
node, prevents seizure when its total headcount matches/exceeds all ready
hostile interceptors there. The actual armies still resolve their clash. Weak,
unsupplied, training or absent guards cannot grant protection. No arbitrary
daily convoy loss.

Per-resource opening+production-consumption-loss must equal holdings+in-transit
cargo+escrow at every accepted boundary. Gold trade transfers conserve money.
No job rewards or company inventories participate in this experimental ledger.

## War, peace and pacts

Mobilization spends coin/food/ore, commits only existing free manpower to an
existing party (cap12), and takes24ticks before marching. Parties follow weighted
routes from actual positions. Readiness requires real troops, supplies and a
reachable contested corridor. Declare war requires an authored border claim or
a recorded sufficiently serious grievance. Active nonaggression/defensive pacts
and ceasefires block declaration; this slice has no pact-breaking shortcut.
Public warning is the mobilization event before a claim war. No global tension
clock forces a conflict. No settlement conquest or elimination in this slice.

Stage97a: [world021](021_strategy_readiness.md) exposes transient own-force
quotes from the same operator price helper. New classic/model preparation
proposals require actual affordable staffing; failed preparations can continue
ordinary supply procurement. Execution still rechecks current conditions.

Stages97b/c: [world022](022_supply_pipeline.md) adds lead-time procurement quotes,
overlapping real cargo and shared observed order/consent capacity budgets.
[World023](023_diplomatic_proposals.md) filters live known negotiations/expired
responses and closes overdue peace records in the existing archive phase.
Actual prices, signatures, conservation and explicit-command gates remain.

Opposing ready parties at one node or crossing on the same edge resolve bounded
seeded clashes using actual
headcount, faction food and a declared defender bonus, with explicit casualties
deducted from both party and total faction manpower. Losers physically withdraw
to a friendly node; a one-town force instead recovers locally before rejoining.
An edge clash leaves both positions/progress on the actual edge; the loser
finishes it before replanning its withdrawal. No teleportation or tactical-player
combat result is fabricated.

War adds exhaustion from time, shortages and casualties. After seven days or
material exhaustion/shortage, a faction can propose a ceasefire. Only the other
party may accept identical terms. Acceptance sets symmetric peace and a14day
ceasefire, retains two signatures, and orders surviving forces home along actual
routes. It does not erase losses, rewind stock or settle shipments instantly.

Nonaggression/defensive pacts reuse core bilateral consent. Commercial history
and common threats can motivate them. An attacked faction's direct defensive
allies receive one aid request per war. An ally can join only with lawful pacts,
routes, forces and resources, otherwise decline at a recorded trust cost.
Aid does not recursively summon allies or make alliances transitive.

## Observations, plans, records and limits

An observation exposes own economy, commitments and policy, public ownership /
war/treaties, bounded public market quotes, incoming offers/aid and up to16own /
public confirmed reports with event IDs, timestamp, age and confidence100.
It never contains other factions' private plans/policies or company inventory.
Classic goals: secure supplies, earn trade income, guard/rebuild, enforce a
claim, defend/aid or seek peace. Economic benefit, security, claim/readiness,
cost and switching components are recorded; deterministic seed tie-breaking.
Hold/rebuild is always valid. Replies and execution consider current reserves,
price, trust, actual readiness and existing commitments. Friendly trade raises
trust; war/interception and refused aid cause recorded directional grievances.

Keep128recent causal events,64outer receipts and16recent decisions per faction,
plus cumulative accounting/diagnostics and monotonic entity/event watermarks.
Archive only closed trades/offers/aid and expired pacts not referenced by retained
receipts or current ceasefires. Never discard cargo, escrow, pending consent,
active pact, open reservation or current war. Generated entity IDs must match
the next durable entity sequence, so archived IDs cannot be reused.

All tuning belongs to the saved validated configuration snapshot. Seed chooses
an opening premise and tie outcomes, not scripted dates for wars. Long-run
diagnostics record trade/losses, wars/peace, casualties, plan reviews/churn and
rejected revalidations; they do not prove balance/fun or ordinary play acceptance.
