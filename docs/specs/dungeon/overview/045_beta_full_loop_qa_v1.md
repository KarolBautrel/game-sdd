# Playable Beta full-loop QA and injury return

Status: implemented and accepted (stage 1 report)
Date: 2026-11-01

World003 also reuses an explicit `returned_party_effects` wrapper around the
same absolute-HP mapping. A completed road encounter normalizes fallen heroes
to1HP, recomputes aggregate loss and preserves debuffs, as a campaign return.
It does not change ordinary in-dungeon incapacitation or older partial fixtures.

## Rules

Combat result application maps surviving player IDs to expedition formation
targets. Their absolute HP replaces the previous injury amount (max HP minus
returned HP), rather than adding the same pre-combat injury twice. Unknown IDs
are ignored. Defeated formation members are incapacitated at zero HP until
recovery supplies restore HP. There is no permanent-death system in this beta.
Bandages/camping use the existing recovery amounts and can restore incapacitated
members. Dungeon cards show current/max HP; the next combat uses current HP.
The displayed HP bar must refresh after recovery and fit within the viewport.
Hazard-only launch loss retains its existing nonlethal floor of one HP.
Tactical statuses remain combat-owned; existing dungeon debuffs remain dungeon-
owned. This change does not translate every combat status into an expedition debuff.

Reject an unsupported result before clearing any pending request. Reapplying an
accepted result is rejected; no reward or injury is applied twice. Completed runs
reject further movement. A pending fight must be resolved before leaving its room.

## Deterministic proof

The full-loop runner uses the normal entry selection, state model, session handoff
and combat resolver. An optional explicit positive combat seed is accepted by
`start_combat` for QA; ordinary launches keep time-based variation. The runner
uses normal legal commands and bounded deterministic player policy, never Debug
Win, enemy HP edits or forced result payloads to win. It records checkpoints
and fails nonzero if a required phase/reward/return invariant fails. Execute the
same seeded run twice and compare results. Separate negative boundary tests may
use shaped payloads to isolate rejection and injury semantics.

Actual gameplay remains mandatory and distinct from the automated runner.
For reproducible hands-on QA, debug builds may read local project setting
`debug/qa/combat_seed` (default zero). `start_game.ps1 -CombatSeed 1234` stores
this opt-in setting in the ignored local profile. Release builds ignore it.

## Proof

- Slice `053_beta_full_loop_qa_v1.md`
- `scripts/domain/dungeon_beta_loop_tests.gd`
- `scripts/session/dungeon_combat_injury_tests.gd`
- `scripts/presentation/dungeon_party_layout_tests.gd`
- Full runner plus actual DISPLAY1 playthrough recorded in stage 1 report.
