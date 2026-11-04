# Dungeon material exports

The approved campaign artwork remains the source. No new art generation or
changes to the world-travel assets are involved.

- `campaign_hide.aseprite`:539x539unframed crop of
  `assets_src/campaign_ui/materials-source.png`, at source resolution. Active
  again after the user restored textured72 as the temporary current appearance.
- `frame_dark.aseprite` and `button.aseprite`: original textured campaign borders
  with muted center contrast, restored72 version. Stretch once; do not tile.
- Rejected72b flat export/shader and current72 snapshot are preserved separately
  under `assets_src/ui_review_baselines/`, with hashes. Do not promote72b again.
- Runtime exports: `assets/ui/dungeon/materials/`. Texture catalogue owns hashes.

From the repository in PowerShell:

```powershell
& 'C:/Program Files/Aseprite/Aseprite.exe' -b --script-param "root=$PWD" --script tools/aseprite/dungeon_visual_materials.lua
.venv/Scripts/python.exe tools/assets/build_catalogue.py
```

Provenance and usage rights are inherited from the existing campaign source
assets; see `assets_src/campaign_ui/` and the campaign UI design documentation.
Original campaign exports are preserved byte for byte.
