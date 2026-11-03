-- Separate Bran identity variant. Every pixel edit and export is made in Aseprite.
local root=assert(app.params.root)
local base=root..'/assets_src/characters/drawn_animation/2026-11-03/'
local source=root..'/assets_src/characters/hero_identity/bran/'
local pc=app.pixelColor
local W,H=384,320
local function read(p)local f=assert(io.open(p));local d=json.decode(f:read('*a'));f:close();return d end
local function home(id,v)return base..id..(v=='south_east' and '' or '/directions/'..v) end
local config=read(source..'build.json')
local masks=read(source..'head_landmarks.json')
local profile=config.profile
local proof={status='PASS',method=config.provenance,clips={}}
local images={}
local function equal(a,b)
 for it in a:pixels() do assert(it()==b:getPixel(it.x,it.y),'Aseprite source roundtrip differs') end
end
for _,view in ipairs(config.views) do
 images[view]={}
 for _,action in ipairs(config.actions) do
  local final={};local atlas=Image(W*profile.frame_counts[action],H,ColorMode.RGB)
  local sprite=Sprite(W,H,ColorMode.RGB)
  local body=sprite.layers[1];body.name='Approved two-handed body and rigid weapon'
  local head=sprite:newLayer();head.name='Bran native head / recorded placement'
  local info={view=view,action=action,frames={},roundtrip=false}
  for n=0,profile.frame_counts[action]-1 do
   local original=Image{fromFile=string.format(home('knight',view)..'/frames/'..action..'/%03d.png',n)}
   local im=Image(original);local bodyim=Image(original);local headim=Image(W,H,ColorMode.RGB)
   local mirror=({south_west='south_east',west='east',north_west='north_east'})[view]
   local edited=0
   if mirror then
    local other=images[mirror][action][n+1]
    for it in other:pixels() do im:drawPixel(W-1-it.x,it.y,it()) end
    bodyim=Image(im)
   elseif masks[view] then
    local def=masks[view];local mark=def.actions[action][n+1]
    local x,y,angle=mark[1],mark[2],mark[3] or 0
    local ref=Image{fromFile=home('warrior',view)..'/frames/neutral_idle/000.png'}
    local box=def.reference
    local c,s=math.cos(math.rad(angle)),math.sin(math.rad(angle))
    -- Inverse nearest sampling applies to the small head only. Body is never scaled.
    local radius=26
    for yy=math.max(0,y-radius),math.min(H-1,y+radius) do for xx=math.max(0,x-radius),math.min(W-1,x+radius) do
     local dx,dy=xx-x,yy-y
     local sx=math.floor(c*dx+s*dy+box[1]+box[3]/2+.5)
     local sy=math.floor(-s*dx+c*dy+box[2]+box[4]/2+.5)
     local in_box=sx>=box[1] and sx<box[1]+box[3] and sy>=box[2] and sy<box[2]+box[4]
     if in_box then
      local p=ref:getPixel(sx,sy)
      -- Ellipse contains the actual old head; keep the collar/arms below it.
      local lx=(sx-box[1]-box[3]/2)/(box[3]/2)
      local ly=(sy-box[2]-box[4]/2)/(box[4]/2)
      if lx*lx+ly*ly<.9 and sy<box[2]+box[4]-6 then bodyim:drawPixel(xx,yy,0) end
      if pc.rgbaA(p)>0 then headim:drawPixel(xx,yy,p) end
     end
    end end
    -- Occluding raised gauntlet/blade remains in front of the face.
    for _,rect in ipairs(mark[4] or {}) do
     for yy=rect[2],rect[4] do for xx=rect[1],rect[3] do
      headim:drawPixel(xx,yy,0);bodyim:drawPixel(xx,yy,original:getPixel(xx,yy))
     end end
    end
    im=Image(bodyim);im:drawImage(headim,Point(0,0))
    for it in im:pixels() do
     if it()~=original:getPixel(it.x,it.y) then
      assert(math.abs(it.x-x)<=radius and math.abs(it.y-y)<=radius,'Edit escapes head mask')
      edited=edited+1
     end
    end
   end
   if n>0 and (action=='neutral_idle' or action=='combat_idle') then
    for yy=232,H-1 do for xx=0,W-1 do assert(im:getPixel(xx,yy)==final[1]:getPixel(xx,yy),'Idle feet move') end end
   end
   final[n+1]=im
   if n==0 then sprite.cels[1].image=bodyim else sprite:newEmptyFrame();sprite:newCel(body,n+1,bodyim,Point(0,0)) end
   sprite:newCel(head,n+1,headim,Point(0,0))
   sprite.frames[n+1].duration=profile.durations_ms[action][n+1]/1000
   im:saveAs(string.format(source..'greatsword/'..view..'/frames/'..action..'/%03d.png',n))
   im:saveAs(string.format(root..'/assets/combat/characters/identity/bran_greatsword/'..action..'/bran_greatsword_'..view..'_'..action..'_%03d.png',n))
   atlas:drawImage(im,Point(n*W,0))
   info.frames[n+1]={duration_ms=profile.durations_ms[action][n+1],edited_pixels=edited,landmark=(masks[view] and masks[view].actions[action][n+1] or nil),mirror_of=mirror}
  end
  images[view][action]=final
  sprite:newTag(1,#final).name=action
  local path=root..'/assets_src/aseprite/characters/hero_identity/bran_greatsword/'..view..'/'..action..'.aseprite'
  sprite:saveAs(path);sprite:close()
  local opened=assert(app.open(path));assert(#opened.frames==#final and opened.tags[1].name==action)
  for n=1,#final do
   assert(math.abs(opened.frames[n].duration-profile.durations_ms[action][n]/1000)<.001)
   local actual=Image(W,H,ColorMode.RGB);actual:drawSprite(opened,n);equal(actual,final[n])
  end
  opened:close();info.roundtrip=true;proof.clips[#proof.clips+1]=info
  atlas:saveAs(source..'greatsword/'..view..'/'..action..'.png')
 end
end
-- Native comparison board: sword/shield above, same hero/greatsword below.
local board=Image(W*5,H*2,ColorMode.RGB)
for i,v in ipairs({'south_east','south','east','north_east','north'}) do
 board:drawImage(Image{fromFile=home('warrior',v)..'/frames/combat_idle/000.png'},Point((i-1)*W,0))
 board:drawImage(images[v].combat_idle[1],Point((i-1)*W,H))
end
board:saveAs(source..'comparison.png')
local weapon=Image{fromFile=base..'weapon_library/props/two_handed_sword.png'}
local icon=Image(96,96,ColorMode.RGB)
local c,s=math.cos(math.rad(45)),math.sin(math.rad(45))
for yy=0,95 do for xx=0,95 do
 local dx,dy=(xx-48)/.85,(yy-48)/.85
 local sx=math.floor(c*dx+s*dy+weapon.width/2+.5)
 local sy=math.floor(-s*dx+c*dy+weapon.height/2+.5)
 if sx>=0 and sy>=0 and sx<weapon.width and sy<weapon.height then icon:drawPixel(xx,yy,weapon:getPixel(sx,sy)) end
end end
icon:saveAs(root..'/assets/ui/campaign/items/hero_greatsword.png')
local item=Sprite(96,96,ColorMode.RGB);item.layers[1].name='Rigid greatsword master';item.cels[1].image=icon
item:saveAs(root..'/assets_src/aseprite/ui/items/hero_greatsword.aseprite');item:close()
local f=assert(io.open(source..'source_proof.json','w'));f:write(json.encode(proof));f:close()
print('BRAN_IDENTITY_SOURCE_PASS 56 layered sources reopened; heads only; planted idle feet')
