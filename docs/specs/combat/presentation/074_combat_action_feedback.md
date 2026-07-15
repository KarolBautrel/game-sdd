# 074 Combat Action Feedback

Status: implemented
Date: 2026-07-15

## Purpose

Executing an attack should read as an in-game combat beat, not only as a resource number changing.

Preview explains what should happen before confirmation. Action feedback explains what happened after confirmation.

## Rules

- Combat action feedback is driven by resolver events.
- Presentation must not invent combat outcomes.
- Floating combat text is produced by a reusable presentation helper that maps resolver events into temporary board messages.
- `damage_applied` creates floating `-X DMG` text near the target.
- `hit_roll_resolved` with `outcome: "miss"` creates floating `MISS` text near the target.
- `status_applied` may create floating uppercase status text near the target, such as `STUNNED` or `BLEEDING`, when those statuses are introduced.
- `command_rejected` remains a HUD/action-banner response and should not create combat floating text.
- Floating text should appear above the board/unit layer and should not obscure the bottom skillbar.
- Floating text should animate briefly upward and fade out.
- Floating text styling and timing should be centralized so future status, buff, debuff, heal, or resource messages do not duplicate node/tween setup.
- Actor lunge, target hit shake, death fall, and floating text should run as one readable combat beat.
- Floating text must be temporary and cleaned up after the animation finishes or the encounter is re-rendered.

## Style

- Damage text should be high-contrast and compact.
- Miss text should be visually distinct from damage.
- Text should use pixel-style shadows/borders consistent with combat HUD.

## Acceptance

- A successful melee or ranged hit shows floating `-X DMG` text near the target.
- A miss shows floating `MISS` near the target.
- The combat sandbox uses the shared floating text helper rather than owning damage/miss/status message construction directly.
- `CombatFloatingText.messages_from_events` is covered by a Godot headless helper test.
- Existing combat animations still play.
- Python validation, Godot project load, and Godot combat slice tests pass.
