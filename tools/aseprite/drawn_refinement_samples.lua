local root=assert(app.params.root)
local relative='/assets_src/characters/drawn_animation/2026-11-03/'
local base=root..relative;local out=base..'refinements/'
local before=out..'before'..relative
local floor=Image{fromFile=root..'/assets/combat/environment/floors/woodland.png'}
local shadow=Image{fromFile=root..'/assets/combat/environment/contact_shadow.png'}
local function pair(name,old,new)
 local im=Image(768,320,ColorMode.RGB)
 for i,path in ipairs({old,new}) do
  local card=Image(384,320,ColorMode.RGB);card:drawImage(floor,Point(0,0))
  local shade=Image(shadow);shade:resize{width=90,height=26,method='bilinear'};card:drawImage(shade,Point(147,259))
  card:drawImage(Image{fromFile=path},Point(0,0));im:drawImage(card,Point((i-1)*384,0))
 end
 im:saveAs(out..name..'_1x.png');im:resize{width=1536,height=640,method='nearest'};im:saveAs(out..name..'_2x.png')
end
local shield='warrior/directions/north_east/frames/combat_idle/000.png'
pair('shield_compare',before..shield,base..shield)
local bow='archer_1/frames/attack/004.png'
pair('bow_compare',before..bow,base..bow)
print('DRAWN_REFINEMENT_STILLS_PASS left before, right after; native and2x')
