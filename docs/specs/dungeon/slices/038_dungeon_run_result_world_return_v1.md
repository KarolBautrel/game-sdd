# Slice 038: Dungeon Run Result And World Return V1

Status: implemented
Owner spec: `docs/specs/dungeon/overview/031_dungeon_run_result_world_return_v1.md`

## Acceptance

- Given the party finishes an exit room, dungeon state stores a `completed` run result payload.
- Given the party retreats from an allowed run state, dungeon state stores a `retreated` run result payload and keeps claimed rewards in the summary.
- Given the run fails, dungeon state stores a `failed` run result payload and preserves persistent effects.
- Given the session finishes a run, it stores `pending_world_return_payload` and exposes the next scene path hook.
- Given the HUD shows a completed run, the post-run summary includes the outcome, claimed rewards, and return hook.

## Proof

- `scripts/domain/dungeon_state_model_tests.gd`
- `scripts/session/dungeon_run_session_tests.gd`
- `scripts/presentation/dungeon_exploration_hud_tests.gd`
