# Autonomous world life: product plan

2026-11-10, stage98, DESIGN ONLY. User reprioritization: simplify economic detail
and design how the whole world lives without company intervention. Owner:
[world024](../../../specs/world/024_autonomous_world_life.md). This replaces the
earlier next-step priority of selecting a live model. Existing97b/c work remains
preserved; this document changes no gameplay, profile, map or provider.

## The experience

The company is one participant in a world with its own interests. Powers pursue
ambitions; patrols, rival adventurers and threats act; places change; opportunities
appear and close. Returning to a province should reveal understandable results
of what happened elsewhere. Locations do not wait for the player to click them.

This remains a mobile mercenary tactical RPG whose important adventures lead
into dungeon exploration and tactical encounters. Ravenford is an opening hub,
not a mandatory permanent base. World life gives reasons to travel, choose a
patron and enter dangerous places. The player does not manage a grand-strategy
faction, taxes or every shipment.

The approved painted dark fantasy map, Ashen interface and character direction
remain. The initial prototype uses the actual existing region/four powers; its
six towns/nine bound sites are not already a complete multi-province simulation.

## 1. Who acts without the company

| Actor | Purpose | Autonomous actions |
| --- | --- | --- |
| Major factions | Security, influence, expansion or protecting a tradition | Negotiate, scout, send patrols, suppress threats, pressure neighbours, launch limited campaigns |
| Towns and garrisons | Safety and recovery | Request help, repair, fund work, receive refugees and reinforcements |
| Rival companies/adventurers | Payment, reputation and survival | Take work, attempt supported adventures, succeed, retreat or suffer losses |
| Bandits | Gain and survival | Establish a viable camp, raid, avoid stronger patrols, move or split |
| Monsters/cults | Control or spreading a specific threat | Expand from real lairs, corrupt a nearby place, raid or lose ground |
| Civilian parties | Reach useful destinations | Trade, carry news, flee danger or resume an open route |

Actors retain identities, a home/source, a goal, limited means and a task. They
are not disposable icons spawned around the company. Defeat changes strength or
removes the party; replacement needs a source, recovery time and budget. Detailed
daily routines for every resident are unnecessary.

## 2. Distinct ambitions

Keep existing faction identities. These are proposed future behaviours, not
claims that all the required operators exist:

- River League protects settlements and passage. It prefers reopening a road,
  rescuing an expedition or hiring help to an expensive territorial war.
- Iron March seeks defensible borders and influence. It may demand access,
  reinforce a pass, exploit weakness or abandon an expensive front.
- Cinder Compact pursues access and leverage. It may broker a pact, hire a rival
  company, support a safer patron or change partners after losses.
- Thornwood Accord protects woodland and sacred places. It may contain a threat,
  resist occupation or accept a useful defensive agreement.

Each power keeps one main ambition and one secondary concern. A strategy lasts
days or weeks and has milestones. Losses, threats or failed agreements can change
it. Personality affects decisions; no calendar forces a war and no faction knows
the company's hidden inventory or scales itself invisibly to its level.

## 3. A modest economic support model

World decisions need four broad assessments:

| Assessment | Question |
| --- | --- |
| Means | Can this power afford another commitment? |
| Military readiness | Which forces can it send and replace? |
| Stability | Can its towns and occupied places withstand more pressure? |
| Supply condition | Is it well supplied, strained or in shortage? |

Town profiles such as commercial, fortified or exposed explain strengths and
needs. A disrupted road worsens supply/security; recovery improves them. We do
not need every profession, recipe, tax or price fluctuation to support decisions.

Exact owned company equipment, money, provisions, contract payments, signatures
and tactical outcomes retain their authorities. Current faction stocks/ledger
can remain internal means checks while world life is built. Stop deepening that
subsystem as the next product goal. A later truly simpler backend needs explicit
versioned rules; abstract labels cannot mint money, pay twice or convert old
stockpiles silently.

## 4. Developing situations drive the world

Use a persistent episode with a cause, actors, target and consequences:

**Pressure -> warning -> commitment -> action -> resolution -> aftermath.**

Episodes own progress. Jobs, reports, map activity and encounters reference the
same facts, rather than running contradictory parallel stories. They branch,
fail or end through NPC actions without waiting for a player quest flag.

| Family | Cause | Progression | Lasting result |
| --- | --- | --- | --- |
| Threatened road | A viable camp/party reaches a corridor | Scout, patron response, patrol/hired expedition, retreat or reinforcement | Camp removed/moved or route remains dangerous; guards and jobs change |
| Border dispute | A claim, incident or contested passage | Demand, negotiation, warning, mobilization, fighting and settlement | Changed access/garrison/control, damaged relations and recovery |
| Dangerous site | A supported lair/cult becomes active | Reports, spreading pressure, investigation, expedition or containment | Threat suppressed, displaced or strengthened; adventure conditions change |
| Recovery | A raid, siege or failed expedition leaves damage | Relief, repairs, returning parties and reopened access | Gradual recovery or an unresolved weakness and new needs |

Economics is one cause, not the universal explanation. Include political
ambitions, rival expeditions and wilderness threats. Peace supports exploration,
recovery, rivalry and protection work as well as trade.

## 5. Bounded political campaigns

A faction wants a result: passage, protection, a defended outpost or removal of
a threat. Declaring war is not that result. Preparation creates warnings; forces
travel from real positions; garrisons/allies can react. NPC clashes use a bounded
rules-based resolver, never a text model's choice of winner.

Start with corridor safety/outposts, then add supported occupation and border
changes. Holding a new place commits forces. Attrition, overextension, truces and
competing needs limit further campaigns without invisible balancing armies or
forcing every faction into permanent war.

## 6. Rivals can succeed while the player is elsewhere

NPC companies can take ordinary work and attempt supported adventures. They may
clear a camp, fail, rescue survivors, weaken a threat or return with news. Ordinary
threats are not reserved forever for the player. Reasons to intervene include
better terms, a preferred patron, a rare reward, urgency or a desired outcome.

Accepted contracts retain their published terms. Races, deadlines, exclusivity
windows and alternative completion must be explicit up front, not imposed later.
NPC success must not erase an earned payment. Current permanent Old Mine
restoration stays permanent. Later reoccupation elsewhere needs an arriving
actor/new cause and new episode, not a hidden daily reset.

NPCs have limited reach, competence and commitments. Consequences create new
opportunities. They should neither magically complete every dungeon nor freeze
all accepted targets until the company arrives. A site's layout/history stays
stable within its episode; new inhabitants do not erase earlier results.

## 7. One clock and whole-world progress

Autonomous means independent of company actions during game time. It does not
mean a service running while the application is closed. Preserve pause/menu and
dungeon-time rules; model latency never advances strategic time.

Move visible parties through current terrain-safe navigation. Daily updates
advance needs/episodes; periodic faction reviews choose commitments. Later distant
provinces use coarse summaries, with persisted actors/history materialized at a
valid place/time when needed. Entering a region cannot reroll its past, duplicate
a force or resolve an episode twice. A larger global world needs real province
connections and supported destinations, not just extra screen area or markers.

News has a source, age and location. Settlements, travellers, scouts and direct
observation deliver relevant reports. Rumours can be outdated; confirmed facts
and private faction intentions remain distinct. No omniscient storyteller invents
an invasion/outcome solely to manufacture a dramatic arc.

## 8. A concrete hands-off chain

1. A bandit group establishes a valid eastern-road camp and starts raiding.
2. Reports reach a town. The League investigates and posts finite work; the
   Compact chooses a safer route or hires a rival company.
3. The rival reaches the camp and succeeds, retreats or fails, spending actual
   committed strength and changing the episode.
4. If danger remains, a later patrol/reinforcement may respond. A border crisis
   can divert that patrol, allowing the camp to grow instead.
5. The company returns to a safer road, stronger camp or recovery work. Map and
   notices reflect that actual outcome. The company could intervene along the
   way, but was not required for the sequence to progress.

This complete chain is the next prototype, ahead of more economic coefficients
or choosing an API provider immediately.

## 9. What the player notices

Use moving parties, changed danger/control, a few consequential reports and
relevant jobs. Existing map/inspector/faction/chronicle surfaces come before a
new dashboard. Explain what changed, where, who acted and why the company cares.

Stable geography/opening facts plus different decisions/interventions produce
different campaigns. Variety comes from actors, targets, context, aftermath and
supported dungeon families, not hundreds of unrelated random popups. Episodes
retain identities; repeated rewards or new occupation require a new cause.

## 10. Implementation order after this design

| Stage | Smallest complete delivery | Gate |
| --- | --- | --- |
| 99 | One classic threatened-road episode, persistent phases, real patrol/rival response and a genuinely playable small camp encounter | Without company orders it resolves/escalates; reload preserves the result |
| 100 | Shared episode/contract target claims and NPC expedition outcomes | Player/NPC outcomes settle once and accepted terms survive competing actions |
| 101 | Political campaigns, defended outposts, limited control changes, recovery/truces | A conflict has cause, warnings, movement, outcome and aftermath without forced endless war |
| 102 | More supported threat/site families and connected province summaries | Distant state advances once; region entry preserves history/materializes valid actors |
| 103 | Native world feedback and hands-off30/90day reviews across varied openings | Changes are explainable and leave useful company choices; no compulsory war or reset loop |
| 104, optional after local proof | Live model strategy over the same episode/action capabilities | Chosen provider/model/budget, asynchronous fallback, recorded decisions and genuine matched comparison |

Stage99 includes required real content/support; a camp marker opening nothing
cannot close it. Owning rules, schemas/versioned data, executable slices and
meaningful tests precede code. Ordinary gameplay acceptance remains separate.

Decisions now: autonomous world first; complete classic mode; modest economic
detail; preserved existing work/saves; no live provider required for99..103.
Exact limits, timing and assessment thresholds are vertical-slice tuning choices,
not reasons to build another economic subsystem first.
