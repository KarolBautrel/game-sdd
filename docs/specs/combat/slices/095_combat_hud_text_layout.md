# Slice 095: combat HUD text layout

Owner: `presentation/087_combat_hud_restructure_v1.md`.

Given the combat scene using the project's 2560x1440 logical canvas, with physical
window sizes 2560x1440 and 1920x1080, when containers settle and an action is hovered, the title, detail,
feed, status and turn-order labels contain text and reserve at least one text
line of height. Their rectangles fit inside their parent panels. Changing the
active action count must preserve this space.

Automated proof: `scripts/presentation/combat_hud_layout_tests.gd`.
Every action button must have either an icon or readable text, including the
AI/next-turn debug controls which have no icon.
Actual proof: inspect hover, movement preview, end turn and the victory return
controls in the visible game on DISPLAY1. Initial manual run found empty action
and turn-order frames; this regression must fail before the layout repair.
