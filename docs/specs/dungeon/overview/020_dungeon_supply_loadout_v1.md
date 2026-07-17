# 020 Dungeon Supply Loadout V1

Status: implemented
Date: 2026-07-16

## Intent

Add an explicit expedition supply loadout before a dungeon run starts.

Dungeon traversal already has light pressure, pickaxe rubble, trap tools, and persistent negative effects. The player should choose starting supplies before entering the dungeon instead of every run silently using fixed `starting_supplies`.

## Loadout Contract

Dungeon data may define `supply_loadout_options`:

```json
{
  "lamp_oil": { "min": 0, "max": 4, "default": 2 },
  "pickaxe": { "min": 0, "max": 2, "default": 1 },
  "trap_tools": { "min": 0, "max": 3, "default": 1 }
}
```

If options are missing, the debug flow falls back to `starting_supplies`.

When a run starts, dungeon state stores:

- `supplies`: the selected loadout counts;
- `selected_supply_loadout`: a duplicate of the chosen loadout for debugging and post-run inspection.

## Presentation Rules

The debug dungeon scene may show a lightweight preparation panel before the run starts:

- show each configured supply;
- allow increment/decrement within min/max;
- start the expedition with the chosen loadout;
- block room traversal until the expedition is started.

This is a functional debug/pre-production loadout, not final inventory UI.

## Implementation Notes

Implemented first-pass support in:

```text
resources/schemas/dungeon.schema.json
resources/data/dungeons/dungeon_old_mine.json
scripts/domain/dungeon_state_model.gd
scripts/presentation/dungeon_debug.gd
```

## Future Work

- Connect supply choices to persistent inventory availability from town/world systems.
- Add carry limits or expedition packing points that control how much of the available inventory can be brought inside.
- Add party/character loadout on the same preparation screen.
- Replace debug steppers with the future polished dungeon preparation UI.

## Non-Goals

- economy/cost balancing;
- supply buying, pricing, or restocking;
- permanent inventory ownership;
- final UI art;
- world-map or town acquisition flow.
