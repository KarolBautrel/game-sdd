# Combat unit and resource readability v1

Status: implemented; automated PASS; live acceptance deferred by user.
Date: 2026-11-01. Stage9 / queue16. Extends086/087; does not replace their art.

## Rules

Reuse the existing processed unit sprites, stable roster portraits, role-aware
visual pools, corpse/depth ordering and mini HP/AP/MP bar textures. Do not add
new art or change combat state, values, legal actions or animation timing.

The active-resource overlay must visibly name the active unit and its team.
Its three384x56 mini bars also show numeric current/maximum HP/AP/MP in readable,
passive text. Allocate one readable identity line above the bars; preserve their
local geometry. Numbers use the same presentation resource overrides as bar
fills and unit overhead labels, including zero and impact/step timing.

Living unit resource backing distinguishes team, active unit (gold), hovered
unit (light border) and wounded state (dark red backing). Active and hover may
coexist; hover brightens the backing while active retains gold. Status icons
and corpse rendering remain existing systems. Hover changes presentation only,
does not select/command a unit and clears on tile exit/encounter reload.

Tile tooltips include unit identity/team, current/max resources and status text,
preferring living occupant to a corpse on the same tile. Dead units retain corpse
visuals and have no live resource/status panel. Tooltip wrapping follows089.

Missing unit art falls back without engine errors to the existing warrior for
player units or axe bandit for enemy units, with role-independent emergency
fallback explicitly limited to missing assets. Preserve the requested config.
If even emergency art is absent, display a passive readable name/team label.
Failure paths must terminate; no infinite fallback recursion or repeated errors.

## Proof

Slice098 and `combat_unit_readability_tests.gd`: actual scene identity/values,
temporary resource override refresh, hover isolation, wounded/active styling,
dead resource/status hiding, missing art fallback, repeated refresh and no state
mutation by presentation. Existing visual/asset, HUD/layout, animation and
domain suites remain gates. Live L9-01/02 (identity, active/hover, injuries,
statuses, death and resource timing) remain NOT_RUN in live-test-scenarios.md.
