# A travelling company in a changing political world

Date:2026-11-09. Status: DESIGN COMPLETE; NOT IMPLEMENTED.
The user reprioritized the full strategic-world layer over the isolated contract
pool and chose a language model as faction strategist with a complete classic
mode underneath. Desktop control remains withheld. This document is the product
brief; [world015](../../../specs/world/015_world_strategy.md) owns the proposed
rules, persistence and planner boundary. Prototype values are tuning proposals.

## What the player should experience

The company travels through a world whose powers need food, materials, revenue
and secure routes. They remember agreements, fear stronger neighbours, protect
important places and choose partners for reasons the player can discover.
Ravenford is a familiar starting town, not a mandatory return point after every
adventure. A journey should present changing opportunities: a threatened trade
road, a disputed crossing, an ally seeking provisions, or a ruin whose contents
could change a negotiation.

Dungeon crawling and tactical combat remain the main adventures. Politics
creates reasons to enter them and meaningful consequences afterwards. The
company can profit from a war, help end it, support a faction, or stay neutral.
It does not become the ruler issuing orders to every army.

## Two modes of the same world

| | Classic strategy | AI strategists |
| --- | --- | --- |
| Decision maker | Local utility scoring, faction personalities and small goal plans | A language model proposes faction goals, priorities and conditional plans |
| Is it dynamic? | Yes: decisions respond to actual resources, routes and history | Yes: the model can compose different sequences and responses from the same legal actions |
| What executes the plan? | The shared simulation | The same simulation |
| What decides a war or delivery outcome? | Actual resources, movement, agreements and resolution rules | Exactly the same rules |
| Long-term intent | Configured goals with commitment and replanning | Saved goals and branches over several in-game weeks |
| Offline play | Complete | Classic strategy continues when model decisions are unavailable |
| Repeatability | Seed, configuration and player commands | Recorded accepted decisions as well as the seed and commands |

Classic mode is not a prewritten sequence where war always starts on day10.
AI mode is not a separate ruleset or a narrator declaring imaginary victories.
Changing mode changes the planner, while keeping the current world and history.

The opening geopolitical situation is also a saved campaign premise: trade
dependencies, disputed routes, public agreements and private ambitions. Start
with authored, seed-selected premises. A later AI-authored opening may propose
a new combination under the same geography/resource/fairness constraints, then
freeze it before play. The first classic/AI comparison uses the same premise;
we should not confuse different starting conditions with better decisions.

## First political cast

Keep River League and Iron March. Two additional working identities are proposed
for a new experimental campaign; they do not replace owners in old saves.

| Power | Economic interest | Political character | Reasons to cooperate or fight |
| --- | --- | --- | --- |
| River League | Food, ore deliveries and river-road commerce | Pragmatic, protective of trade | Protect caravans, reopen the mine, resist costly tolls |
| Iron March | Reliable ore, military supplies and the High Pass corridor | Security-minded, assertive | Buy access, seek guarantees, mobilize over a real dispute |
| Cinder Compact — working name | Profitable overland trade and access to markets | Commercial, adaptable | Broker agreements, fund escorts, oppose damaging embargoes |
| Thornwood Accord — working name | Food imports, timber exports and protected woodland sanctuaries | Defensive, wary of expansion | Trade with merchants, defend sacred sites, seek a useful ally |

An eventual four-power region needs actual settlements and reachable economic
links. The current three-settlement/two-faction/four-party pilot cannot gain this
by adding two names. First prove the politics on an isolated six-settlement
fixture, then place the expanded roles on new campaign geography. Preserve all
existing authored and generated maps and their current ownership.

## Three situations worth playing

These are branching design examples, not scheduled story events.

### Ore and the border

1. Mine occupation interrupts ore traffic. The League loses supply and the
   March's reserve runs down.
2. The League can fund a restoration job. The March can negotiate purchases or
   passage. If rejected and militarily ready, it can prepare coercion at the
   contested crossing; the player hears warnings before open conflict.
3. The Compact can offer a trade guarantee. The Accord might support it to keep
   its food corridor open, forming a coalition motivated by trade.
4. The company restores the mine, escorts a shipment, or scouts the crossing.
   Actual ore arrival can remove the reason for escalation. Failure preserves
   the shortage; a model cannot declare the job completed in dialogue.

For this same shortage, a classic policy might first buy an available shipment
and protect its road. A model proposal might bundle that shipment with a
nonaggression offer and a contingent long-term deal after mine restoration.
Both sequences must be executable and affordable; either planner can choose
either sequence when its policy supports it. These are design examples, not
results of a model-connected game or evidence that AI mode is superior.

### A commercial alliance

A trader needs timber and the woodland faction needs grain. They negotiate a
shipment and passage rights. A separate embargo makes that route expensive, so
they may seek League mediation or a defensive pact. An alliance starts only when
both parties accept actual terms. Shared hostility alone is not a signed treaty.
The company sees new escort, supply and route-clearance work. If trade succeeds,
their interests may diverge again after the commitment period.

### A war that can end

Raids and border losses consume real reserves. A faction unable to sustain its
objective should consider a ceasefire, a limited concession or a new supplier.
There are public signals: exhausted patrols, disrupted caravans, expensive food
and changing offers. A successful company expedition can improve bargaining
power; it does not instantly decide an entire war. Peace leaves reconstruction
and exploration work, giving the player reasons to continue outside wartime.

## What the strategic scene needs to show

Keep the approved dark fantasy map, material family and continuous travel.
Add information gradually through existing map overlays and the inspector:

- **Map:** actual parties, owned settlements, contested crossings, trade routes
  and threatened sites. Distinguish a dangerous route from impassable terrain.
- **Faction inspector:** known interests, public agreements, wars, company
  reputation and a short explanation of recent visible decisions.
- **Chronicle:** causal reports, such as "Three ore shipments were lost; the
  March is mobilizing at the pass." Separate confirmed reports from rumours.
- **Contracts:** jobs arising from those needs, with issuer, objective, return
  destination, risk, terms and visible consequences. Accepted terms stay stable.
- **Journey decisions:** provisions, time, route safety and useful places to
  rest; politics must not silently change accepted movement or animation rules.

No separate grand-strategy dashboard is needed for the first playable slice.
Never expose secret model reasoning or implementation details in ordinary play.

## First playable scope and order

| Stage | Deliverable | Proof before promotion |
| --- | --- | --- |
| 92 — current | Product plan, proposed rules, dual-mode protocol and acceptance scenarios | Documentation consistency and repository validation; no runtime claim |
| 93 | Versioned registry for factions/settlements/parties, diplomacy facts and event receipts | Legacy save/terrain preservation; deterministic isolated model |
| 94 | Complete classic four-faction simulation: economic dependencies, plans, trade, war and peace | Long headless campaigns, legal actions, conserved transfers and explainable decisions |
| 95 | Strategic scene and contract consequences on an expanded opt-in region | Native layout/input checks, then ordinary play when desktop controls are released |
| 96 | AI strategist adapter, first with recorded responses, then a configured real model | Same command rules; stale/invalid/repeated/late replies and offline continuation |
| 97 | Matched classic/AI comparisons and balancing | Replay plus measured long-run behaviour and actual player review |

Earlier L91-01/L91-02 and L77-01 acceptance gaps remain open. They must be reviewed
before promoting a replacement as the main campaign. Further implementation is
a separate step after this design; do not infer an authorized runtime rewrite,
network provider activation, expenditure, desktop control or publication.

The original contract-pool work becomes a consequence of world needs. It follows
the strategic foundation instead of manufacturing unrelated daily errands.
Town exploration, full territorial conquest, recruitment expansion, naval travel
and a new tactical ruleset are separate later increments.

## Decisions still needed before real model integration

Provider/local hosting and an explicit request budget are not chosen yet. The
interface is provider-neutral. The first foundation does not need that choice.
Faction names, numeric utility weights, resource rates and strategic pacing need
prototype/play evidence; the architecture and comparison method are specified.

[Research notes](RESEARCH.md) distinguish primary-source observations from our
own design choices. [Planned acceptance](../../../specs/world/slices/016_world_strategy.md)
describes how to reject a world that merely produces colourful text.
