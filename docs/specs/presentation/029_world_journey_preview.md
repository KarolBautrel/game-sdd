# World journey preview and explicit commitment

Date:2026-11-04. Authorized stage69, milestone022. Keep the approved campaign006
world-map art, frame/material hierarchy and typography. World002/003 and
CampaignSession remain the owners of route costs, danger, events and saves.

- Selecting a known adjacent map landmark or journey-list entry previews the
  route. It never travels, charges food/time, increments journey_count, creates
  an event, rerolls risk, heals or writes a save.
- Distinguish current location and selected destination. Show the trusted route's
  hours, food cost, authored danger and required return reserve. Forecast arrival
  from elapsed_hours+route.time_hours using WorldTravel.clock_text; label it as
  before any road-event time. Show food remaining and food available beyond the
  return reserve, with no new carrying/capacity rule.
- Insufficient food remains inspectable so the UI can explain the exact missing
  trip+reserve requirement. Unknown/non-adjacent destinations stay unavailable.
  Pending events and active expeditions block journey selection/confirmation.
- One Confirm journey action commits through CampaignSession.travel, which
  re-quotes/revalidates and atomically saves the actual transaction. Cancellation
  changes only local selection. A successful trip clears selection; duplicate
  confirmation cannot charge twice. Failed writes preserve the real profile.
- Return reserve is retained, not charged in advance. No invented gold toll,
  real-time animation delay, scouting, new road encounter or risk reduction.
- Preserve native readable focus, route names, destination/service gating and
  event resume. Existing source/release fixture inputs must exercise preview
  followed by confirmation, rather than silently bypass the new control.

Proof: slices/029_world_journey_preview.md and focused journey UI/world tests,
existing campaign/save/event tests and native region review.
