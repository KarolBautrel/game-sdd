# Bounded faction-strategist adapter

Stage96,2026-11-09. Implements the proposal/replay/fallback boundary of world015,
on world017/018. Proof: [slice020](slices/020_model_strategist.md). No live provider
or paid inference is configured. Authored offline fixtures are explicitly labelled
examples, not captured live-model output. Provider/model/budget selection remains
a separate configuration step before network integration.

## Compatibility and authority

Explicit new campaignv4 adds `strategist` to the native v3 envelope; no automatic
conversion/reset. A separate seed/preset slot and StrategistWorld opt-in scene
retain the same company/terrain/dungeon rules. V1/v2/v3 dispatch stays unchanged.
Model commands share the successful regional request sequence and atomic writer.
Classic optional host hooks receive copied observations, not mutation authority.
No model field can assign stock, sign another faction's consent, teleport parties,
change geography or complete company/dungeon objectives.

## Protocol and candidates

Versioned requests contain policy version, monotonic request number/ID, faction,
mode generation, observation tick/hash, fixed apply deadline and review/horizon.
One bounded snapshot per faction excludes other private policies/plans and company
inventory. Bound relations16, forces8, markets12, offers8each and reports16.
Capabilities are finite goal and intent catalogues derived from that observation.
Goals: hold/commerce, actual reserve deficits, observed war defence/peace and an
observed lawful claim. Intents come from the same classic capabilities/operators;
models select IDs, never arbitrary payloads. Hash includes capabilities too.

Stage97a [world021](021_strategy_readiness.md) includes transient own-force
preparation quotes in new observations and filters unaffordable preparations.
Old stored observations/capabilities remain valid and are never rewritten.

Strict replies echo the complete context, choose one known goal, at most3distinct
intent IDs, at most2supporting preferences and2contingencies, short allowed reason
codes, up to4observed event citations and a public summary of at most180characters.
Contingencies use only `food_below_target`, `at_war`, `trade_offer_waiting` and a
known intent ID. Unknown fields/IDs/versions, invented events, invalid counts,
duplicate choices and replies over16KiB reject. Request snapshots cap32KiB.
Never execute response text, scene paths or resource JSON. Explanations are not
world facts; public chronicle remains committed simulation events only.

First increment uses the supported classic3day commitment,7day review and14day
horizon, not arbitrary model timing. Plan scores for a model selection are zero
and provenance belongs to the adapter journal, not invented utility evidence.

## Scheduling and failure

Classic mode is the default. Recorded-example mode staggers initial faction
reviews by168ticks, then672ticks per faction. One pending request per faction;
material invalidation may request once per faction/day after commitment. A reply
can queue asynchronously; effects occur only on its fixed24tick planning boundary
at least24ticks after observation. Menus/network latency never advance time.
At that boundary, recheck generation/deadline, public diplomatic context and goal
availability. Operators recheck actual resources, readiness, paths and consent.
Known candidate IDs cannot bypass a newly closed route or spend a budget twice.

Missing/late/interrupted/timeout/malformed/stale/over-budget replies choose a
fresh classic plan. Classic logistics continues while waiting. Coalesce pending
work; never catch up missed weeks with a request storm. Mode changes increment
generation, cancel pending requests and retain sequence watermarks. New modes do
not override a still-committed plan before its commitment expires.

Recorded transport caps4dispatches/real minute,8/world day,65536reserved token
units/day,512reply token units and10seconds per dispatched request. Token units
are a documented conservative UTF-8-size estimate, not a provider invoice.
Offline fixtures cost zero; no claim of real-provider cost enforcement. Requests
reserve estimated units and persist dispatch before transport. Failed save means
no dispatch; failed reply-save retries cached bytes without another dispatch.
Runtime tickets bind a session epoch plus generation/request; abandoned/cancelled
callbacks cannot write another profile. Reload preserves queued replies, treats
unrecoverable sent work as interrupted, and never resends a paid request silently.

## Persistence and replay

Adapter journal retains64completed requests with reply/provenance and actual
operator outcomes. Monotonic global request IDs and per-faction completion
watermarks survive pruning; duplicates never apply again. Outstanding requests
retain full snapshots; canonical world obligations remain under world017/018.
The entire candidate, adapter records, plans, time, company consequences and
receipts publish only after one atomic successful save. Failed writes roll back
all of them. No live HTTP/API keys are stored in saves or public fixtures.

Replay accepts an explicit v4 checkpoint and ordered subsequent regional command
stream, including recorded replies/faults. It calls no transport and reproduces
the resulting state exactly. A seed or pruned journal alone does not promise
replay from campaign start; only checkpoint-plus-tail replay is offered.

Native entry/status are owned by presentation046. Physical review remains
deferred while desktop controls are withheld. Stage97 comparison/balance follows.
