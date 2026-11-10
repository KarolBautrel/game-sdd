# Vast map framing and size selection

Follow-up96c, world020; proof [slice048](slices/048_vast_worlds.md). Retain approved
campaign/ashen materials, fonts, symbols and camera gestures. Add a visible
Large/Vast choice to strategic factories and Vast to RegionFoundry. Size choice
alone never changes the current company; New/Resume explicitly opens its own
size slot. Existing active saves keep their stored map size.

Vast rendered reference width is6688versus3344Large. Shared camera retains old
limits/defaults for v1/v2; Vast local focus starts5.2and max zoom9, versus2.6/4.5.
The same native landmark/terrain detail size therefore occupies about a quarter
as much of the larger world in a local view. Company/Center, wheel, RMB/MMB,
minimap and Overview work within the same normalized bounds. Overview alone
fits the whole world; it does not shrink labels/hit targets or issue orders.

Explicit native entries `StrategicVastWorld` / `StrategistVastWorld`, launchers
`strategy-vast` / `strategy-ai-vast`, create/resume distinct slots. Managed dungeon
return and seed/size changes retain the correct scene. Show actual size beside
factory settings. No visible launch or desktop input while controls are withheld.
