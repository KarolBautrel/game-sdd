-- Retiming only: preserve every walk pixel, frame and tag in the editable source.
local root=assert(app.params.root)
local base=root..'/assets_src/characters/drawn_animation/2026-11-03'
local sources=root..'/assets_src/aseprite/characters/drawn_animation/2026-11-03'
local duration_ms=tonumber(app.params.duration_ms or 50)
local stride_pixels=tonumber(app.params.stride_pixels or 80)
local report={status='PASS',duration_ms=duration_ms,cycle_ms=duration_ms*8,stride_pixels=stride_pixels,clips={}}
local function equal(actual,expected,label)
 for it in actual:pixels() do assert(it()==expected:getPixel(it.x,it.y),label) end
end
for _,id in ipairs({'knight','warrior','archer_1','rogue_1','axe_bandit','bandit_spearman'}) do
 for _,view in ipairs({'south_east','south','south_west','east','west','north_east','north_west','north'}) do
  local suffix=id..(view=='south_east' and '' or '/directions/'..view)
  for _,action in ipairs({'neutral_walk','combat_walk'}) do
   local path=sources..'/'..suffix..'/'..action..'.aseprite'
   local sprite=assert(app.open(path));local expected={}
   assert(#sprite.frames==8 and #sprite.tags==1 and sprite.tags[1].name==action,'Walk structure '..suffix..action)
   for n=1,8 do
    expected[n]=Image(384,320,ColorMode.RGB);expected[n]:drawSprite(sprite,n)
    local exported=Image{fromFile=string.format(base..'/'..suffix..'/frames/'..action..'/%03d.png',n-1)}
    equal(expected[n],exported,'Existing walk source/export mismatch '..suffix..action..n)
    sprite.frames[n].duration=duration_ms/1000
   end
   sprite:saveAs(path);sprite:close()
   local reopened=assert(app.open(path))
   assert(#reopened.frames==8 and #reopened.tags==1 and reopened.tags[1].name==action)
   for n=1,8 do
    assert(math.abs(reopened.frames[n].duration-duration_ms/1000)<.0001,'Walk timing did not save')
    local actual=Image(384,320,ColorMode.RGB);actual:drawSprite(reopened,n)
    equal(actual,expected[n],'Retiming changed walk pixels '..suffix..action..n)
   end
   reopened:close()
   report.clips[#report.clips+1]={id=id,view=view,action=action,frames=8,
    duration_ms=duration_ms,cycle_ms=duration_ms*8,source_roundtrip='PASS',pixels_unchanged=true}
  end
 end
 print('DRAWN_WALK_TIMING_ROLE_PASS '..id)
end
assert(#report.clips==96)
local f=assert(io.open(base..'/'..(app.params.report or 'refinements/battle_feedback/walk_timing_report.json'),'w'));f:write(json.encode(report));f:close()
print('DRAWN_WALK_TIMING_PASS 96 clips, 768 frames')
