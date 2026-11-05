# Slice037 — terrain editor

Owner: ../037_terrain_editor.md; domain world/011.

- At1280x720 and1920x1080 the palette/brush, undo/redo, save and feedback fit.
- A pointer drag paints all traversed cells; undo restores exact previous rows,
  redo restores the stroke; right-click samples terrain.
- Probe clicks show the same safe route as the company. Water/peaks fail clearly.
- Save/reload roundtrip and invalid/disconnected-mask refusal are proven on a
  separate QA file, never a player save or the production terrain file.
- Zoom/pan keeps input coordinates aligned with the illustration; overlay can
  be hidden to inspect alignment. Native rendered samples accompany QA report.
