# 012 Dungeon Expedition Resources V1

Status: planned
Date: 2026-07-16

## Intent

Define the long-term dungeon exploration resource layer.

Dungeon exploration should become its own gameplay mode, not only a room-to-room selector. The party should prepare for an expedition, spend supplies while moving through dangerous corridors, and risk negative events when it lacks the right tools.

This spec is intentionally planned. It records target design direction before implementation.

## Design Pillars

- Dungeon traversal creates pressure before and between tactical fights.
- The party can reduce or avoid bad outcomes by bringing expedition supplies.
- Supplies are consumed by traversal, hazards, curios, and authored dungeon events.
- Missing supplies should not always hard-block progress, but should create meaningful risk, cost, injury, stress, debuff, or alternate consequences.
- Corridors matter as gameplay space, not only as graph edges between rooms.

## Expedition Supplies

Planned supply examples:

- `lamp_oil`: keeps expedition light stable during corridor traversal;
- `pickaxe`: clears rubble, collapsed passages, and mine obstacles;
- `bandages`: mitigates bleeding/injury events outside combat;
- `antidote`: mitigates poison, venom, or toxic fungus events;
- `rations`: mitigates hunger/exhaustion during longer dungeons;
- `rope`: mitigates pits, climbs, broken bridges, or vertical shafts;
- `holy_water` or similar warding item: mitigates cursed shrines, crypt events, or corruption hazards.

Exact item names and balancing are future work.

## Light Pressure

The dungeon should eventually track a light state.

Target behavior:

- Moving through corridors reduces light or consumes time toward light decay.
- `lamp_oil` can be consumed to restore or stabilize light.
- Lower light increases risk:
  - worse scouting;
  - ambush chance;
  - stress or morale pressure;
  - stronger enemy advantage;
  - worse trap/hazard outcomes;
  - reduced reward safety or increased curio risk.
- Running out of oil should not necessarily stop traversal, but should make pushing deeper dangerous.

## Corridor Hazards

Corridors may contain authored or random hazard checks.

Target examples:

- Rubble blocks the way. If the party has a `pickaxe`, it can clear it safely. Without one, the party may force passage and suffer HP loss, fatigue, stress, time loss, or a debuff.
- Darkness event. If the party spends `lamp_oil`, light is restored. Without oil, light drops and an ambush or stress event may trigger.
- Caved-in support beam. Rope or tools may prevent injury.
- Toxic spores. Antidote or careful traversal may prevent poison.
- Sharp debris. Bandages may prevent bleeding or reduce HP loss.

## Consequence Model

Consequences should be explicit data-driven outcomes where possible.

Planned consequence types:

- reduce party HP or a selected character's HP;
- apply dungeon debuff or future combat status;
- increase stress/fatigue/morale pressure;
- reduce light;
- consume time;
- trigger combat ambush;
- block or reroute a corridor;
- damage or consume supplies;
- alter reward quality or room state.

## Data Direction

Future dungeon data may extend corridors and rooms with fields such as:

```json
{
  "hazards": [
    {
      "id": "collapsed_rubble_001",
      "type": "rubble",
      "required_supply": "pickaxe",
      "on_success": {"consume": {"pickaxe_durability": 1}},
      "on_missing_supply": {"hp_loss": 2, "debuff": "fatigued"}
    }
  ]
}
```

The exact schema is not implemented yet. When implemented, it must be added to `resources/schemas/dungeon.schema.json` and proven by validator coverage.

## Detailed Planned Specs

This file is the umbrella direction. Future implementation details live in:

```text
docs/specs/dungeon/overview/013_dungeon_hazard_outcome_contract_v1.md
docs/specs/dungeon/overview/014_dungeon_light_and_oil_v1.md
docs/specs/dungeon/overview/015_dungeon_rubble_pickaxe_v1.md
docs/specs/dungeon/overview/016_dungeon_trap_tools_v1.md
docs/specs/dungeon/overview/017_dungeon_debuff_table_v1.md
docs/specs/dungeon/overview/018_dungeon_combat_modifier_bridge_v1.md
docs/specs/dungeon/presentation/012_dungeon_event_presentation_v1.md
```

Recommended future implementation order:

1. Hazard outcome contract.
2. Light and oil.
3. Rubble and pickaxe.
4. Debuff table.
5. Trap tools.
6. Event presentation.
7. Combat modifier bridge.

## Relationship To Combat

- Dungeon hazards may affect future combat setup, but combat does not own hazard resolution.
- Dungeon may pass statuses, debuffs, light state, ambush flags, or party resource changes into combat encounters later.
- Combat still owns tactical command legality and combat outcomes.

## Non-Goals For First Implementation

- full supply shop;
- economy balancing;
- procedural hazard generation;
- camping system;
- stress/morale implementation;
- persistent inventory;
- final Darkest-Dungeon-style tuning.

## Future Slice Ideas

- `Dungeon Hazard Outcome Contract V1`: hazards produce deterministic event payloads.
- `Dungeon Light And Oil V1`: corridor traversal reduces light; oil restores it.
- `Dungeon Rubble And Pickaxe V1`: pickaxe prevents negative rubble outcome.
- `Dungeon Trap Tools V1`: trap tools prevent or mitigate trap outcomes.
- `Dungeon Debuff Table V1`: debuffs and percentages are data-driven.
- `Dungeon Event Presentation V1`: hazards are shown as event cards.
- `Dungeon Combat Modifier Bridge V1`: dungeon consequences can affect combat launch.
- `Dungeon Supply Loadout V1`: party enters dungeon with selected supplies.
