-- Normalize rendered geometry into editable pixel sprites with one fixed pivot.
local root=app.params.root or app.fs.currentPath
local raw=root.."/artifacts/character-pilot/raw"
local output=root.."/assets/combat/characters/original/ash_raider"
local source=root.."/assets_src/aseprite/combat/characters/ash_raider"
local review=root.."/artifacts/character-pilot"
local directions={"south","south_west","west","north_west","north","north_east","east","south_east"}
local actions={{"pose",4},{"walk",8},{"combat",8},{"hit",4},{"death",8}}
local W,H=448,352
app.fs.makeAllDirectories(output)
app.fs.makeAllDirectories(source)
local pc=app.pixelColor
local reports={}
local clipped={}
local sheet=Image(W*8,H*5,ColorMode.RGB)
local function alpha(p) return pc.rgbaA(p) end
for row,entry in ipairs(actions) do
  local action,count=entry[1],entry[2]
  app.fs.makeAllDirectories(output.."/"..action)
  for col,direction in ipairs(directions) do
    local sprite=Sprite(W,H,ColorMode.RGB)
    local layer=sprite.layers[1]
    layer.name="Original mesh render"
    for index=0,count-1 do
      local name=string.format("ash_raider_%s_%s_%03d",direction,action,index)
      local input=Image{fromFile=raw.."/"..action.."/"..name..".png"}
      local image=Image(W,H,ColorMode.RGB)
      local minx,miny,maxx,maxy=W,H,-1,-1
      for y=0,H-1 do for x=0,W-1 do
        local p=input:getPixel(x,y)
        if alpha(p)>=96 then
          minx=math.min(minx,x);miny=math.min(miny,y);maxx=math.max(maxx,x);maxy=math.max(maxy,y)
          local r=math.floor(pc.rgbaR(p)/8)*8
          local g=math.floor(pc.rgbaG(p)/8)*8
          local b=math.floor(pc.rgbaB(p)/8)*8
          image:putPixel(x,y,pc.rgba(r,g,b,255))
        end
      end end
      if minx<=1 or miny<=1 or maxx>=W-2 or maxy>=H-2 then clipped[#clipped+1]=name end
      -- One-pixel dark contour, generated in the editable pixel-art source.
      local final=Image(W,H,ColorMode.RGB)
      for y=1,H-2 do for x=1,W-2 do
        if alpha(image:getPixel(x,y))==0 and (alpha(image:getPixel(x-1,y))>0 or alpha(image:getPixel(x+1,y))>0 or alpha(image:getPixel(x,y-1))>0 or alpha(image:getPixel(x,y+1))>0) then
          final:putPixel(x,y,pc.rgba(27,21,16,255))
        end
      end end
      final:drawImage(image)
      if index==0 then sprite.cels[1].image=final else
        sprite:newEmptyFrame();sprite:newCel(layer,index+1,final,Point(0,0))
      end
      sprite.frames[index+1].duration=action=="pose" and .18 or .09
      final:saveAs(output.."/"..action.."/"..name..".png")
      reports[#reports+1]={name=name,bounds={minx,miny,maxx,maxy}}
      local sample=action=="death" and count-1 or math.floor(count/2)
      if index==sample then sheet:drawImage(final,Point((col-1)*W,(row-1)*H)) end
    end
    local tag=sprite:newTag(1,count);tag.name=action
    sprite:saveAs(source.."/"..action.."_"..direction..".aseprite")
    if direction=="south_east" then sprite:saveAs(review.."/"..action.."-sampled.gif") end
    sprite:close()
  end
end
sheet:saveAs(review.."/action-contact.png")
local file=io.open(review.."/aseprite-report.json","w")
file:write(json.encode{frame_count=#reports,clipped=clipped,frames=reports,editor=app.version})
file:close()
if #clipped>0 then error("Clipped source frames: "..#clipped.."; inspect aseprite-report.json") end
print("SDD_ASEPRITE_RAIDER_PASS "..#reports.." frames, 40 editable sprites")
