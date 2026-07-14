# Combat Unit Art Direction

Use the current unit PNGs as the visual reference for future combat characters.

## Reference Assets

- Player/hero style: `heroes/warrior/pose/warrior_south.png`, `heroes/warrior/pose/warrior_east.png`
- Enemy style: `villains/enemy_baddie/pose/enemy_baddie_south.png`, `villains/enemy_baddie/pose/enemy_baddie_east.png`

## Folder Layout

- `heroes/<character_id>/` stores player-side or party unit variants.
- `villains/<character_id>/` stores hostile unit variants.
- Each character folder owns action-state subfolders:
  - `pose/` for idle/standing frames;
  - `walk/` for movement frames;
  - `combat/` for attack/combat frames.
- Debug combat uses `pose` while idle, `walk` during movement, and attempts `combat` during attack feedback.
- If a `combat` frame is missing, presentation falls back to the matching `pose` frame.

## Naming

Preferred names:

- `pose/<character_id>_<direction>.png`
- `walk/<character_id>_<direction>_walk.png`
- `combat/<character_id>_<direction>_combat.png`

Short walk/combat names are also accepted:

- `walk/<direction>_walk.png`
- `combat/<direction>_combat.png`

## Target Format

- transparent-background PNG;
- one character per image;
- centered full-body tactical unit;
- 124x124 or 128x128 source size;
- readable when downscaled to a 56x56 combat grid icon;
- eight directional variants when possible:
  - `north`;
  - `north_east`;
  - `east`;
  - `south_east`;
  - `south`;
  - `south_west`;
  - `west`;
  - `north_west`.

## Style Notes

- dark fantasy tactical RPG unit art;
- compact armored silhouette;
- high-contrast metal highlights;
- painterly pixel-art feel with crisp edges;
- no background, no shadow plate, no UI frame;
- slightly top-down/isometric camera;
- keep weapons and shields visible inside the image bounds;
- avoid oversized heads, cartoon proportions, and clean vector shapes.

## Generation Prompt Seed

Create a transparent-background dark fantasy tactical RPG unit sprite matching the style of the existing `warrior_*` and `enemy_baddie_*` PNG references. Full-body compact armored silhouette, slightly top-down isometric view, painterly pixel-art texture, crisp edges, high-contrast metal highlights, readable at small grid-icon size, no background, no UI frame.
