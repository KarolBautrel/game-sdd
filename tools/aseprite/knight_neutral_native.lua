-- Native accepted pixels only: no model resampling or generative replacement.
local root=assert(app.params.root)
local base=root..'/assets_src/characters/drawn_animation/2026-11-03/'
local out=base..'refinements/native_neutral/'
local source=root..'/assets_src/aseprite/characters/drawn_animation/2026-11-03/knight'
local pc=app.pixelColor
local W,H=384,320
local report={status='PASS',method='native pose/weapon composition; no body resampling',views={}}
local function home(id,view)return base..id..(view=='south_east' and '' or '/directions/'..view) end
local function read(path)local f=assert(io.open(path));local d=json.decode(f:read('*a'));f:close();return d end
local function sword(im,x,y,scale,angle)
 local master=Image{fromFile=base..'weapon_library/props/two_handed_sword.png'}
 local c,s=math.cos(math.rad(angle)),math.sin(math.rad(angle))
 -- Inverse sample one rigid native weapon around its grip; retain sharp pixels.
 for yy=125,277 do for xx=95,300 do
  local dx,dy=(xx-x)/scale,(yy-y)/scale
  local sx=math.floor(c*dx+s*dy+16+.5);local sy=math.floor(-s*dx+c*dy+101+.5)
  if sx>=0 and sy>=0 and sx<master.width and sy<master.height then
   local p=master:getPixel(sx,sy);if pc.rgbaA(p)>=48 then im:drawPixel(xx,yy,p) end
  end
 end end
end
for _,view in ipairs({'south_east','south','east','north_east','north'}) do
 local target=home('knight',view)
 local before=out..'before/assets_src/characters/drawn_animation/2026-11-03/knight'..(view=='south_east' and '' or '/directions/'..view)
 local atlas=Image(W*4,H,ColorMode.RGB)
 local sprite=Sprite(W,H,ColorMode.RGB);sprite.layers[1].name='Native neutral pose; protected original head and boots'
 local proof={view=view,frames={}}
 local final={}
 for n=0,3 do
  local original=Image{fromFile=string.format(before..'/frames/neutral_idle/%03d.png',n)}
  local im=Image(original)
  local grip,scale={170,191},.82
  if view=='south' then
   local donor=Image{fromFile=string.format(home('warrior',view)..'/frames/neutral_idle/%03d.png',n)}
   for y=198,270 do for x=188,197 do im:drawPixel(x,y,0) end end
   for y=132,218 do for x=136,248 do
    local sx=(x<=192 and x or 384-x)-6
    local p=donor:getPixel(sx,y)
    if y>=204 and sx<169 then p=0 end
    im:drawPixel(x,y,p)
   end end
   for y=131,157 do for x=178,207 do im:drawPixel(x,y,original:getPixel(x,y)) end end
   grip={159,194};scale=.78
  elseif view=='north' then
   local relaxed=Image{fromFile=home('knight',view)..'/frames/draw/000.png'}
   for y=145,215 do for x=153,231 do im:drawPixel(x,y,relaxed:getPixel(x,y)) end end
   for y=218,270 do for x=188,197 do im:drawPixel(x,y,0) end end
   grip={217,192};scale=.70
  elseif view=='east' then grip={189,193};scale=.78
  elseif view=='north_east' then
   -- This restored native pose already carries the sword lowered at its side.
   grip=nil
  end
  if grip then
   local hand=Image(im)
   sword(im,grip[1],grip[2],scale,135)
   -- Fingers remain over the grip instead of the weapon covering the glove.
   for y=grip[2]-6,grip[2]+5 do for x=grip[1]-6,grip[1]+4 do
    local p=hand:getPixel(x,y);if pc.rgbaA(p)>=128 then im:drawPixel(x,y,p) end
   end end
  end
  -- Preserve the complete original face/head and lower boot pixels exactly.
  for y=0,130 do for x=0,W-1 do im:drawPixel(x,y,original:getPixel(x,y)) end end
  for y=248,H-1 do for x=145,238 do
   local p=original:getPixel(x,y)
   if pc.rgbaA(p)>=48 and not ((view=='south' or view=='north') and x>=188 and x<=197) then im:drawPixel(x,y,p) end
  end end
  if n>0 then
   for y=232,H-1 do for x=0,W-1 do im:drawPixel(x,y,final[1]:getPixel(x,y)) end end
  end
  final[n+1]=im
  local x0,y0,x1,y1=W,H,-1,-1;local count=0
  for it in im:pixels() do if pc.rgbaA(it())>=48 then
   x0=math.min(x0,it.x);y0=math.min(y0,it.y);x1=math.max(x1,it.x);y1=math.max(y1,it.y);count=count+1
  end end
  assert(x0>=3 and x1<W-3 and y0>=3 and y1<H-3,'Native neutral clipping')
  if n==0 then sprite.cels[1].image=im else sprite:newEmptyFrame();sprite:newCel(sprite.layers[1],n+1,im,Point(0,0)) end
  sprite.frames[n+1].duration=.25
  im:saveAs(string.format(target..'/frames/neutral_idle/%03d.png',n));atlas:drawImage(im,Point(n*W,0))
  proof.frames[n+1]={bounds={x0,y0,x1,y1},pixels=count,duration_ms=250,head_original=true,boots_original=true}
 end
 sprite:newTag(1,4).name='neutral_idle'
 local path=source..(view=='south_east' and '' or '/directions/'..view)..'/neutral_idle.aseprite'
 sprite:saveAs(path);sprite:close();atlas:saveAs(target..'/neutral_idle.png')
 local opened=assert(app.open(path));assert(#opened.frames==4 and opened.tags[1].name=='neutral_idle')
 for n=1,4 do
  assert(math.abs(opened.frames[n].duration-.25)<.001)
  local actual=Image(W,H,ColorMode.RGB);actual:drawSprite(opened,n)
  for it in actual:pixels() do assert(it()==final[n]:getPixel(it.x,it.y),'Native neutral source roundtrip') end
 end
 opened:close();proof.source_roundtrip='PASS';report.views[#report.views+1]=proof
end
for _,pair in ipairs({{'south_east','south_west'},{'east','west'},{'north_east','north_west'}}) do
 local from,to=pair[1],pair[2]
 local target=home('knight',to);local atlas=Image(W*4,H,ColorMode.RGB)
 local sprite=Sprite(W,H,ColorMode.RGB);sprite.layers[1].name='Native neutral reflection of '..from
 for n=0,3 do
  local input=Image{fromFile=string.format(home('knight',from)..'/frames/neutral_idle/%03d.png',n)}
  local im=Image(W,H,ColorMode.RGB)
  for it in input:pixels() do im:drawPixel(W-1-it.x,it.y,it()) end
  if n==0 then sprite.cels[1].image=im else sprite:newEmptyFrame();sprite:newCel(sprite.layers[1],n+1,im,Point(0,0)) end
  sprite.frames[n+1].duration=.25
  im:saveAs(string.format(target..'/frames/neutral_idle/%03d.png',n));atlas:drawImage(im,Point(n*W,0))
 end
 sprite:newTag(1,4).name='neutral_idle'
 local path=source..'/directions/'..to..'/neutral_idle.aseprite'
 sprite:saveAs(path);sprite:close();atlas:saveAs(target..'/neutral_idle.png')
 local opened=assert(app.open(path))
 for n=1,4 do
  local actual=Image(W,H,ColorMode.RGB);actual:drawSprite(opened,n)
  local expected=Image{fromFile=string.format(target..'/frames/neutral_idle/%03d.png',n-1)}
  for it in actual:pixels() do assert(it()==expected:getPixel(it.x,it.y),'Native mirror source roundtrip') end
 end
 opened:close();report.views[#report.views+1]={view=to,mirror_of=from,source_roundtrip='PASS'}
end
local f=assert(io.open(out..'neutral_report.json','w'));f:write(json.encode(report));f:close()
print('KNIGHT_NATIVE_NEUTRAL_PASS 5 drawn views, preserved native head/boots')
