# Slice 052 - Large Horizontal Dungeon Maps V1

## Objective

Prove that D2 and D3 generated dungeons can be larger, horizontally scrollable, and more combat-heavy while keeping room cards readable.

## Implementation

- Render medium/deep generated maps as longer rightward routes.
- Raise D3 beta pacing to at least three combat rooms per deep template.
- Keep generated combat encounter selection data-driven through `old_mine_generated_combat_pool`.
- Add a horizontally scrollable map viewport around `GraphLayer`.
- Compute graph content size separately from the visible map frame.
- Stop shrinking D2/D3 room cards to fit one screen.

## Acceptance

- Generated D2 and D3 keep normal room-card size.
- Generated D2 and D3 graph content is wider than the visible map viewport.
- Generated D3 display goes farther right than down.
- Generated D3 has at least three combat rooms.
- All rooms fit inside scroll content bounds.
- Existing authored dungeon presentation still fits inside the scroll content model.
- Dungeon validation and HUD tests pass.
