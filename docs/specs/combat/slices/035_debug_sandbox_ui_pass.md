# 035 Debug Sandbox UI Pass

Status: implemented  
Date: 2026-07-14

## Intent

Make the combat debug scene easier to use while combat rules are still evolving.

## Expected Debug Scene Behavior

- command buttons are grouped separately from scenario loading buttons;
- the event log shows newest events first;
- selecting or clicking a tile updates an inspect panel;
- the inspect panel shows tile position, terrain, occupant, and current action legality;
- tooltips include terrain and rejection reason for the selected action;
- selected tile is visually highlighted separately from legal targets and active unit.

## Non-Goals

- final in-game combat UI;
- pixel-art assets;
- animation;
- controller support.
