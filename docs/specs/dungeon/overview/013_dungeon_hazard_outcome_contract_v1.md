# 013 Dungeon Hazard Outcome Contract V1

Status: implemented
Date: 2026-07-16

## Intent

Define the future data and event contract for dungeon corridor hazards.

This contract should be implemented before individual hazard types such as light decay, rubble, or traps. It gives every corridor event the same shape: trigger, player option, supply check, deterministic outcome, and state update.

## Core Concept

Corridor traversal can produce a hazard event before the party reaches the destination room.

The player should see what happened, choose or confirm an approach, and then receive a clear result. Some hazards can be safely resolved with the right supply. Without the supply, the party can force progress, retreat, or suffer a negative outcome depending on hazard type.

## Planned Hazard Event Shape

Future hazard result events should include:

- `type`: stable event type, e.g. `corridor_hazard_resolved`;
- `hazard_id`;
- `hazard_type`;
- `corridor_id`;
- `from_room_id`;
- `to_room_id`;
- `required_supply_id`, if any;
- `supply_available`;
- `supply_consumed`, if any;
- `choice_id`;
- `outcome_id`;
- `consequences`;
- `message`;
- optional `combat_modifiers` when the outcome affects a future combat encounter.

## Planned Hazard Data Shape

Future dungeon corridor data may contain:

```json
{
  "hazards": [
    {
      "id": "rubble_crossing_001",
      "type": "rubble",
      "trigger": {"mode": "first_traversal"},
      "required_supply_id": "pickaxe",
      "choices": [
        {"id": "use_supply", "label": "Clear with pickaxe"},
        {"id": "force_passage", "label": "Force passage"}
      ],
      "outcomes": [
        {
          "id": "cleared_safely",
          "when": {"choice_id": "use_supply", "has_supply": true},
          "consume": {"pickaxe_uses": 1}
        },
        {
          "id": "injured_by_rubble",
          "when": {"choice_id": "force_passage"},
          "weight": 35,
          "consequences": [{"type": "apply_debuff", "debuff_id": "bruised"}]
        }
      ]
    }
  ]
}
```

Exact schema details are future work.

## Determinism

- Hazard resolution must be deterministic under test seed.
- Weighted outcomes must be seedable.
- The same input state, hazard id, choice, and seed must produce the same outcome.
- Manual UI can hide seeds, but tests must control them.

## Consequence Types

Planned consequence IDs:

- `consume_supply`;
- `reduce_light`;
- `restore_light`;
- `apply_debuff`;
- `remove_debuff`;
- `hp_loss`;
- `mp_penalty`;
- `stress_gain`;
- `trigger_ambush`;
- `block_corridor`;
- `unlock_corridor`;
- `modify_next_combat`;
- `log_only`.

## Implementation Timing

Implement this before `Light/Oil V1`, `Rubble/Pickaxe V1`, and `Trap Tools V1`. It is the foundation that keeps future hazards from becoming one-off scripts.

## Implementation Notes

Implemented first-pass support in:

```text
scripts/domain/dungeon_state_model.gd
resources/schemas/dungeon.schema.json
resources/data/dungeons/dungeon_old_mine.json
```

The implemented contract supports corridor `hazards`, deterministic weighted outcome selection, structured `consequences`, `hazard_log`, and traversal event payloads returned from `enter_room`.

First-pass corridor hazards are resolved before the target room is entered. `enter_room` returns `choice_required` with a `corridor_hazard_choice_required` payload when the party finds an unresolved corridor hazard. The caller must resolve that prompt through `resolve_corridor_hazard_choice` before traversal continues. This keeps rubble, traps, darkness checks, and similar traversal events between rooms rather than inside room content.

Hazard outcomes now support weighted variants and target stubs. Consequences may include `target_id`, currently using `party_member_0` until the real party roster exists. Runtime state records both party-level totals and per-target `target_effects`.

## Non-Goals

- final balancing;
- UI art;
- procedural hazard generation;
- persistent character roster.
