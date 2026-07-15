# 076 Combat Sandbox Layout

Status: active
Date: 2026-07-15

## Purpose

The combat sandbox should read like the first version of the real combat screen, not a debug form.

The board is the primary gameplay surface. UI should support tactical decisions without crowding the battlefield.

## Layout

- The combat board should dominate the viewport.
- Player actions live in a bottom pixel-styled skillbar.
- Turn order lives in the top-right corner.
- Immediate action feedback and combat log summary live near the bottom action area.
- Unit resources are shown locally above units.
- Target outcome preview is shown locally on target units while choosing attacks or skills.

## Board Scale

- The current full-combat showcase uses an 18x11 board.
- The board background is a single generated meadow image for performance and visual continuity.
- Logic tiles stay aligned to the combat grid, but grass should read as one continuous field rather than separated square clumps.
- Props, blockers, cover, and units render above the background and remain aligned to logical tile centers.

## UI Style

- UI should use compact pixel-styled panels and borders.
- Debug-only text should be minimized on the main screen.
- Action labels may remain text-based while skill icons are not final.
- Overlays should be readable but soft enough not to hide terrain art.

## Acceptance

- At 2560x1440, the board uses most of the screen without cutting off top or bottom UI.
- The bottom action bar remains visible and clickable.
- Turn order remains visible in the top-right corner.
- Unit HP/AP/MP and target preview labels do not replace each other.
- The layout remains playable when the active encounter is reset or reloaded.
