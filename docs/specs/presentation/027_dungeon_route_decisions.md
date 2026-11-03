# Native dungeon route decisions and restrained map presentation

Date:2026-11-04. Authorized stage67 under milestone022. The user reiterates that
connections look ugly and delegates removing/replacing them to avoid kitsch.
This extends presentation007 and the design contract026; dungeon domain rules
continue to own every move, cost, lock, event and reward.

## Rules

- The campaign-skinned map omits heavy corridor pipes, decorative junction crosses
  and permanent hazard plaques. The room graph is unchanged. Available passages
  are explicit in the current room's navigation list and highlighted room states.
- Clicking a map room or a passage-list entry previews the destination. Numeric
  passage shortcuts do the same in the skinned HUD. Preview never moves the party,
  reduces light, rolls a hazard or checkpoints/changes a save.
- The preview distinguishes current location and proposed destination, shows the
  actual connecting corridor light cost and lock/non-adjacency reason, and offers
  one explicit Travel action only when available. The actual enter_room command
  revalidates everything; UI state is not a legality authority.
- Returning to current-room detail requires no command or resource. A successful
  travel/forced event resets preview; the map follows the current room without
  shrinking long generated layouts. No illustration implies a false generated
  graph connection.
- Current-room prose is concise: location/state/content, actionable threat/reward
  and last feedback. Coordinates, raw IDs and a second full supply inventory do
  not occupy the main player-facing inspector. Real values remain in the HUD.
- Pending room/corridor choices own keyboard focus and pointer input. Other HUD
  buttons cannot receive Tab focus or activate travel/F7 until resolution. Choice
  focus wraps; completing a choice restores a valid underlying focus target.
- Preparation packing, recovery, combat pending, reward, exit/retreat and managed
  checkpoint/settlement keep existing domain/session ownership. No changes to
  risk tables, lighting balance, injuries, equipment, accepted sprite art or saves.
- Retain the approved campaign frames/fonts/materials and readable native controls.
- The exact authored Old Mine graph may use the imagegen/Aseprite parchment with
  native room plates anchored to its seven landmarks. Enable it only for the
  matching dungeon id, room positions and six corridor pairs. A changed/generated
  graph falls back to truthful data-driven cards; never stretch that illustration
  beneath unrelated rooms or invent visual routes. The art does not decide travel.

Proof owner: slices/027_dungeon_route_decisions.md. Native HUD/domain tests and
GPU captures remain distinct from actual normal-window Computer Use gameplay.
