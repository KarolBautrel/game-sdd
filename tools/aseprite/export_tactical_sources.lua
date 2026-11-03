-- Export the saved edited Aseprite cels as authority; never regenerate raw art.
local root=assert(app.params.root);local id=assert(app.params.id)
local base=root..'/assets_src/characters/tactical_batch/2026-11-03/'..id
local sources=root..'/assets_src/aseprite/characters/tactical_batch/2026-11-03/'..id
local runtime=root..'/assets/combat/characters/tactical/'..id
local function read(p)local f=assert(io.open(p));local d=json.decode(f:read('*a'));f:close();return d end
local function write(p,d)local f=assert(io.open(p,'w'));f:write(json.encode(d));f:close() end
local proof={status='PASS',id=id,authority='saved edited Aseprite cels',clips={},views={}}
local right
for _,side in ipairs({'south_east','south_west'}) do
 local home=base..(side=='south_east' and '' or '/directions/'..side)
 local manifest=read(home..'/manifest.json');local lock=manifest.idle_lock_y
 local contact=Image(384*4,320*2,ColorMode.RGB)
 for index,clip in ipairs(manifest.clips) do
  local sprite=assert(app.open(sources..'/'..side..'/'..clip.id..'.aseprite'))
  assert(sprite.width==384 and sprite.height==320 and #sprite.frames==clip.frames)
  assert(#sprite.tags==1 and sprite.tags[1].name==clip.id)
  local atlas=Image(384*clip.frames,320,ColorMode.RGB);local first
  for n=1,clip.frames do
   local image=Image(384,320,ColorMode.RGB);image:drawSprite(sprite,n)
   if n==1 then first=image elseif clip.id=='neutral_idle' or clip.id=='combat_idle' then
    for y=lock,319 do for x=0,383 do assert(image:getPixel(x,y)==first:getPixel(x,y),'Canonical idle feet/paws must remain planted') end end
   end
   clip.durations[n]=math.floor(sprite.frames[n].duration*1000+.5)
   if side=='south_west' then assert(clip.durations[n]==right.clips[index].durations[n],'Both view timings must agree') end
   local path=string.format(home..'/frames/'..clip.id..'/%03d.png',n-1)
   image:saveAs(path)
   image:saveAs(string.format(runtime..'/'..clip.id..'/'..id..'_'..side..'_'..clip.id..'_%03d.png',n-1))
   local reopened=Image{fromFile=path}
   for it in image:pixels() do assert(it()==reopened:getPixel(it.x,it.y),'PNG/source pixels differ') end
   atlas:drawImage(image,Point((n-1)*384,0))
  end
  sprite:close();atlas:saveAs(home..'/'..clip.id..'.png')
  contact:drawImage(first,Point(((index-1)%4)*384,math.floor((index-1)/4)*320))
  proof.clips[#proof.clips+1]={view=side,action=clip.id,frames=clip.frames,roundtrip=true}
 end
 if side=='south_east' then right=manifest end
 contact:saveAs(home..'/contact.png');write(home..'/manifest.json',manifest)
 proof.views[#proof.views+1]={id=side,mirror_of=side=='south_west' and 'south_east' or nil}
end
proof.idle_lock_y=right.idle_lock_y
write(base..'/source_proof.json',proof)
print('TACTICAL_CANONICAL_EXPORT_PASS '..id)
