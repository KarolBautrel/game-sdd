# Combat board frame and panel skin v1

Status: implemented; automated acceptance PASS; interactive acceptance pending.
Date: 2026-11-01. Queue item15 / stage8.

## Ownership and scope

CombatPanelSkin owns battle chrome only and composes the existing PixelSkin and
imported AssetCatalog. It does not decide actions, state, targeting or outcomes.
Reuse processed panel_small/panel_large art; no new raster assets or pipeline.
Preserve action slots, resource meter values/geometry and all resolver rules.

## Rules

- Encounter title/status, turn order, action bar, action context, action feed,
  tooltip surfaces and scenario popup use the same dark wood/iron/gold family.
  Outer panels use the imported small frame, wider bar uses the large frame;
  inset action context and compact resource backing use restrained flat styles.
  Panel padding keeps text away from decorative borders. Resource bars retain
  their384x56 geometry and compact backing so decoration cannot expand them.
- A thin imported frame surrounds the board. Its center is not drawn, it sits
  behind terrain and its mouse filter is IGNORE. It must not intercept tiles,
  obscure terrain, or change unit/grid coordinates. Flat fallback also leaves
  the center transparent. Board frame output is scaled for an8px perimeter.
- The board and its child layers scale together to fit the space between the
  top and bottom HUD. A separate viewport control reserves that space, centers
  the board and its frame, and preserves aspect ratio. It must fit2560x1440
  and1920x1080 layout tests without a clipped last row or overlap with HUD.
  Pointer targeting continues through normal transformed tile buttons.
- Every role has an explicit StyleBoxFlat fallback if its frame texture is
  missing. Fallback padding matches the textured role. No null/default-engine
  frame is an accepted missing-asset fallback. Style caches are per instance;
  changing board transparency must not mutate opaque panel styles or another
  screen's styles. Texture fallback does not modify player state or assets.
- Combat-local Theme styles TooltipPanel/TooltipLabel and PopupMenu, including
  selected menu rows and separators. Tooltips retain their full information,
  split into lines using the actual tooltip font metrics with a maximum420px
  line width, including long unbroken tokens. Do not clip away tooltip content.
- Visible labels wrap/clip inside content bounds and retain the font-derived
  line-height reservations from presentation087/slice095. Long titles/status,
  action details/feed and turn order cannot expand panels beyond the viewport.
- Resizing, action-count changes and encounter reload keep the board frame and
  HUD aligned. Visual changes must not mutate the combat domain state.

## Proof and manual gate

Chronological slice097; `combat_panel_skin_tests.gd` covers real scene layout,
fallbacks, instance isolation, long tooltip wrapping, board transparency/passive
input and resize/long-copy boundaries. Existing HUD, targeting, animation and
combat domain suites remain regression gates. Full verifier and scene checker
must pass. Actual windowed DISPLAY1 play must inspect frame/padding/tooltips/menu,
move and target edge tiles, Defend/attack/end turn, reload/resize and normal
victory/return before this stage is accepted.

User currently uses the desktop: implement and run headless checks only. Do not
activate a GUI or inject desktop input until the user makes controls available.
That restriction leaves manual acceptance open, not implicitly passed.

API references: [Control theme/tooltip](https://docs.godotengine.org/en/4.7/classes/class_control.html),
[StyleBoxTexture center](https://docs.godotengine.org/en/4.7/classes/class_styleboxtexture.html).
