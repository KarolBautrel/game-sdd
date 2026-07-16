# 015 Dungeon Rubble And Pickaxe V1

Status: implemented
Date: 2026-07-16

## Intent

Define the first obstacle-tool corridor hazard.

Sometimes the party encounters rubble, collapsed stone, or mine debris in a corridor. A pickaxe resolves the obstacle safely. Without it, the party may force passage and risk injury or combat penalties.

## Required Supply

- Supply id: `pickaxe`.
- Future balancing may use durability or uses instead of consuming the whole item.

## Target Flow

1. Party attempts to traverse a corridor.
2. Rubble hazard triggers.
3. If the party has `pickaxe`, UI offers safe clear.
4. If the party lacks `pickaxe`, UI offers risky force passage or retreat.
5. Resolution produces a deterministic hazard outcome event.
6. Traversal either continues, is blocked, or applies consequences.

## No-Pickaxe Outcome Ideas

Possible weighted outcomes:

- safe but slow passage;
- selected character takes HP damage;
- party gains fatigue;
- one character receives `bruised`;
- one character receives `strained_back`;
- next combat starts with reduced player MP;
- corridor remains blocked until tool acquired;
- rubble noise triggers ambush chance.

Exact percentages belong in `017_dungeon_debuff_table_v1.md` or a later balancing table.

## Presentation Direction

The event should read as a clear expedition choice:

- "A collapsed beam and stone pile blocks the corridor."
- "Use pickaxe" if available.
- "Force passage" if not or if player chooses to conserve tool durability.
- "Turn back" if corridor blocking is supported.

## Implementation Timing

Implement after:

1. hazard outcome contract;
2. light/oil baseline, or before it if we want a one-off obstacle prototype.

The safest implementation order is hazard contract -> light/oil -> rubble/pickaxe.

## Implementation Notes

Implemented first-pass support in:

```text
resources/data/dungeons/dungeon_old_mine.json
scripts/domain/dungeon_state_model.gd
scripts/presentation/dungeon_debug.gd
```

`crossing_to_cache` now contains the first rubble hazard. A party with `pickaxe` clears it safely and consumes one pickaxe use. A party without `pickaxe` forces passage and receives structured negative consequences: HP loss and the `bruised` dungeon debuff marker in `party_effects`.

The rubble hazard is a corridor event. It is prompted while moving from `dusty_crossing` to `collapsed_cache`, before the party enters the target room. The player chooses whether to use the pickaxe or force passage; the target room is entered only after that choice is resolved.

## Non-Goals

- destructible map geometry;
- detailed animation;
- permanent injury system;
- procedural cave-in generation.
