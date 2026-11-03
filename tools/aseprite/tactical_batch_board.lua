local root=assert(app.params.root)
local base=root..'/assets_src/characters/tactical_batch/2026-11-03'
local ids={};for id in (app.params.ids or ''):gmatch('[^,]+') do ids[#ids+1]=id end
local W,H=(#ids+1)*320,640
local board=Image(W,H,ColorMode.RGB)
local ground=Image{fromFile=root..'/assets/combat/environment/floors/earth.png'}
for y=0,H-1,ground.height do for x=0,W-1,ground.width do board:drawImage(ground,Point(x,y)) end end
local shadow=Image{fromFile=root..'/assets/combat/environment/contact_shadow.png'}
shadow:resize{width=90,height=26,method='bilinear'}
for row,view in ipairs({'south_east','south_west'}) do
 local paths={root..'/assets_src/characters/drawn_animation/2026-11-03/warrior'..(view=='south_east' and '' or '/directions/'..view)..'/frames/combat_idle/000.png'}
 for _,id in ipairs(ids) do paths[#paths+1]=base..'/'..id..(view=='south_east' and '' or '/directions/'..view)..'/frames/combat_idle/000.png' end
 for col,path in ipairs(paths) do
  local x,y=(col-1)*320-32,(row-1)*320
  board:drawImage(shadow,Point(x+147,y+259))
  board:drawImage(Image{fromFile=path},Point(x,y))
 end
end
board:saveAs(base..'/comparison.png')
local source=Sprite(W,H,ColorMode.RGB);source.cels[1].image=board;source.layers[1].name='Actual native scale; SE above / reflected SW below; Bran reference first'
source:saveAs(root..'/assets_src/aseprite/characters/tactical_batch/2026-11-03/comparison.aseprite');source:close()
print('TACTICAL_BATCH_BOARD_PASS')
