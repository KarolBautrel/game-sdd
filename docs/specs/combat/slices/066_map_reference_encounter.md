# 066 Map Reference Encounter

Status: implemented
Date: 2026-07-14

## Purpose

Start Map Pipeline V1 by making authored Tiled maps drive combat encounter grids.

Today the sandbox has both:

- editable Tiled source: `resources/tiled/maps/combat_test_clearing.tmx`;
- generated map data: `resources/data/maps/combat_test_clearing.json`;
- combat encounter data with duplicated `grid.tiles`.

This removes that duplication for the map-authored sandbox encounter.

## Acceptance

- combat encounters may reference a map through `map_path`;
- `map_path` points to `res://resources/data/maps/*.json`;
- when an encounter has `map_path`, combat setup loads `width`, `height`, and `tiles` from the map JSON;
- inline `grid` remains supported for low-level regression slices;
- validators reject an encounter that defines both stale inline map data and a conflicting `map_path`;
- validators reject unit spawn positions that are outside the referenced map;
- validators reject unit spawn positions on `blocked` tiles from the referenced map;
- `debug_map_scale_showcase` uses `map_path` instead of manually duplicating the map's `grid.tiles`;
- Python and Godot combat slice validation still pass.

## Notes

This is the first step before improving targeting UX. The combat sandbox should become authored from map data first, then the UI can reliably preview movement, line of sight, cover, and blocked reasons from the same map source.
