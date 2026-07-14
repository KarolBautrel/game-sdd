# 035 Debug Sandbox UI Pass

Status: implemented  
Date: 2026-07-14

## Intent

Make the combat debug scene easier to use while combat rules are still evolving.

## Expected Debug Scene Behavior

- command buttons are grouped separately from scenario loading controls;
- scenario tests are selected from one compact picker and loaded with one button;
- event log has enough reserved vertical space to remain visible as the test list grows;
- the event log shows newest events first;
- selecting or clicking a tile updates an inspect panel;
- the inspect panel shows tile position, terrain, occupant, and current action legality;
- tooltips include terrain and rejection reason for the selected action;
- selected tile is visually highlighted separately from legal targets and active unit.
- player and enemy units use temporary pixel-art sprite sheets in the grid;
- movement and attacks briefly switch the unit sprite to a matching test frame;
- pixel-art source generation lives in `assets_src/aseprite/`.

## Non-Goals

- final in-game combat UI;
- final pixel-art assets;
- production animation state machine;
- controller support.
