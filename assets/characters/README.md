# Character Art Direction

Use the current character PNGs as the visual reference for future heroes, villains, and combat-capable NPCs. Character art lives in `assets/characters` because the same actor can be reused by combat, exploration, roster, dialogue, and future presentation layers.

## Reference Assets

- Player/hero style: `heroes/warrior/pose/warrior_south.png`, `heroes/warrior/pose/warrior_east.png`
- Enemy style: `villains/enemy_baddie/pose/enemy_baddie_south.png`, `villains/enemy_baddie/pose/enemy_baddie_east.png`

## Folder Layout

- `heroes/<character_id>/` stores player-side or party unit variants.
- `villains/<character_id>/` stores hostile unit variants.
- Each character folder owns action-state subfolders:
  - `pose/` for neutral idle/standing frames, used when the nearest enemy is farther than 2 tiles;
  - `fight-stance-idle-8-frames/` for combat-ready idle frames, used when an enemy is within 2 tiles;
  - `walk/` for movement frames;
  - `combat/` for attack frames;
  - `hit/` for taking-damage frames;
  - `falling-back-death/` for death frames.
- Debug combat uses `pose` for neutral stance, `fight-stance-idle-8-frames` for nearby combat stance, `walk` during movement, `combat` during attacks, `hit` when damage is received, and `falling-back-death` when a unit dies.
- If an action-state frame is missing, presentation falls back through compatible aliases and then to the matching `pose` frame.
- Every production combat-capable character should ship all six visual states above before it is considered complete.

## Naming

Preferred names:

- `pose/<character_id>_<direction>.png`
- `fight-stance-idle-8-frames/<character_id>_<direction>_fight-stance-idle-8-frames.png`
- `walk/<character_id>_<direction>_walk.png`
- `combat/<character_id>_<direction>_combat.png`
- `hit/<character_id>_<direction>_hit.png`
- `falling-back-death/<character_id>_<direction>_falling-back-death.png`

Short action names are also accepted:

- `walk/<direction>_walk.png`
- `combat/<direction>_combat.png`
- `hit/<direction>_hit.png`
- `falling-back-death/<direction>_falling-back-death.png`

Accepted compatibility aliases:

- combat stance: `combat_idle/<character_id>_<direction>_combat_idle.png`
- taking damage: `damage/<character_id>_<direction>_damage.png` or `hurt/<character_id>_<direction>_hurt.png`
- death: `death/<character_id>_<direction>_death.png`

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
