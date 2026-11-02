-- Upgrade and independently reopen every editable clip to check saved timing.
local root=assert(app.params.root)
app.fs.makeAllDirectories(root.."/artifacts/roster")
local function read(path) local f=assert(io.open(path,"r"));local value=json.decode(f:read("*a"));f:close();return value end
local data=read(root.."/resources/data/presentation/original_roster.json")
local records={}
for _,profile in ipairs(data.characters) do
 for action,count in pairs(data.frame_counts) do
  for direction,_ in pairs(data.camera.yaw) do
   local path=root.."/assets_src/aseprite/combat/characters/"..profile.id.."/"..action.."_"..direction..".aseprite"
   local sprite=app.open(path)
   assert(#sprite.frames==count,path.." frame count")
   for _,frame in ipairs(sprite.frames) do frame.duration=data.frame_seconds[action] end
   sprite:saveAs(path);sprite:close()
   local saved=app.open(path)
   for _,frame in ipairs(saved.frames) do assert(math.abs(frame.duration-data.frame_seconds[action])<.0005,path.." saved timing") end
   records[#records+1]={id=profile.id,action=action,direction=direction,frames=#saved.frames,seconds=saved.frames[1].duration}
   saved:close()
  end
 end
 print("ROSTER_TIMING_PASS "..profile.id)
end
local f=assert(io.open(root.."/artifacts/roster/timing-check.json","w"));f:write(json.encode{status="PASS",clips=records});f:close()
local stable=assert(io.open(root.."/assets_src/characters/roster/timing-check.json","w"));stable:write(json.encode{status="PASS",clips=records});stable:close()
