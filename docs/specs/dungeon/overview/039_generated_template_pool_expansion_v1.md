# 039 Generated Template Pool Expansion V1

Status: implemented
Date: 2026-07-17

## Intent

Grow generated Old Mine from a tiny difficulty-based layout set into a profile-aware curated template pool.

This keeps generation reliable and readable while giving debug playthroughs more shape variety before any free-form procedural graph work returns.

## Rules

- Generated dungeon templates declare `profile_ids`.
- `short_mine`, `medium_mine`, and `deep_mine` each have multiple selectable templates.
- Template selection filters by the requested profile first, then falls back to difficulty if needed.
- Templates declare `pacing` metadata:
  - route length;
  - branch count;
  - treasure count;
  - combat count;
  - room-event slot count;
  - corridor-hazard candidate count.
- `procedural_dungeon_draft` exposes selected template id, display name, and pacing metadata for debug/testing.
- Hazard and room-event placement remain seed-driven over authored candidate slots.

## Non-Goals

- free-form procedural graph generation;
- combat encounter pool selection;
- final reward economy balance;
- production dungeon art;
- town/global-map supply ownership.

## Proof

- schema validation for template profile and pacing fields;
- procedural tests proving each generated profile can select multiple templates;
- procedural tests proving selected template metadata is exposed;
- domain traversal smoke test still reaches generated combat rooms.
