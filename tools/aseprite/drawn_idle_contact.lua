-- Register idle drawings at the feet, then retain planted lower shins/boots.
local root=assert(app.params.root)
local base=root..'/assets_src/characters/drawn_animation/2026-11-03'
local source=root..'/assets_src/aseprite/characters/drawn_animation/2026-11-03'
local pc=app.pixelColor
local W,H,PX,PY,LOCK_Y=384,320,192,270,232
local result={status='PASS',lock_y=LOCK_Y,views={}}
local function metrics(im)
 local x0,y0,x1,y1=W,H,-1,-1;local pixels=0
 for it in im:pixels() do if pc.rgbaA(it())>=48 then
  x0=math.min(x0,it.x);y0=math.min(y0,it.y);x1=math.max(x1,it.x);y1=math.max(y1,it.y);pixels=pixels+1
 end end
 assert(x0>=3 and y0>=3 and x1<W-3 and y1<H-3,'Idle clipping')
 return {bounds={x0,y0,x1,y1},pixels=pixels}
end
for _,id in ipairs({'knight','warrior','archer_1','rogue_1','axe_bandit','bandit_spearman'}) do
 for _,view in ipairs({'south_east','south','east','north_east','north'}) do
  local suffix=id..(view=='south_east' and '' or '/directions/'..view)
  local proof={id=id,view=view,clips={}}
  for _,action in ipairs({'neutral_idle','combat_idle'}) do
   local path=source..'/'..suffix..'/'..action..'.aseprite'
   local opened=assert(app.open(path));local frames,durations={},{}
   for n=1,#opened.frames do
    local im=Image(W,H,ColorMode.RGB);im:drawSprite(opened,n)
    frames[n]=im;durations[n]=opened.frames[n].duration
   end
   opened:close()
   local fixed={};local entries={};local atlas=Image(W*#frames,H,ColorMode.RGB)
   for n,im in ipairs(frames) do
    local x0,x1,y1=W,-1,-1
    for y=PY-18,PY+4 do for x=0,W-1 do
     if pc.rgbaA(im:getPixel(x,y))>=128 then x0=math.min(x0,x);x1=math.max(x1,x);y1=math.max(y1,y) end
    end end
    assert(x1>x0,'Missing idle foot contact '..suffix..action)
    local dx=PX-math.floor((x0+x1)/2+.5);local dy=PY-y1
    local target=Image(W,H,ColorMode.RGB);target:drawImage(im,Point(dx,dy))
    if n>1 then
     for y=LOCK_Y,H-1 do for x=0,W-1 do target:drawPixel(x,y,fixed[1]:getPixel(x,y)) end end
    end
    fixed[n]=target
    entries[n]=metrics(target);entries[n].registration={dx,dy};entries[n].duration_ms=math.floor(durations[n]*1000+.5)
    target:saveAs(string.format(base..'/'..suffix..'/frames/'..action..'/%03d.png',n-1))
    atlas:drawImage(target,Point((n-1)*W,0))
   end
   local sprite=Sprite(W,H,ColorMode.RGB);local upper=sprite.layers[1];upper.name='Breathing upper body'
   local feet=sprite:newLayer();feet.name='Planted shins and boots'
   local lower=Image(fixed[1],Rectangle(0,LOCK_Y,W,H-LOCK_Y))
   for n,target in ipairs(fixed) do
    if n>1 then sprite:newEmptyFrame() end
    local top=Image(target,Rectangle(0,0,W,LOCK_Y))
    if n==1 then sprite.cels[1].image=top else sprite:newCel(upper,n,top,Point(0,0)) end
    sprite:newCel(feet,n,lower,Point(0,LOCK_Y));sprite.frames[n].duration=durations[n]
   end
   sprite:newTag(1,#fixed).name=action;sprite:saveAs(path);sprite:close()
   atlas:saveAs(base..'/'..suffix..'/'..action..'.png')
   local check=assert(app.open(path));assert(#check.frames==#fixed and #check.tags==1 and check.tags[1].name==action)
   for n,expected in ipairs(fixed) do
    local actual=Image(W,H,ColorMode.RGB);actual:drawSprite(check,n)
    assert(math.abs(check.frames[n].duration-durations[n])<.001,'Idle source duration')
    for it in actual:pixels() do assert(it()==expected:getPixel(it.x,it.y),'Idle source reopen pixel mismatch') end
   end
   check:close();proof.clips[action]={frames=entries,source_roundtrip='PASS',lower_contact_pixels='EXACT_FRAME_ZERO'}
  end
  local input=assert(io.open(base..'/'..suffix..'/manifest.json'));local manifest=json.decode(input:read('*a'));input:close()
  local count=0;for _ in ipairs(manifest.clips) do count=count+1 end
  local contact=Image(W*4,H*math.ceil(count/4),ColorMode.RGB)
  for i,clip in ipairs(manifest.clips) do
   local im=Image{fromFile=base..'/'..suffix..'/frames/'..clip.id..'/000.png'}
   contact:drawImage(im,Point(((i-1)%4)*W,math.floor((i-1)/4)*H))
  end
  contact:saveAs(base..'/'..suffix..'/contact.png')
  result.views[#result.views+1]=proof
 end
 print('DRAWN_IDLE_CONTACT_ROLE_PASS '..id)
end
local f=assert(io.open(base..'/refinements/idle_contact_report.json','w'));f:write(json.encode(result));f:close()
print('DRAWN_IDLE_CONTACT_PASS 60 clips, 30 drawn views; mirrored views follow')
