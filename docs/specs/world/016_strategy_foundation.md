# Strategy-world foundation v1

Date:2026-11-09. Stage93, authorized by the user's implementation continuation.
Owner for the implemented foundation below; world015 retains the broader plan.
Acceptance: [slice017](slices/017_strategy_foundation.md).

## Scope and isolation

Provide a pure versioned world model and dedicated atomic session, with a
four-faction/six-settlement reference fixture. This is a headless experimental
foundation, not the replacement main scene, a political AI or live model adapter.
No clock, production, convoy movement, military combat, wars or contract rewards
are simulated yet. Existing living/atlas campaigns and art keep their owners.

Use a standalone `sdd.strategy-campaign` version1 envelope containing a valid
v4 company snapshot and `sdd.strategy-world` version1 state. Prototype company
starts with80gold/16food and existing starter gear, independently of faction
stockpiles. The company snapshot has no living block, pending event or active
run. Company seed matches the world seed and its elapsed hours equal the integer
floor of strategic ticks/4; queries and loads never advance either clock.
Its legacy atlas location stays valid; the strategy session stores its
own current settlement ID. No new dynamic ID enters the legacy atlas validator.

The dedicated session creates/persists only single-file paths matching
`user://qa_strategy_world_[A-Za-z0-9_-]+.json` or explicit memory instances.
Directory traversal, subdirectories and other extensions reject. Creation refuses
an existing file or directory. Loading missing,
corrupt, legacy or unsupported data never creates/resets/writes a file. The
legacy CampaignSession explicitly rejects the reserved strategy prefix and
strategy envelope. Neither loader converts a profile implicitly. No new autoload
or visible launcher is introduced at this backend stage.

## State and reference data

Persist schema, state/simulation/content versions, scenario ID, seed1..1e9,
tick, command sequence and current planner mode `classic`. Other planner modes
remain unsupported until their real adapter exists. Store keyed registries for
factions, settlements, routes and parties, company reputation, canonical
diplomatic pairs, pact offers, budget reservations and bounded recent receipts.
No behaviour depends on dictionary insertion order or fixed actor positions.

The fixture graph is explicitly `abstract_fixture`: coordinates and positive
travel-tick weights are diagnostic anchors, not proof of actual terrain-safe
routes or a newly rendered map. All nodes must form a connected graph, references
must exist and route endpoints differ. Existing immutable geography is untouched.
Later movement needs its real terrain adapter before player-facing promotion.

Faction stores use nonnegative integer `coin`, `food`, `ore`, `timber` units plus
total manpower. Food/material units here are strategic stock units, not directly
interchangeable with the company's expedition supplies. A party is anchored at
a known settlement, belongs to a faction and commits headcount from its total
manpower; sum of party headcounts cannot exceed that total. This stage does not
create recruitment or additional troops through those bookkeeping fields.

Exactly one diplomatic pair exists per unordered faction pair. Its stable key is
the two sorted IDs joined by `~`, with ordered endpoints and `peace`/`war` stance.
The fixture starts at peace; the command API cannot declare war before stage94
defines its prerequisites. Company reputation is a separate-100..100 registry,
not an inter-faction attitude. Unknown references/versions/fields and contradictory
pair/party/reservation/treaty facts fail validation.

## Economic reservations

`reserve_budget` holds a positive amount of an existing faction stock against a
stable reservation ID and bounded purpose text. Available stock is holdings
minus all open reservations. A second goal cannot reserve the same available
resources again. Reservation/release never creates, transports or consumes goods.
Only the owning faction can release an open hold, once. Closed reservation IDs
cannot be reused. Actual payments, transport, escrow settlement and consumption
need their later domain operations; this API cannot teleport a trade shipment.

## Bilateral pacts

`propose_pact` supports nonaggression and defensive pacts with a known different
faction, valid offer window1..7days and duration1..30days (96ticks/day). The
proposer signs its own immutable terms. Same-kind pending/active duplicate pacts
and negotiations while at war reject. Only the recipient can accept/reject;
only the proposer can withdraw a pending offer. Pending offers confer no treaty.

Acceptance records both signatories and the same terms in the single pair
record, in one transaction. Accepted offer and treaty ID/kind/ticks/signatures
must agree on load. Single-sided accepted state, a pact contradicting war, a
duplicate response or an expired offer rejects. Treaty/offer records survive
reload. Time advancement/automatic expiry and wartime breach behaviour are
future stage94 operations, not hidden transitions on load or query.

## Commands, receipts and persistence

Commands contain only id, sequence, actor_id, action and an exact action payload.
Next successful sequence is current+1; ID is `order_%08d` for that sequence.
Rejected commands do not advance it. Duplicate/older/out-of-order commands reject
without changing state. Authorized command APIs cover reserve/release budget,
propose/accept/reject/withdraw pact only. Unknown operations/fields reject.

Pure execution works on a deep copy, revalidates the candidate and publishes
only accepted states. Keep the latest64contiguous successful receipts, each
with ID/sequence/actor/action/target/tick. The durable sequence watermark rejects
old replay even after its receipt scrolls out. Canonical obligations are not
discarded with the receipt tail. Conservative registry bounds protect this
foundation; later long-running simulation must define archival before promotion.

The session validates the company/world envelope, writes an owned sibling .tmp,
flushes/closes and atomically renames before replacing its in-memory snapshot.
Failure preserves memory and existing file bytes, including reservations, pact
consent and command sequence. Load alone preserves exact bytes and performs no
world catch-up or migration. No player data, art or existing pilot file is used
as a mutation fixture. Stages94..97 remain separate unfinished work.
