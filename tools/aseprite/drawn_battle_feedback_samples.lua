local root=assert(app.params.root)
local relative='/assets_src/characters/drawn_animation/2026-11-03/'
local base=root..relative;local out=base..'refinements/battle_feedback/'
local floor=Image{fromFile=root..'/assets/combat/environment/floors/woodland.png'}
local shadow=Image{fromFile=root..'/assets/combat/environment/contact_shadow.png'}
shadow:resize{width=90,height=26,method='bilinear'}
local pc=app.pixelColor
local proof={status='PASS',views={}}
local function foot_separation(im)
 local groups={};local current=nil
 for x=125,250 do
  local count=0
  for y=250,270 do if pc.rgbaA(im:getPixel(x,y))>=128 then count=count+1 end end
  if count>=2 then
   if not current then current={x0=x,x1=x,count=0};groups[#groups+1]=current end
   current.x1=x;current.count=current.count+count
  else current=nil end
 end
 table.sort(groups,function(a,b)return a.count>b.count end)
 assert(#groups>=2,'Missing distinct boots')
 return math.abs((groups[1].x0+groups[1].x1-groups[2].x0-groups[2].x1)/2)
end
local function exposed_blade_pixels(im)
 local count=0
 for y=110,155 do for x=244,275 do if pc.rgbaA(im:getPixel(x,y))>=128 then count=count+1 end end end
 return count
end
for _,action in ipairs({'neutral_idle','combat_idle'}) do
 local im=Image(768,320,ColorMode.RGB)
 local path='warrior/directions/north/frames/'..action..'/000.png'
 local measures={}
 for i,home in ipairs({out..'before'..relative,base}) do
  local sprite=Image{fromFile=home..path}
  measures[i]={foot_centres_apart_px=foot_separation(sprite),exposed_side_blade_pixels=exposed_blade_pixels(sprite)}
  local card=Image(384,320,ColorMode.RGB)
  card:drawImage(floor,Point(0,0));card:drawImage(shadow,Point(147,259))
  card:drawImage(sprite,Point(0,0));im:drawImage(card,Point((i-1)*384,0))
 end
 im:saveAs(out..action..'_compare_1x.png')
 im:resize{width=1536,height=640,method='nearest'};im:saveAs(out..action..'_compare_2x.png')
 assert(measures[2].foot_centres_apart_px>=measures[1].foot_centres_apart_px*1.25,'Rear stance insufficiently widened')
 if action=='combat_idle' then assert(measures[2].exposed_side_blade_pixels<measures[1].exposed_side_blade_pixels,'Sword still exposed alongside torso') end
 proof.views[#proof.views+1]={action=action,before=measures[1],after=measures[2]}
end
local f=assert(io.open(out..'rear_pose_report.json','w'));f:write(json.encode(proof));f:close()
print('DRAWN_BATTLE_FEEDBACK_STILLS_PASS left before, right after')
