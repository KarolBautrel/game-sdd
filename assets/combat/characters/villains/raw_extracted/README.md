# Raw Extracted Combat Characters

Generated from `game_dir/raw_assety/combat/characters`.

The extractor removes near-black background pixels, crops detected sprite components, and writes transparent PNG frames plus `manifest.json`.

Near-black pixels are removed only when they belong to edge-connected background, so dark outlines and interior shadow pixels stay opaque.

Large single-character sheets are written as `<character>/pose/raw_<character>_pose_frame_###.png` and mirrored into `<character>/pose_right` plus `<character>/pose_left`.

The combined combat atlas is written twice: once as `combat_atlas/frames` and once grouped into `<monster>/atlas_frames` folders for easier sandbox browsing.

Atlas monsters also get `atlas_frames_right` and mirrored `atlas_frames_left` folders, so combat can pick facing-specific sprites without runtime flipping.

Regenerate with:

```powershell
.\tools\characters\extract_raw_combat_characters.ps1
```