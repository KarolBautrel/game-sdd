# 012 Dungeon Event Presentation V1

Status: implemented
Date: 2026-07-16

## Intent

Define how future corridor hazards and dungeon events should be shown.

The event layer can use generated 2D or 2.5D bitmap illustrations. It does not need to use pixel art immediately.

## Presentation Shape

Future dungeon event UI should show:

- event title;
- short narrative text;
- optional illustration;
- available choices;
- supply availability;
- projected risk when known;
- resolved outcome text;
- resulting changes to light, supplies, HP, debuffs, or combat modifiers.

## Visual Direction

Event illustrations may be:

- generated 2D painted images;
- generated 2.5D isometric/oblique scenes;
- simple placeholder panels while mechanics are being tested;
- later replaced with consistent production art.

These images should be stored as regular PNG assets. Godot does not need a special AI library at runtime.

## Suggested Production Approach

- Use static generated bitmap illustrations for event cards.
- Keep UI and state logic in Godot.
- Avoid runtime AI generation inside the game.
- Build a small event art prompt/style guide once the event list stabilizes.
- Later, if pixel art direction becomes mandatory, convert or repaint selected event images through the established art pipeline.

## Asset Guidance

Recommended early folders:

```text
assets/dungeon/events/
assets/dungeon/events/placeholders/
assets_src/dungeon/events/
```

Only add these folders when event images are actually created.

## Non-Goals

- selecting a specific AI vendor;
- runtime image generation;
- final art direction;
- animated event cutscenes.

## First-Pass Implementation Note

The first corridor-event presentation is a custom debug event panel in:

```text
scripts/presentation/dungeon_debug.gd
```

When `DungeonStateModel.enter_room` returns `choice_required`, the HUD keeps the party in the current room and shows a corridor event panel before the target room is entered. The panel lists the event title, hazard type, corridor endpoints, event text, required supply availability, and available choices such as `Use pickaxe`, `Use trap tools`, and `Force passage`.
