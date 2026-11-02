-- Background normalization; all sprite edits remain editable in Aseprite.
local root=assert(app.params.root)
local ids=assert(app.params.ids)
local pc=app.pixelColor
local directions={"south","south_west","west","north_west","north","north_east","east","south_east"}
local actions={{"pose",4},{"walk",8},{"combat",8},{"hit",4},{"death",8}}
local function read(path) local f=assert(io.open(path,"r"));local value=json.decode(f:read("*a"));f:close();return value end
local timings=read(root.."/resources/data/presentation/original_roster.json").frame_seconds
for id in ids:gmatch("[^,]+") do
 local model=read(root.."/assets_src/characters/roster/"..id.."/model.json")
 assert(not model.preview_only,"Full render required: "..id)
 local W,H=model.canvas_size[1],model.canvas_size[2]
 local base=root.."/artifacts/roster/"..id
 local output=root.."/assets/combat/characters/original/"..id
 local source=root.."/assets_src/aseprite/combat/characters/"..id
 app.fs.makeAllDirectories(output);app.fs.makeAllDirectories(source)
 local report={id=id,frames={},clipped={},editor=app.version}
 local previous={}
 if app.params.directions then
  for _,row in ipairs(read(base.."/aseprite-report.json").frames) do previous[row.name]=row end
 end
 local sheet=Image(W*8,H*5,ColorMode.RGB)
 for row,entry in ipairs(actions) do
  local action,count=entry[1],entry[2]
  app.fs.makeAllDirectories(output.."/"..action)
  for col,direction in ipairs(directions) do
   local selected=not app.params.directions or (","..app.params.directions..","):find(","..direction..",",1,true)
   if selected then
   local sprite=Sprite(W,H,ColorMode.RGB);local layer=sprite.layers[1];layer.name="Original model render"
   for index=0,count-1 do
    local name=string.format("%s_%s_%s_%03d",id,direction,action,index)
    local input=Image{fromFile=base.."/raw/"..action.."/"..name..".png"}
    local image=Image(W,H,ColorMode.RGB)
    local minx,miny,maxx,maxy=W,H,-1,-1
    for y=0,H-1 do for x=0,W-1 do
     local p=input:getPixel(x,y)
     if pc.rgbaA(p)>=96 then
      minx=math.min(minx,x);miny=math.min(miny,y);maxx=math.max(maxx,x);maxy=math.max(maxy,y)
      image:putPixel(x,y,pc.rgba(math.floor(pc.rgbaR(p)/4)*4,math.floor(pc.rgbaG(p)/4)*4,math.floor(pc.rgbaB(p)/4)*4,255))
     end
    end end
    assert(maxx>=minx,"Empty frame: "..name)
    if minx<=1 or miny<=1 or maxx>=W-2 or maxy>=H-2 then report.clipped[#report.clipped+1]=name end
    local final=Image(W,H,ColorMode.RGB)
    for y=math.max(1,miny-1),math.min(H-2,maxy+1) do for x=math.max(1,minx-1),math.min(W-2,maxx+1) do
     if pc.rgbaA(image:getPixel(x,y))==0 and (pc.rgbaA(image:getPixel(x-1,y))>0 or pc.rgbaA(image:getPixel(x+1,y))>0 or pc.rgbaA(image:getPixel(x,y-1))>0 or pc.rgbaA(image:getPixel(x,y+1))>0) then final:putPixel(x,y,pc.rgba(25,21,17,255)) end
    end end
    final:drawImage(image)
    if index==0 then sprite.cels[1].image=final else sprite:newEmptyFrame();sprite:newCel(layer,index+1,final,Point(0,0)) end
    sprite.frames[index+1].duration=timings[action]
    final:saveAs(output.."/"..action.."/"..name..".png")
    report.frames[#report.frames+1]={name=name,bounds={minx,miny,maxx,maxy}}
    if index==(action=="death" and count-1 or math.floor(count/2)) then sheet:drawImage(final,Point((col-1)*W,(row-1)*H)) end
   end
   sprite:newTag(1,count).name=action
   sprite:saveAs(source.."/"..action.."_"..direction..".aseprite");sprite:close()
   else
    for index=0,count-1 do
     local name=string.format("%s_%s_%s_%03d",id,direction,action,index)
     local entry=assert(previous[name],"Missing unchanged normalization: "..name)
     report.frames[#report.frames+1]=entry
     if index==(action=="death" and count-1 or math.floor(count/2)) then
      sheet:drawImage(Image{fromFile=output.."/"..action.."/"..name..".png"},Point((col-1)*W,(row-1)*H))
     end
    end
   end
  end
 end
 local portrait=app.open(base.."/portrait.png")
 portrait:saveAs(source.."/portrait.aseprite");portrait:saveAs(output.."/portrait.png");portrait:close()
 sheet:saveAs(base.."/action-contact.png")
 report.frame_count=#report.frames
 local f=assert(io.open(base.."/aseprite-report.json","w"));f:write(json.encode(report));f:close()
 local stable=assert(io.open(root.."/assets_src/characters/roster/"..id.."/sprite-report.json","w"));stable:write(json.encode(report));stable:close()
 assert(#report.clipped==0,"Clipped frames for "..id..": "..#report.clipped)
 print("ROSTER_ASEPRITE_PASS "..id.." "..#report.frames.." frames")
end
