local root=assert(app.params.root)
local im=Image{fromFile=root..'/assets_src/characters/drawn_animation/2026-11-03/warrior/directions/north/raw/sequence_rear_stance.png'}
local crop=Image(im,Rectangle(495,950,135,85))
crop:resize{width=540,height=340,method='nearest'}
crop:saveAs(root..'/assets_src/characters/drawn_animation/2026-11-03/refinements/battle_feedback/overlap_probe.png')
print('DRAWN_SHEET_PROBE_PASS')
