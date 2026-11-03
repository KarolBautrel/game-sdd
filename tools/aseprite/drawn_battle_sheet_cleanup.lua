-- Preserve the raw imagegen sheet. Remove the two-pose contact before segmentation.
local root=assert(app.params.root)
local base=root..'/assets_src/characters/drawn_animation/2026-11-03/warrior/directions/north/raw/'
local im=Image{fromFile=base..'sequence_rear_stance.png'}
-- Row6 col3's boot touches the next attack drawing's raised sword tip.
-- Two alpha rows separate the drawings without changing their pose or scale.
for y=987,988 do for x=570,610 do im:drawPixel(x,y,0) end end
im:saveAs(base..'sequence_rear_stance_clean.png')
print('DRAWN_BATTLE_SHEET_CLEANUP_PASS')
