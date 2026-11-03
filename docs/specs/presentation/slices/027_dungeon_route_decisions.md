# Native dungeon route decision acceptance

Owner: presentation027. Stage67. Status: IMPLEMENTED / AUTOMATED_PASS /
AWAITING_INTERACTIVE (Computer Use activation failure, not a missing permission).

1. Start a sandbox or isolated managed run; inspect a connected destination via
   the map and passage list. Current room/light/supplies/run log stay exact.
2. Confirm travel through its real Button. Domain entry spends the authored
   light cost once and creates any real pending event; preview is cleared.
3. Inspect a non-adjacent or locked room. Explain the restriction and disable
   Travel; calling the underlying command remains rejected by the domain.
4. A pending room/corridor choice blocks background mouse/Tab/F7, focuses a legal
   choice and wraps focus within the modal. Resolving it restores navigation.
5. No heavy pipe/cross/marker corridor nodes appear in the campaign-skinned map.
   Real adjacent rooms remain discoverable through labels and the passage list.
6. Native inspector shows concise current-room text, without raw coordinates or
   a duplicate complete resource inventory. Preparation/result flows remain clear.
7. Verify720p/1080p/1440p/4K native captures and an actual normal-window play sample
   on DISPLAY1. If OS activation fails, record the exact blocker and do not mark
   interactive acceptance complete from engine-local fixture events.

Automated owner: scripts/presentation/dungeon_route_preview_tests.gd plus existing
dungeon_exploration_hud_tests, dungeon_party_layout_tests, campaign_interface_tests,
domain/session regression and validate_all. Persist actual results in dated QA.
