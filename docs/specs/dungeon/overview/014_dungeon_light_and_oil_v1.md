# 014 Dungeon Light And Oil V1

Status: implemented
Date: 2026-07-16

## Intent

Define the first light pressure system for dungeon exploration.

The party carries an oil lamp. Moving through corridors causes the lamp to dim. Lamp oil can restore or stabilize light. Low light makes exploration and combat riskier.

## State Direction

Dungeon state should eventually track:

- `light_level`: integer or enum;
- `max_light_level`;
- `light_state`: e.g. `bright`, `dim`, `dark`, `blackout`;
- `supplies.lamp_oil`;
- `corridor_steps_since_oil`, if needed;
- last light event payload.

## Target Rules

- Each corridor traversal reduces light or advances decay.
- `lamp_oil` can be consumed to restore light.
- Light should not be a hard timer that instantly ends a dungeon.
- Low light increases risk and pressure.
- Extremely low light can trigger ambushes or apply exploration/combat penalties.

## Planned Light Bands

Initial target bands:

- `bright`: no penalty;
- `dim`: minor exploration risk, small scouting penalty;
- `dark`: increased hazard/ambush chance, player-side combat penalty;
- `blackout`: severe risk, likely ambush, major combat penalty or stress/fatigue event.

Exact numbers are future balancing.

## Combat Interaction Direction

Low light may later affect combat by:

- increasing enemy damage, accuracy, initiative, or starting advantage;
- reducing player accuracy, initiative, or available MP;
- increasing ambush layouts;
- adding pre-combat debuffs.

Combat modifiers must be passed through data. Combat itself should not know how dungeon light decays.

## UI Direction

The dungeon HUD should eventually show:

- light state;
- oil count;
- warning when light becomes dangerous;
- action to use oil when available;
- event text when darkness causes an outcome.

## Implementation Timing

Implement after the hazard outcome contract exists. This should probably be the first actual expedition-resource slice because it creates constant pressure without needing many hazard assets.

## Implementation Notes

Implemented first-pass support in:

```text
scripts/domain/dungeon_state_model.gd
scripts/presentation/dungeon_debug.gd
resources/data/dungeons/dungeon_old_mine.json
```

Dungeon run state now tracks `light_level`, `max_light_level`, `light_state`, `supplies.lamp_oil`, and structured `exploration_modifiers`. Corridor traversal applies `light_decay`; `use_lamp_oil` restores light and consumes oil. The debug HUD shows light, oil, and a `Use Oil` action when applicable.

## Non-Goals

- shop/economy for oil;
- final art for the lamp;
- stress system implementation;
- full ambush encounter generation.
