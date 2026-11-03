# Map authoring v2

Status: accepted; automated and actual workbench gates passed. Date: 2026-11-01.

Tiled TMX is authoritative for generated map JSON. Converter emits schema_version2,
row-major full tiles, test_spawns, optional background_path/terrain_theme and
terrain_decorations. Orthogonal finite square grids and CSV terrain only; reject
unknown/flipped gids, invalid dimensions, non-grid-aligned/out-of-bounds objects,
blocked/overlapping spawn points, duplicate ids and unavailable decoration paths.
Object positions are top-left cell origins in pixels; no implicit rounding or
tile-object bottom-anchor adjustment. Decoration objects are points/rectangles
in objectgroup decorations, with path and optional kind properties. Spawn roles
remain metadata, not automatic combat unit generation.

Both combat runtimes materialize grid and map visual defaults. Explicit encounter
visuals override map visuals. Existing unversioned maps remain readable. Validation
detects TMX/JSON drift and catches conversion failures as actionable diagnostics.

Workbench loads encounter map references into a private inline working copy.
Loading never writes source data. Saving explicitly forks the materialized
encounter (removes map_path), avoiding an inline/reference conflict. Spawn brush
moves the selected existing unit only. Invalid/overlapping/blocked unit starts
prevent save/play with visible diagnostics. Metadata spawn markers are shown.
Developer F6 opens workbench; Play Draft runs its in-memory working copy through
the normal resolver. F6 in draft combat returns the copy to the workbench. Draft
play must never consume/complete a pending dungeon combat. No automatic file write.

Proof: tooling slice003, converter negative tests, Godot workbench tests, full
regression including combat slices, and actual edit/save/reload/play on DISPLAY1.
