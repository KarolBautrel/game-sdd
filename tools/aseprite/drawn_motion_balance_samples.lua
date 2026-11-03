local root=assert(app.params.root)
local relative='/assets_src/characters/drawn_animation/2026-11-03/'
local base=root..relative;local out=base..'refinements/motion_balance/'
local floor=Image{fromFile=root..'/assets/combat/environment/floors/woodland.png'}
local shadow=Image{fromFile=root..'/assets/combat/environment/contact_shadow.png'}
shadow:resize{width=90,height=26,method='bilinear'}
local pc=app.pixelColor
local proof={status='PASS',combat_feet={}}
local function foot_span(im)
 local lo,hi=384,-1
 for y=248,270 do for x=0,383 do if pc.rgbaA(im:getPixel(x,y))>=128 then lo=math.min(lo,x);hi=math.max(hi,x) end end end
 assert(hi>=lo);return hi-lo+1
end
for _,action in ipairs({'neutral_idle','combat_idle'}) do
 local image=Image(384*4,320,ColorMode.RGB)
 for i,view in ipairs({'south_east','south'}) do
  for j,home in ipairs({out..'before'..relative,base}) do
   local path='knight'..(view=='south_east' and '' or '/directions/'..view)..'/frames/'..action..'/000.png'
   local card=Image(384,320,ColorMode.RGB);card:drawImage(floor,Point(0,0));card:drawImage(shadow,Point(147,259))
   card:drawImage(Image{fromFile=home..path},Point(0,0));image:drawImage(card,Point(((i-1)*2+j-1)*384,0))
  end
 end
 image:saveAs(out..action..'_compare_1x.png')
 image:resize{width=3072,height=640,method='nearest'};image:saveAs(out..action..'_compare_2x.png')
end
for _,view in ipairs({'south_east','south','east','north_east','north'}) do
 local path='knight'..(view=='south_east' and '' or '/directions/'..view)..'/frames/combat_idle/000.png'
 local old=foot_span(Image{fromFile=out..'before'..relative..path})
 local new=foot_span(Image{fromFile=base..path})
 assert(new>old*1.2,'Combat base still too narrow '..view)
 proof.combat_feet[#proof.combat_feet+1]={view=view,before_span_px=old,after_span_px=new}
end
local f=assert(io.open(out..'stance_report.json','w'));f:write(json.encode(proof));f:close()
print('DRAWN_MOTION_STILLS_PASS SE before/after, S before/after')
