# Tactical environment cohesion and readable terrain

Stage83,2026-11-05. User delegates travel/combat polish and desktop play. Owners:
presentation030 arenas, combat/grid024 terrain, combat/grid022 line of sight,
presentation041 locomotion.

The accepted painted characters remain unchanged. Replace selected bright
faceted environment props with a coherent painted family in versioned sibling
assets, retaining archived originals. Camera: orthographic oblique3/4, elevated
front view, light upper-left, muted olive/umber/slate, restrained worn highlights,
soft painted edges and readable silhouettes. No baked labels/grid/UI/characters.
Logical tiles140x104; actors about170px tall. Trees250..360px, low cover60..110px,
stone obstacles90..180px. Transparent padded RGBA; feet/roots anchored to tile
ground. Aseprite editable source and repeatable exports, English prompt/manifest,
actual720p/1080p arena review required. This is agent-selected, user review pending.

Props are presentation only. Existing map cells, passability, costs and attack
modifiers stay authoritative. Preserve existing prop sizes/pivots when swapping
images by normalizing each new export to its declared canvas and ground anchor.
Low cover remains walkable and visually low. Hover must explain real semantics:
floor1MP; low cover1MP and ranged attacker -20hit; highground2MP and ranged
attacker +10hit/+1maximum range; blocked impassable and blocks ranged line of
sight when intermediate on the firing line, as specified by combat/grid022.
Do not imply cover blocks arrows or add hidden tactical bonuses in art code.

Proof: slices/042_tactical_environment_readability.md, environment readability
tests, unchanged resolver terrain slices, actual native arena captures and normal
desktop battles. Technical PASS is distinct from user art approval.
