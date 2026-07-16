# 018 Dungeon Combat Modifier Bridge V1

Status: implemented
Date: 2026-07-16

## Intent

Define how dungeon exploration consequences affect tactical combat.

Dungeon hazards, light, and debuffs should be able to influence combat without moving combat legality or outcome rules into dungeon code.

## Ownership

- Dungeon owns light state, supplies, hazard outcomes, and dungeon debuffs.
- Combat owns tactical command legality, hit resolution, status ticking, AI, and victory/defeat.
- The bridge is data passed from dungeon to combat encounter launch.

## Planned Bridge Payload

When dungeon launches combat, it may eventually add:

```json
{
  "dungeon_modifiers": {
    "light_state": "dark",
    "ambush": true,
    "player_modifiers": [
      {"type": "starting_mp_multiplier", "value": 0.5, "source": "limping"}
    ],
    "enemy_modifiers": [
      {"type": "initiative_bonus", "value": 2, "source": "darkness"}
    ],
    "starting_statuses": [
      {"unit_selector": "party_member:front", "status_id": "bleeding", "source": "blade_trap"}
    ]
  }
}
```

Exact fields must be implemented only when combat supports them.

## Initial Modifier Ideas

- `dark` light gives enemies initiative or accuracy bonus;
- `blackout` may force ambush layout;
- `limping` reduces player starting MP;
- `bleeding` applies existing combat bleeding if target mapping is available;
- rubble injury can reduce player HP before battle;
- alarm trap can add enemies or change spawn positions.

## Implementation Timing

Implement after at least one dungeon hazard and one dungeon debuff exist. Do not implement this before there is a clear modifier to pass.

## Implementation Notes

Implemented first-pass launch metadata support in:

```text
scripts/domain/dungeon_state_model.gd
scripts/session/dungeon_run_session.gd
scripts/presentation/combat_debug.gd
```

Dungeon pending combat requests now include `dungeon_modifiers` with:

- `light_state`;
- `light_level`;
- `ambush_risk`;
- `enemy_modifiers`;
- `active_debuffs`;
- `target_effects`;
- `party_effects`.
- `party_formation`.

`DungeonRunSession.apply_launch_metadata` passes this payload into the combat encounter. Combat debug displays a compact summary line, but combat resolver rules are not changed yet.

## Implemented Modifier Effects

First supported launch effects:

- `enemy_modifiers` with `type: initiative_bonus` increase enemy unit `stats.initiative` before combat starts.
- `target_effects.party_slot_front.hp_loss` resolves through `party_formation` and reduces that combat unit's starting HP, clamped above zero for launch safety.
- `target_effects.party_slot_front.debuffs.limping` resolves through `party_formation` and halves that combat unit's starting MP.
- `target_effects.party_slot_front.debuffs.bleeding` resolves through `party_formation` and applies the supported combat `bleeding` status.

`party_member_0` is kept only as backwards-compatible debug metadata and maps to the first player unit.

Unsupported future debuffs stay in `dungeon_modifiers` metadata but do not mutate combat state yet.

## Non-Goals

- combat resolver rewrite;
- undocumented direct mutation of combat state;
- permanent progression effects;
- balance finalization.
