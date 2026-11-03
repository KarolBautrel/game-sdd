# Slice097: battle frame and panel skin

Owner: [presentation089](../presentation/089_combat_board_frame_skin_v1.md).
Date: 2026-11-01.

| ID | Scenario | Expected proof |
| --- | --- | --- |
| S8-01 | Instantiate the real battle scene | Encounter, turn order, bar/feed and popup/tooltip theme use explicit family styles; text stays within padded content. |
| S8-02 | Missing small/large frame paths | Every affected role returns usable flat fallback with preserved padding; board center remains clear. |
| S8-03 | Multiple skin instances and roles | Board transparency and local style edits never mutate opaque panels or another instance. |
| S8-04 | Resize2560x1440 ->1920x1080 ->2560x1440, long title/status/feed | Top/bottom HUD and framed board stay within viewport, no HUD/board overlap, readable line heights. |
| S8-05 | Long tooltip with whitespace, explicit newline and unbroken token | Complete text preserved; each line within420px using the actual tooltip font metrics. |
| S8-06 | Rebuild/reload and change available action count | Board frame remains aligned/passive; labels and controls retain bounds; skin application does not alter domain state. |
| S8-07 | Actual DISPLAY1 play | Visually inspect chrome, tooltip/menu and long copy; operate edge tiles, movement, Defend, attacks/end turn, normal victory/return and resizing. |

Automated proof: `scripts/presentation/combat_panel_skin_tests.gd`, existing HUD,
targeting/animation and combat domain suites, full verifier and scene checker.
S8-07 is manual and remains OPEN while the user uses desktop controls. The user's
later2026-11-01 instruction permits stages9..12 automation before the accumulated
live session; see docs/qa/live-test-scenarios.md. It does not accept S8-07.
