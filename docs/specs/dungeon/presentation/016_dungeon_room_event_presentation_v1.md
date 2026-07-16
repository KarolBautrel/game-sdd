# Dungeon Room Event Presentation V1

Status: implemented
Owner: dungeon presentation

## Purpose

The debug dungeon scene must present room events as explicit player decisions, not invisible automatic outcomes.

## Rules

- When a run state has `pending_room_event`, the debug scene shows a modal event panel.
- The panel shows the room name, event type, message, and available choices.
- Resolving a room event hides the panel, refreshes the HUD, and writes concise feedback.
- Room exits and other actions remain hidden or disabled while a room event is pending.
- Room event presentation may reuse the corridor event panel styling, but the copy must identify that this is a room event rather than a corridor obstacle.

## Proof

- `scripts/presentation/dungeon_exploration_hud_tests.gd`
