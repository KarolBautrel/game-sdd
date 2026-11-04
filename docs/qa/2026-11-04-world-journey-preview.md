# Stage69 world journey planning

Owner: presentation029/slice029. Status: IMPLEMENTED / AUTOMATED_PASS /
AGENT_GPU_VISUAL_REVIEW / AWAITING_INTERACTIVE. Existing approved map, frame,
font and portrait family is unchanged.

Map/list destinations now preview a trip before an explicit Travel confirmation.
The plan shows authored hours/food/danger, arrival before road events, food after
travel and the retained return reserve. Underfunded adjacent routes remain
inspectable, with a disabled confirmation and precise missing-food explanation.
Cancellation is free and restores focus; success clears the plan and duplicate
confirmation cannot charge again. CampaignSession still revalidates/saves.
No new price, risk roll, save schema, balance rule or automatic equipment change.

Tests: journey_interface19/0; world_travel, world_town, road_event and campaign
session PASS; campaign_interface2433/0 and equipment_usability19/0 PASS. Repeated
preview preserves the entire profile/seed; real confirm reaches Old Mine after
6hours/1food, quoted Day1 14:00. The low-food test now uses a separate in-memory
profile so a previously rolled road event cannot mask the return-reserve case.
No player save is used. Source/export probes follow the new confirmation path.

Native source render: world-plan-69-v2, region,1920x1080/1280x720/2560x1440,
--exercise: PASS,139checks/69engine pointer events/15captures,0errors/warnings.
Actual native inputs cover Old Mine plan/cancel, Cart plan/commit, event help and
confirmed return plus existing equipment/trade/training interactions. Inspected
1080p and720p plan captures. Fixed narrow-layout behavior: reveal the confirmation
inside its scroll ancestors after selection so the user sees costs and action,
instead of an unchanged map above an off-screen panel. Final targeted tests also
prove focus restoration after cancel.

OS activation is still blocked as documented in stage67. No physical journey /
keyboard/ordinary campaign play is claimed; L69-01 remains open. Validator and
whitespace checks run before publication. Next authorized independent scope70:
two bounded authored tactical arenas using current art and existing mechanics.
