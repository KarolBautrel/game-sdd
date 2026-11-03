# Stage67 native dungeon route decisions

Status: IMPLEMENTED / AUTOMATED_PASS / AGENT_GPU_VISUAL_REVIEW /
AWAITING_INTERACTIVE. Owner: presentation027/slice027. User authorizes native
polish, desktop control and per-episode master pushes under milestone022.

## Result

Native Old Mine now has the reference-generated/Aseprite parchment chart, with
native location plates aligned to its seven landmarks. This activates only when
id/unique room positions/six corridor pairs match the authored layout. Generated
or altered dungeons retain honest data-driven room cards. One new runtime PNG;
catalogue10545 ->10546, existing entries unchanged. Accepted character art intact.

Removed heavy pipes/cross ornaments/permanent hazard plaques from the skinned
map. Current, accessible passage and selected destination are distinct. Map /
passage list/number shortcuts inspect first; Travel confirms the real command.
Preview does not spend light, roll hazards, checkpoint or move current room.
Real cost/lock/adjacency and the existing model are revalidated on commit.

Current detail omits coordinates and a duplicate resource inventory. Native
event focus wraps, removes background Tab targets and blocks F7/world until the
choice resolves. Map follows the company without shrinking generated layouts.
Packing, combat, recovery, rewards, campaign ownership/save and settlement rules
remain unchanged. No illustrative connections drive legality.

## Evidence

- dungeon_route_preview_tests:31checks/0 including source-layout fallback,
  no-mutation preview, one-cost travel, actual shrine choices, input/focus guards.
- dungeon_exploration_hud_tests, dungeon_party_layout_tests,
  expedition_art_direction_tests99/0, campaign_interface_tests2430/0,
  dungeon_state_model_tests, dungeon_run_session_tests and campaign_session_tests
  PASS. Existing generated layout/packing and campaign regressions preserved.
- Native GPU/engine-local pointer matrix:
  `tools/qa/render_campaign.py --suite play --run-id dungeon-route-67-v2 --views dungeon --sizes 1920x1080,1280x720,2560x1440,3840x2160 --exercise`.
  PASS,119checks/36native pointer clicks,24captures,0errors/warnings; start,
  preview/travel, shrine, oil, rubble resolution and real9gold reward claim.
  Source actor/body art and real player save are not modified by the fixture.
- Visually inspected actual1080p route/current state,720p destination preview and
  event sheet; native screenshots retained beside the design preview. These are
  GPU evidence, separate from the browser mockup and physical gameplay.
- Existing source/body files re-export through Aseprite; updated manifest hashes.
  Validator/whitespace and final targeted checks run before publication.

## Computer Use limitation

Normal sandbox launch PID6088 was verified running/windowed on the larger left
DISPLAY1 (3840x2160). Installed Computer Use skill, guidance and confirmation
instructions were read. Sky could enumerate/capture the game, but activation,
click and the exposed Raise action failed with `failed to activate captured
window`. A task-owned Project Manager launched via Sky reproduced the failure;
the alternate official CUA API reproduced it too. No successful OS gameplay
input is claimed. Only the task-owned PID6088 was closed; unrelated apps were
not closed or modified. No foreground/security policy was weakened to bypass it.

L67-01 remains AWAITING_INTERACTIVE, not accepted by numerical/native fixtures.
The user explicitly directs the unattended session to continue all authorized
work despite ongoing visual feedback; independently verifiable equipment/world
increments can proceed while this external OS-control issue remains recorded.
Full human/physical acceptance remains open for each episode.
