# Expedition and combat UI stages27..29

Authorized2026-11-02, following explicit user approval of campaign appearance.
Owners presentation007/slice007 extending006; dungeon/combat rules unchanged.

1. Stage27 dungeon exploration/preparation/events: automated PASS,
   AWAITING_INTERACTIVE. Full50/50,99 layout assertions and21 native clicks across
   three sizes; see stage27 report. Paper map/inspector, named rooms, new art and
   reachable preparation/events implemented.
2. Stage28 battle UI: automated PASS, AWAITING_INTERACTIVE.51/51 regression,
   150 targeted assertions,39 native clicks/18 captures at three sizes. Fixed
   reset visuals, shared chrome/named actions/side inspector; see stage28 report.
3. Stage29 integrated native/release/handoff: automated PASS,
   AWAITING_INTERACTIVE.51/51, strict2094 files, release/probe and final EXE native
   play/campaign104 clicks/51 captures PASS, zero diagnostics. See stage29 report.
   Next:46 physical cases after explicit desktop release; no further feature batch.

Each increment requires automated PASS and reviewed actual GPU output. User's
background-work policy permits the next increment while actual play remains
AWAITING_INTERACTIVE. Never mark physical scenarios passed without playing them.
