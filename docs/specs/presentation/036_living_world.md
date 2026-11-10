# Living-world interface v1

Date:2026-11-04. Owners world010 and accepted presentation035/style card.

Provide a dedicated LivingWorld scene and QA launcher entry `-Scene living-world`.
The approved illustrated atlas remains the background for the authored pilot.
Actual company/caravan/patrol/raider positions and a selected route are native
overlays. Show distinct labelled faction banners and clear company identity.
Sea/blocked clicks explain rejection without altering the company.

Click land/site to travel; Pause/1x/2x/4x and Space/numeric actions control time.
Arrival, raid, contract progress and world changes produce bounded journal
feedback. The sidebar presents actual selected/current location, supplies/
security, faction relationships, contracts, camp/inn/provision actions and mine
entry/resume. Prices and availability come from CampaignSession/domain state.

Contract cards show domain-provided progress: carried delivery food versus3,
the unvisited scouting target, readiness to return to the issuer, or paid/closed
state. Disabled Accept/Report controls expose the exact current domain reason
in their tooltips; enabled controls describe the action. Campaign rejection
feedback uses the same reason. Recompute after stock, location, movement,
objective or event/run changes without rebuilding cards. Preserve accepted art,
styles and prices. Headless availability/layout checks are technical evidence;
ordinary desktop readability and play remain deferred when controls are held.

Keep leather/brass, parchment, Cinzel/Source Sans and readable native focus.
Map and inspector have independent bounds/scrolling at720p/1080p; the illustrated
map must remain visible while reading long contracts. Clicking/pausing/selection
does not rebuild the whole scene each frame or reset sidebar position/focus.
Show company supplies/gold/time/fatigue and pause/event/run state clearly.

Existing App equipment/services can be opened paused; return to the living map
after closing inventory or returning from its managed dungeon/road battle.
Opening Contracts pauses time; Chronicle remains a live, read-only activity feed.
An explicit exit returns to the ordinary atlas without rewriting that profile.
The pilot profile is separate and resumed next launch; do not auto-reset it.

Proof: slice036, focused UI/session tests and no-focus native GPU/pointer/key
fixtures. Preserve exact accepted map/art archive; no art replacement is needed.
