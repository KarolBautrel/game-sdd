# Slice 087: Combat HUD Restructure V1

Status: active

Owner spec: `docs/specs/combat/presentation/087_combat_hud_restructure_v1.md`

## Scenario

Given the provided combat UI atlas and example mockup

When processed UI assets are generated and the combat debug scene loads

Then the action bar and core panels use fantasy UI frames from processed assets

And primary action buttons show enlarged atlas-backed icons without visible action-name text

And named skills use their specific processed icons before falling back to generic action icons

And standard skillbar actions use full-size processed `icons/icon_*` exports instead of smaller inner crops for consistent slot scale

And hovering an action icon updates the action detail panel with readable action context

And log, feed, and turn order copy stay inside their framed panel bounds

And report/feed typography uses compact font sizes and bounded lines so text does not spill out of the report frame

And the active unit HP/AP/MP is visible in the board overlay HUD

And processed HP/AP/MP bar art is used for the active-unit UI overlay

And recent combat log text is visible in a board overlay without stretching the UI across the whole viewport

And active-unit resource bars stay as a readable top-left board overlay using generated `384x56` mini bar PNGs without native-scale bar atlas art or expanding text

And log/feed overlay is positioned separately from the active-unit resource bars

And framed log/feed panels show fallback or recent event text instead of empty framed boxes

And unit-overhead board resource info remains compact text rather than large UI bars

And processed character walk, attack, hit, idle, and death frames keep a stable visual scale during animation

And processed enemy and mercenary visuals are normalized to the player warrior pose height unless explicitly configured otherwise

And defeated units remain visible as corpse sprites instead of shrinking into a tiny final fade frame

And debug controls remain available without replacing the main action slot layout.

## Acceptance Checks

- `assets/ui/combat/processed/manifest.json` exists.
- Processed action slot, selected slot, panel, and icon PNGs exist.
- Processed skill-specific icons exist for `aimed_shot`, `deep_cut`, `guard_break`, `power_strike`, and `shield_wall`.
- Primary action buttons do not overflow with text labels because labels are moved to tooltip/detail surfaces.
- Action hover updates detail copy without requiring the action to be selected.
- Action feed and turn order text use bounded wrapping/clipping.
- Report/feed labels use compact font sizing and bounded visible line counts.
- Processed `bar_hp`, `bar_ap`, and `bar_mp` assets are loaded by the active-unit overlay HUD.
- Unit-overhead resource panels use compact text labels.
- The board overlay log/action feed remains visible during combat and does not share the resource bar corner.
- The board overlay log/action feed has non-empty text after scene load.
- Generated mini bars are `384x56`.
- Processed-sheet units render on a stable canvas across pose, walk, combat, hit, and death frames.
- Processed-sheet visual scale is derived from the player warrior reference height.
- Dead processed-sheet units hold a visible corpse frame after the death animation.
- `CombatDebug.tscn` loads headlessly.
- Manual visual review confirms the HUD is closer to the provided example and remains readable.

## Manual Review Gap

Automated tests can verify asset paths and scene load, but final visual quality needs manual screenshot review.
