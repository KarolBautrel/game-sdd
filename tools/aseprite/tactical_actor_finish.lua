-- New SE/SW batch only: plant idle contacts, author reflection and reopen sources.
local root=assert(app.params.root);local id=assert(app.params.id)
local base=root..'/assets_src/characters/tactical_batch/2026-11-03/'..id
local source=root..'/assets_src/aseprite/characters/tactical_batch/2026-11-03/'..id
local runtime=root..'/assets/combat/characters/tactical/'..id
local pc=app.pixelColor;local W,H,PX,PY=384,320,192,270
local function read(p)local f=assert(io.open(p));local v=json.decode(f:read('*a'));f:close();return v end
local function write(p,v)local f=assert(io.open(p,'w'));f:write(json.encode(v));f:close() end
local cfg=read(base..'/clips_source.json');local manifest=read(base..'/manifest.json')
local lock=cfg.idle_lock_y or 232
local proof={status='PASS',id=id,views={},idle_lock_y=lock,clips={}}
local right={}
for _,clip in ipairs(manifest.clips) do
 local frames={}
 for n=0,clip.frames-1 do
  frames[n+1]=Image{fromFile=string.format(base..'/frames/'..clip.id..'/%03d.png',n)}
 end
 if clip.id=='neutral_idle' or clip.id=='combat_idle' then
  for n,im in ipairs(frames) do
   local x0,x1,y1=W,-1,-1
   for y=PY-18,PY+4 do for x=0,W-1 do
    if pc.rgbaA(im:getPixel(x,y))>=128 then x0=math.min(x0,x);x1=math.max(x1,x);y1=math.max(y1,y) end
   end end
   assert(x1>x0,'Missing idle contacts')
   local fixed=Image(W,H,ColorMode.RGB)
   fixed:drawImage(im,Point(PX-math.floor((x0+x1)/2+.5),PY-y1))
   if n>1 then for y=lock,H-1 do for x=0,W-1 do fixed:drawPixel(x,y,frames[1]:getPixel(x,y)) end end end
   frames[n]=fixed
  end
 end
 right[clip.id]=frames
end
for _,view in ipairs({'south_east','south_west'}) do
 local folder=base..(view=='south_east' and '' or '/directions/'..view)
 local sources=source..'/'..view
 app.fs.makeAllDirectories(folder);app.fs.makeAllDirectories(sources)
 local contact=Image(W*4,H*2,ColorMode.RGB)
 for row,clip in ipairs(manifest.clips) do
  local dir=folder..'/frames/'..clip.id;app.fs.makeAllDirectories(dir);app.fs.makeAllDirectories(runtime..'/'..clip.id)
  local sprite=Sprite(W,H,ColorMode.RGB)
  sprite.layers[1].name=view=='south_east' and 'Painted articulated poses; planted idle paws/feet' or 'Reflection of SE; handedness/costume reflected'
  local atlas=Image(W*clip.frames,H,ColorMode.RGB);local final={};local info={action=clip.id,view=view,frames=clip.frames,roundtrip=false}
  for n,input in ipairs(right[clip.id]) do
   local im=Image(input)
   if view=='south_west' then for it in input:pixels() do im:drawPixel(W-1-it.x,it.y,it()) end end
   local x0,y0,x1,y1,count=W,H,-1,-1,0
   for it in im:pixels() do if pc.rgbaA(it())>=48 then x0=math.min(x0,it.x);y0=math.min(y0,it.y);x1=math.max(x1,it.x);y1=math.max(y1,it.y);count=count+1 end end
   assert(count>1000 and x0>=3 and y0>=3 and x1<W-3 and y1<H-3,'Empty/clipped tactical frame '..id..clip.id..n)
   if n>1 and (clip.id=='neutral_idle' or clip.id=='combat_idle') then
    for y=lock,H-1 do for x=0,W-1 do assert(im:getPixel(x,y)==final[1]:getPixel(x,y),'Idle contact moved') end end
   end
   if n==1 then sprite.cels[1].image=im else sprite:newEmptyFrame();sprite:newCel(sprite.layers[1],n,im,Point(0,0)) end
   sprite.frames[n].duration=clip.durations[n]/1000;final[n]=im
   im:saveAs(string.format(dir..'/%03d.png',n-1))
   im:saveAs(string.format(runtime..'/'..clip.id..'/'..id..'_'..view..'_'..clip.id..'_%03d.png',n-1))
   atlas:drawImage(im,Point((n-1)*W,0))
  end
  sprite:newTag(1,clip.frames).name=clip.id
  local path=sources..'/'..clip.id..'.aseprite';sprite:saveAs(path);sprite:close()
  local opened=assert(app.open(path));assert(#opened.frames==clip.frames and opened.tags[1].name==clip.id)
  for n,expected in ipairs(final) do
   assert(math.abs(opened.frames[n].duration-clip.durations[n]/1000)<.001)
   local actual=Image(W,H,ColorMode.RGB);actual:drawSprite(opened,n)
   for it in actual:pixels() do assert(it()==expected:getPixel(it.x,it.y),'Tactical source reopen differs') end
  end
  opened:close();info.roundtrip=true;proof.clips[#proof.clips+1]=info
  atlas:saveAs(folder..'/'..clip.id..'.png')
  contact:drawImage(final[1],Point(((row-1)%4)*W,math.floor((row-1)/4)*H))
 end
 contact:saveAs(folder..'/contact.png')
 local view_meta=read(base..'/manifest.json');view_meta.view=view;view_meta.exported_views={view}
 view_meta.mirror_of=view=='south_west' and 'south_east' or nil
 view_meta.direction_note=view=='south_west' and 'Disclosed SE reflection; handedness and costume reflected.' or 'Drawn front-right tactical view.'
 view_meta.idle_lock_y=lock
 write(folder..'/manifest.json',view_meta)
 proof.views[#proof.views+1]={id=view,mirror_of=view_meta.mirror_of}
end
write(base..'/source_proof.json',proof)
print('TACTICAL_ACTOR_FINISH_PASS '..id..' '..(#manifest.clips*2)..' source clips')
