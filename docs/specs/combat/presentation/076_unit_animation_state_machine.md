# 076 Unit Animation State Machine

Status: implemented
Date: 2026-07-15

## Purpose

Combat unit visuals should be selected from a small reusable state model instead of scattered one-off flags in the sandbox controller.

This keeps movement, attack, hit, death, and future status reactions predictable when more combat effects are added.

## Rules

- Presentation state is derived from resolver events.
- Presentation010/stage36: delayed pose cleanup refreshes unit visuals only.
  It must retain live action/tile controls and an in-progress pointer press;
  a post-turn action must not disappear between mouse-down and mouse-up.
- Combat presentation must not invent gameplay outcomes.
- `unit_moved` maps the actor to `walk`.
- `damage_applied` maps the actor to `combat`.
- `damage_applied` maps the target to:
  - `death` when `hp_after <= 0`;
  - `hit` otherwise.
- `hit_roll_resolved` maps the actor to `combat`.
- `status_applied` maps the target to `status_reaction`.
- Missing animation assets must fall back deterministically to available combat, hit, or pose art.
- The sandbox controller may still own tweens and board positioning, but event-to-visual-state mapping belongs to a reusable presentation helper.

## Acceptance

- Movement still uses walk visuals.
- Attacks still use combat visuals.
- Damaged units still use hit visuals.
- Defeated units still use death visuals.
- Status application has a reusable state path for future effects.
- Helper mapping is covered by a Godot headless presentation test.
