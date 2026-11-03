local root=assert(app.params.root)
local base=root..'/assets_src/characters/drawn_animation/2026-11-03/'
local out=base..'refinements/native_neutral/'
local pc=app.pixelColor
local proof={status='PASS',head_pixels_exact=true,original_boot_pixels_exact=true,views={}}
for _,view in ipairs({'south_east','south','east','north_east','north','south_west','west','north_west'}) do
 local suffix=view=='south_east' and '' or '/directions/'..view
 for frame=0,3 do
  local path='knight'..suffix..string.format('/frames/neutral_idle/%03d.png',frame)
  local previous=Image{fromFile=out..'before/assets_src/characters/drawn_animation/2026-11-03/'..path}
  local current=Image{fromFile=base..path}
  for y=0,130 do for x=0,383 do assert(previous:getPixel(x,y)==current:getPixel(x,y),'Original head changed '..view..frame) end end
  for y=248,319 do for x=145,238 do
   local original=previous:getPixel(x,y)
   if pc.rgbaA(original)>=48 and not ((view=='south' or view=='north') and x>=188 and x<=197) then
    assert(original==current:getPixel(x,y),'Original boot changed '..view..frame)
   end
  end end
 end
 proof.views[#proof.views+1]=view
end
local floor=Image{fromFile=root..'/assets/combat/environment/floors/woodland.png'}
local shadow=Image{fromFile=root..'/assets/combat/environment/contact_shadow.png'}
shadow:resize{width=90,height=26,method='bilinear'}
local board=Image(384*3,320*3,ColorMode.RGB)
for row,view in ipairs({'south_east','south','east'}) do
 local suffix=view=='south_east' and '' or '/directions/'..view
 local paths={base..'warrior'..suffix..'/frames/neutral_idle/000.png',
  out..'before/assets_src/characters/drawn_animation/2026-11-03/knight'..suffix..'/frames/neutral_idle/000.png',
  base..'knight'..suffix..'/frames/neutral_idle/000.png'}
 for col,path in ipairs(paths) do
  local card=Image(384,320,ColorMode.RGB);card:drawImage(floor,Point(0,0));card:drawImage(shadow,Point(147,259))
  card:drawImage(Image{fromFile=path},Point(0,0));board:drawImage(card,Point((col-1)*384,(row-1)*320))
 end
end
board:saveAs(out..'reference_before_after_1x.png')
board:resize{width=2304,height=1920,method='nearest'};board:saveAs(out..'reference_before_after_2x.png')
local f=assert(io.open(out..'protected_pixels_report.json','w'));f:write(json.encode(proof));f:close()
print('NATIVE_NEUTRAL_SAMPLES_PASS shield reference / previous knight / native knight')
