# The Lantern Court: small-space pilot

Full design and ordered build: world008/slice008. StageA is an isolated mechanical
pilot using existing painted party sprites and environment props. NPC appearances
are stand-ins, not new approved civilian identities or final city art. StageB
campaign/service integration and stageC inn/final art remain pending.

The12x10courtyard uses a2:1 diamond projection. WASD/arrows walk in screen
directions; diagonals are normalized. Two companions follow the leader's valid
breadcrumb route. Accepted125ms walk cels and104px/s at0.65sprite scale retain the
original one-second stride. E/Enter talks to the nearest reachable NPC; Escape
or Continue closes. A conversation blocks motion and clears held input.

The gate watch, quartermaster and innkeeper offer authored dialogue. Purchases,
rest, gear and travel remain in their existing campaign interfaces. The preview
never opens/writes a campaign save. Close preview exits only the preview process.

```powershell
& .\tools\qa\start_game.ps1 -Scene town-preview
```

Canonical map: resources/tiled/maps/ravenford_courtyard_pilot.tmx. Re-export with
`tools/maps/tiled_to_map_json.py` to its matching map-v2 JSON. Space/NPC metadata:
resources/data/town_spaces/ravenford_courtyard.json, schema town_space. Validator
checks unique connected spawns and complete eight-facing source profiles.

Review: [courtyard](courtyard-native.png), [dialogue](dialogue-native.png).
Evidence: docs/qa/2026-11-04-town-exploration-pilot.md. This is a movement/dialogue
prototype; approved tactical SE/SW selectors and actor artwork remain untouched.
