# Slice 050 - Playable Generated Beta Party V1

## Objective

Start hands-on dungeon beta testing from generated content and run every dungeon-launched combat with Warrior plus Archer.

## Implementation

- Change default dungeon entry payload to generated medium mine.
- Initialize dungeon debug source state as generated.
- Expand default party formation to front Warrior plus backline Archer.
- Keep authored Old Mine compatible with the same two-slot formation.
- Inject the Archer and `hero_bow` profile into dungeon-launched combat encounters.
- Preserve both player units when dungeon session randomizes enemies.
- Add regression coverage for default source, two-slot formation, injected Archer, bow profile, and front-slot effects.

## Acceptance

- Opening dungeon debug without an existing run starts on generated dungeon content.
- Switching to authored Old Mine remains possible from the preparation screen.
- Starting dungeon combat creates exactly two player units before randomized enemies.
- Front-slot dungeon damage/debuff effects hit Warrior and do not hit Archer.
- Validation and affected Godot tests pass.
