# Large Horizontal Dungeon Maps V1

Status: implemented
Date: 2026-07-17

## Goal

Let D2 and D3 generated dungeons become physically longer to the right without shrinking the dungeon map into an unreadable single-screen layout.

## Behavior

- `medium_mine` and `deep_mine` generated templates are expected to require horizontal scrolling in the beta debug map.
- D3 generated templates should contain at least three combat rooms in the beta pool.
- The dungeon map presentation keeps readable room cards at the normal room size instead of scaling dense maps down aggressively.
- The visible map frame owns a scrollable map viewport.
- The graph content may exceed the viewport width; horizontal scrolling is the intended way to inspect longer layouts.
- Room and corridor placement remains data-driven through template `position` values.
- Existing authored and short generated dungeons still render inside the same map component.

## Design Notes

For this beta pass, larger dungeons are still curated finite templates. The goal is not free-form procedural layout yet. The important shift is presentation: once the map supports horizontal scrolling, D2 and D3 can be designed as routes that push to the right instead of being constrained by one screen.

## Boundaries

- This does not create bespoke tactical combat boards.
- This does not add minimaps, pan gestures, or production map art.
- This does not change combat resolution, room-event rules, corridor-hazard rules, or run-result payloads.
- D2 and D3 beta map presentation should prefer rightward route depth over downward route depth.

## Proof

- `python tools\validators\validate_all.py`
- `scripts/domain/dungeon_procedural_draft_tests.gd`
- `scripts/presentation/dungeon_exploration_hud_tests.gd`
- headless `DungeonDebug.tscn` load
