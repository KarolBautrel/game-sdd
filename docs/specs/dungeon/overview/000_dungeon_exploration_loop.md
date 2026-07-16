# 000 Dungeon Exploration Loop

Status: planned
Date: 2026-07-15

## Intent

Define the target dungeon exploration mode.

Dungeon mode is a separate scene and gameplay phase from tactical combat. It represents an abstract dungeon-crawler exploration layer: the party moves through corridors, reaches room checkpoints, resolves room content, and continues deeper into the dungeon or exits.

The long-term dungeon target is not simple room-to-room hopping. Dungeon traversal should become its own pressure system: the party prepares supplies before entering, spends resources while moving through corridors, and risks negative events when it lacks the right tools.

## Core Loop

1. The party enters a dungeon exploration scene.
2. The dungeon presents connected rooms and corridors.
3. The party advances along a corridor toward an adjacent room checkpoint.
4. Corridor traversal may reduce light, consume supplies, or trigger hazards/events.
5. The party may spend supplies to avoid or soften negative outcomes.
6. Entering a room resolves that room's authored content.
7. Room content may be empty, treasure, combat, treasure guarded by combat, quest content, or a future puzzle/trap/curio.
8. Combat content transitions into the tactical combat scene.
9. After combat, the dungeon receives the combat result and updates room state.
10. Cleared rooms remain cleared.
11. The party continues exploring, retreats, completes the objective, or suffers a defeat consequence.

## Dungeon Shape

- A dungeon is a graph of rooms connected by corridors.
- Rooms are checkpoints and primary content nodes.
- Corridors are traversal links between rooms.
- Corridor traversal should eventually support events, hazards, scouting, hunger, light, supplies, and ambushes.
- Corridors should become meaningful risk spaces. Moving through a corridor may consume expedition resources or test whether the party has the right tools.
- The first implementation may render the graph abstractly instead of using tactical grid movement.

## Expedition Resource Direction

Dungeon exploration should eventually include expedition supplies and pressure mechanics.

Examples:

- Lamp oil keeps the party's light stable. Each corridor traversal may dim the lamp or advance light decay. If the party has oil, it can spend it to restore light. Without oil, darkness may increase ambush chance, stress, scouting failures, or other negative outcomes.
- A pickaxe can clear rubble or collapsed mine passages. Without it, the party may force a passage and suffer HP loss, fatigue, stress, a debuff, time loss, or another cost.
- Bandages, antidotes, rope, rations, and warding supplies may later mitigate specific corridor hazards or room events.

These mechanics are planned, not implemented in the first dungeon foundation. The durable owner for this direction is:

```text
docs/specs/dungeon/overview/012_dungeon_expedition_resources_v1.md
```

## Room Content

Rooms may contain one or more content entries:

- `empty`: no immediate reward or encounter;
- `treasure`: rewards without combat;
- `combat`: enemy encounter trigger;
- `guarded_treasure`: combat followed by reward if victorious;
- `quest`: authored quest state or objective interaction;
- `puzzle`: planned, not implemented in the first version;
- `trap`: planned, not implemented in the first version;
- `curio`: planned, not implemented in the first version.

## Combat Encounter Theme

- Dungeon room content may choose the combat encounter data.
- Combat encounter data may specify a battle map, terrain data, background, and visual theme.
- Combat backgrounds are not limited to the current meadow/grass test scene.
- Future dungeon encounter themes may include cave, crypt, mine, ruins, forest, or dungeon interior combat boards.

## Rewards

- Rewards are authored as data, not hardcoded in the dungeon scene.
- First reward payloads should support XP, gold, and item IDs.
- Reward application may be stubbed until inventory/party progression systems exist.
- Guarded rewards are granted only after a victorious combat result.

## State

Dungeon state tracks at least:

- current room;
- visited rooms;
- cleared rooms;
- resolved room content;
- expedition supplies and light state once implemented;
- corridor hazard/event outcomes once implemented;
- party state summary;
- pending combat request, if transitioning to combat;
- completed objective flags, once quest content exists.

## Non-Goals For First Implementation

- full procedural dungeon generation;
- puzzle implementation;
- trap implementation;
- camping, hunger, light, or stress systems;
- inventory UI;
- final reward balancing;
- replacing the tactical combat scene.
