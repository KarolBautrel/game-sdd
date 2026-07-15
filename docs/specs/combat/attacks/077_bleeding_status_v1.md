# 077 Bleeding Status V1

Status: implemented
Date: 2026-07-15

## Intent

Add the first damage-over-time combat status.

Bleeding should prove that attack profiles can apply statuses, that statuses can tick on future turns, and that presentation can display both status application and tick damage without special-case UI code.

## Rules

- `bleeding` is a status applied by an attack action profile.
- `deep_cut` is the first player-facing melee action that applies `bleeding`.
- `deep_cut` targets one adjacent enemy.
- `deep_cut` uses normal melee target validation.
- On hit, `deep_cut` applies normal damage and then applies `bleeding` if the target is still alive.
- A bleeding status stores:
  - `id: "bleeding"`;
  - `source_unit_id`;
  - `remaining_turns`;
  - `duration_rule: "own_turn_starts"`;
  - `tick_damage`.
- At the start of the affected unit's own turn, bleeding deals `tick_damage`.
- Bleeding tick damage emits `damage_applied` with:
  - `source_status_id: "bleeding"`;
  - `damage`;
  - `hp_before`;
  - `hp_after`.
- Bleeding duration decreases after each own-turn tick.
- When `remaining_turns` reaches 0, `status_expired` is emitted.
- Bleeding tick damage can defeat a unit and end combat.

## Presentation

- `status_applied` for bleeding creates floating `BLEEDING` text through the shared floating text helper.
- Bleeding tick damage creates floating `-X DMG` text through the shared floating text helper.
- A bleeding unit shows a compact red status icon above the unit until the status expires.

## Acceptance Proof

Implemented by:

```text
docs/specs/combat/slices/077_bleeding_status_v1.md
```

## Non-Goals

- stacking multiple bleeding instances;
- bleed resistance;
- bleed-specific pose assets;
- critical bleeding;
- healing or cleansing.
