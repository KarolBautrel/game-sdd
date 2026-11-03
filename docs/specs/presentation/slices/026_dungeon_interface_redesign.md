# Dungeon interface design review

Owner: [presentation026](../026_dungeon_interface_redesign.md).
Status: WORLD-FAMILY REVISION DELIVERED / AGENT_VISUAL_REVIEW. The first flat
composition is superseded. Native follow-up is authorized through milestone022.

## Design acceptance scenarios

1. In the exploration composition, identify current room, selected room, next
   action, light, carried supplies and both heroes' HP without reading diagnostics.
2. Open the low-light fixture: the warning and oil action become prominent while
   room names and route reading remain legible. No invented fog or timer appears.
3. Open the rubble fixture: exactly the authored pickaxe/force choices and clear
   consequences are shown; background input is blocked until a choice is made.
4. Open preparation: all six real supply types and the authored default7/7 packing
   budget fit; changing quantities respects fixture capacity/min/max.
5. Open reward: distinguish the guarded cache claim (7gold/12XP/rusty_key) from
   already claimed expedition loot. Claims in the mockup have no real save effect.
6. Check720p/1080p/1440p/4K/ultrawide design layouts for accessible controls and
   deliberate chart scrolling. Browser checks are separate from native Godot proof.

Evidence and any automated mockup limitations belong in
`docs/qa/2026-11-03-dungeon-ui-design.md`. Actual user choice is not inferred from
successful browser rendering. Native implementation/full managed expedition and
physical input tests remain future acceptance work after design selection.
