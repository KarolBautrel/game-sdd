-- Native-scale static compositions, explicitly not runtime screenshots.
local root=assert(app.params.root);local base=root..'/assets_src/characters/drawn_animation/2026-11-03'
local source=root..'/assets_src/aseprite/characters/drawn_animation/2026-11-03'
local ids={'knight','warrior','archer_1','rogue_1','axe_bandit','bandit_spearman'}
local floor=Image{fromFile=root..'/assets/combat/environment/floors/woodland.png'}
local shadow=Image{fromFile=root..'/assets/combat/environment/contact_shadow.png'}
shadow:resize{width=90,height=26,method='bilinear'}
for _,action in ipairs({'neutral_idle','attack'}) do
 local sprite=Sprite(1152,640,ColorMode.RGB);sprite.layers[1].name='Actual woodland texture at native scale'
 local ground=Image(1152,640,ColorMode.RGB)
 for y=0,639,floor.height do for x=0,1151,floor.width do ground:drawImage(floor,Point(x,y)) end end
 sprite.cels[1].image=ground
 local shadows=sprite:newLayer();shadows.name='Contact shadows'
 local shade=Image(1152,640,ColorMode.RGB)
 for n,id in ipairs(ids) do
  local x=((n-1)%3)*384;local y=math.floor((n-1)/3)*320
  shade:drawImage(shadow,Point(x+147,y+259))
  local frame=action=='attack' and (id=='archer_1' and 5 or 4) or 0
  local path=string.format(root..'/assets/combat/characters/drawn/'..id..'/'..action..'/'..id..'_south_east_'..action..'_%03d.png',frame)
  local layer=sprite:newLayer();layer.name=id..' / '..action
  sprite:newCel(layer,1,Image{fromFile=path},Point(x,y))
 end
 sprite:newCel(shadows,1,shade,Point(0,0))
 sprite:saveAs(source..'/roster_'..action..'.aseprite')
 local image=Image(sprite.width,sprite.height,ColorMode.RGB);image:drawSprite(sprite,1)
 image:saveAs(base..'/roster_'..action..'_1x.png')
 image:resize{width=2304,height=1280,method='nearest'};image:saveAs(base..'/roster_'..action..'_2x.png')
 sprite:close()
end
print('DRAWN_ROSTER_BOARDS_PASS six actors, two static compositions, native/enlarged')
