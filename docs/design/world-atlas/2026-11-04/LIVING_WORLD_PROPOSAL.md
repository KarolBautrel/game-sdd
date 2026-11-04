# Living mercenary world — discussion proposal

Date:2026-11-04. Status: AUTHORIZED; FIRST LIVING-REGION PILOT IMPLEMENTED.
Follow-up: the user now authorizes proceeding. Stage77/world010/presentation036
implements the first small living-region pilot; its QA/handoff record exact
scope and results. Seeded geography and broader content below remain later work.
The user's requested vision is recorded below; proposed mechanics and prototype
numbers remain recommendations. Existing world009/presentation035 still own
the playable atlas until a new approved implementation stage supersedes them.

## User direction

Keep the current beautiful map/UI appearance and preserve its sources. The game
should support a travelling mercenary company, many contracts, relationships
with factions and conflicts between those factions. Battle Brothers and Mount
& Blade are the main world-layer inspirations. Dungeon crawling remains the
principal adventure layer, using this game's own tactical combat.

The current four-province/twenty-destination atlas proves presentation and travel;
its geography/route model alone does not supply long-term campaign play.

## Recommended campaign structure

Generate coherent geography once when starting a campaign, store the seed and
generator version, and persist the evolving world. Regions retain identity;
towns/roads/landmarks, ownership and threats may vary between campaigns. Validate
connected settlements, accessible early opportunities and meaningful travel times.
Revisiting a place preserves its history, depletion and occupants until a world
event logically changes them.

Use a continuous strategic map: click to travel, visible company motion,
roads/off-road terrain costs, pause and speed controls. Caravans, patrols and
raiders move with goals. Reconnaissance, pursuit, avoidance and camping create
travel decisions. Inventory and tactical deliberation pause time. Campaign time
inside dungeons advances through actions and rest, not the player's thinking
time. Show consequential off-screen events through clear reports/rumours.

Preserve the approved art direction through modular painted terrain, roads and
landmark assets composed from actual world data. The current complete PNG maps
remain approved references and archival samples. Dynamic geography requires
separate geometry and presentation, rather than repositioning labels over an
unrelated fixed illustration. Do not reduce the visual target to debug tiles.

Ravenford starts as a familiar settlement and optional home. A mobile company
can provision, recruit and recover in other appropriate towns and maintain a
camp. Returning to one mandatory hub after every expedition would constrain
the requested travelling-company campaign.

## World causes contracts; dungeon results affect the world

Use bounded simulation state: settlement security/supply, faction relations,
resources/strength and a few explicit goals. Distant activity can use coarse
time steps; visible parties represent relevant nearby activity. Begin with a
small comprehensible model before scaling faction counts and economies.

Example: raiders occupy a mine -> ore deliveries fall -> a settlement offers a
contract -> the company enters the mine -> rescuing workers/restoring the mine
improves supply/security. Leaving the raiders alive preserves that threat.
A rival faction can offer a conflicting objective, giving the same expedition
different consequences. World changes must be signalled to the player.

Mission variety should change decisions: rescue, recovery, reconnaissance,
sabotage and stopping a ritual, with authored narrative/context modules. Combine
these with generated dungeon structure, inhabitants, hazards, urgency and
company condition. Avoid relying only on reshuffled room order or inflated stats.
Cleared sites have persistent outcomes; reoccupation requires a world cause.

Long-term motivation comes from company development, scarce provisions/time,
equipment specialisation, relationships, consequences, discoveries and larger
regional crises. Campaign goals should offer meaningful milestones/endings.
Procedural combinations alone cannot guarantee retention or unlimited variety.

## Recommended implementation order

1. Agree the campaign pillars and durable rules for time, movement, faction
   activity, persistent locations, contract creation and dungeon consequences.
2. Prove a small living region: three settlements, two political factions, a
   bandit camp, caravan/patrol activity and several dungeon objectives. Existing
   authored geography can serve as the testbed. Demonstrate that a threat creates
   a contract and completing its dungeon changes the actual world state.
3. Add seeded geography and the modular illustrated renderer, preserving the
   visual baseline; expand after the small loop survives actual play review.
4. Broaden faction conflicts, contract families, discoveries and crises based on
   playtest evidence of repeated decisions, rather than a target marker count.

## Reference research

These are design references, not claims that all historical announced features
are implemented identically in their current games.

- Battle Brothers official feature overview: procedural mercenary campaign,
  free strategic travel, company development, events and late-game crises.
  https://battlebrothersgame.com/features/
- Battle Brothers dev blog95: actual settlement situations affect contracts,
  prices/recruits/supply; player actions resolve or cause situations.
  https://battlebrothersgame.com/dev-blog-95-contract-changes/
- Mount & Blade II official publisher description: medieval sandbox with
  diplomacy, trade and territorial conflict.
  https://store.steampowered.com/app/261550/Mount__Blade_II_Bannerlord/
- Darkest Dungeon official developer description: expedition pressure, flawed
  heroes, injuries/stress, town recovery and procedural dungeons.
  https://store.steampowered.com/app/262060/Darkest_Dungeon/
