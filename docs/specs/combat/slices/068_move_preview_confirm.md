# 068 Move Preview Confirm

Status: implemented
Date: 2026-07-14

## Purpose

Make movement selection readable before committing the command in the combat sandbox.

The player should not accidentally spend MP by clicking a legal tile once. The first click should show the selected route and cost; the second click on the same destination should execute movement.

## Acceptance

- Selecting `Move` shows legal movement destinations with a softer overlay that does not hide terrain art.
- First click on a legal destination does not mutate combat state.
- First click previews:
  - route tiles;
  - destination tile;
  - MP cost;
  - confirmation text.
- Second click on the same destination executes the move command.
- Clicking a different legal destination replaces the preview.
- Clicking an illegal destination clears the preview and shows the rejection reason.
- Switching action clears the pending movement preview.

## Notes

This only changes presentation/interaction. Combat legality still comes from `CombatResolver`, and the preview is derived by simulating the move command against a clean copy of the current state.

Walk-cycle frame animation is still a separate issue: the current presentation can switch to a walk image while tweening movement, but it does not yet cycle multiple walking frames.
