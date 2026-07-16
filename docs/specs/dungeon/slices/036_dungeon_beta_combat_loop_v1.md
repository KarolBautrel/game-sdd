# Slice 036: Dungeon Beta Combat Loop V1

Status: implemented
Owner spec: `docs/specs/dungeon/overview/029_dungeon_beta_combat_loop_v1.md`

## Acceptance

- Given combat returns victory from a normal combat room, the session clears pending combat, marks the room secured, and stores readable return feedback.
- Given combat returns victory from a guarded treasure room, the session unlocks the reward and stores feedback that names the unlocked reward.
- Given combat returns defeat, the session clears the launch request but does not mark the room secured.
- Given the dungeon scene is restored after combat, the existing HUD can display `DungeonRunSession.last_feedback`.

## Proof

- `scripts/session/dungeon_run_session_tests.gd`
- `scripts/presentation/dungeon_exploration_hud_tests.gd`
