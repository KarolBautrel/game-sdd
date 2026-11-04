# Crownlands atlas art

Four new background plates generated with the built-in imagegen tool. The
accepted `assets/ui/campaign/marches_map.png` was used as a style reference and
is unchanged byte-for-byte. Full prompts: `prompts.json`; exact source/editable/
runtime hashes and dimensions: `manifest.json`.

Visual target: antique golden parchment, sepia engraved hatching, muted olive
pines, blue-green rivers, oblique miniature landmarks and a worn irregular rim.
Native game labels, states and actual roads are never baked into these plates.
World view shows four connected provinces; each province plate is a closer map,
not a literal zoom crop. Preserve the original Marches artwork on future changes.

Production outputs: four opaque1672x941PNGs in `assets/ui/campaign/`; four editable
sources in `assets_src/aseprite/world_atlas/`. Linear filtering, original-size
exports, aspect-preserving display. The UI uses normalized domain-authored
anchors; generated landmark positions are only approximate visual references.

To reproduce runtime exports after editing the Aseprite sources:

```powershell
& 'C:/Program Files/Aseprite/Aseprite.exe' -b --script-param "root=$PWD" --script-param from_editable=1 --script tools/aseprite/world_atlas.lua
```

Omit `from_editable=1` only for a deliberate rebuild from the raw generated PNGs;
that mode recreates the editable sources. Four editable exports were reproduced
with exact runtime PNG hashes. No rejected existing art or private skill package
was copied into this delivery. These are project-generated illustrations, not
third-party stock assets. Native in-game evidence is linked from the stage QA.
