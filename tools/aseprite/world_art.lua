-- Final environment crop, edge matching, editable sources and painted ledges.
local root=assert(app.params.root)
local out=root..'/assets/combat/environment'
local src=root..'/assets_src/aseprite/environment'
app.fs.makeAllDirectories(out..'/props');app.fs.makeAllDirectories(out..'/floors')
app.fs.makeAllDirectories(src)
local function rgba(r,g,b,a)return app.pixelColor.rgba(math.floor(r),math.floor(g),math.floor(b),a or 255)end
local function mix(a,b,t)
 return rgba(app.pixelColor.rgbaR(a)*(1-t)+app.pixelColor.rgbaR(b)*t,app.pixelColor.rgbaG(a)*(1-t)+app.pixelColor.rgbaG(b)*t,app.pixelColor.rgbaB(a)*(1-t)+app.pixelColor.rgbaB(b)*t,app.pixelColor.rgbaA(a)*(1-t)+app.pixelColor.rgbaA(b)*t)
end
local function save(image,name)
 local sprite=Sprite(image.width,image.height,ColorMode.RGB);sprite.cels[1].image=image
 sprite:saveAs(src..'/'..name:gsub('/','_')..'.aseprite')
 sprite:saveCopyAs(out..'/'..name..'.png');sprite:close()
end
local input=Image{fromFile=root..'/assets_src/environment/floors-source.png'}
local names={'woodland','earth','flagstone','cave'};local floors={}
for index,name in ipairs(names) do
 local side=math.floor(input.width/2);local image=Image(side,side,ColorMode.RGB)
 image:drawImage(input,Point(-((index-1)%2)*side,-math.floor((index-1)/2)*side));image:resize(512,512)
 -- Blend opposite edges symmetrically, preserving the central painted material.
 local original=image:clone()
 for d=0,19 do for i=0,511 do
  local t=.5*(1-d/20)
  image:putPixel(d,i,mix(original:getPixel(d,i),original:getPixel(511-d,i),t))
  image:putPixel(511-d,i,mix(original:getPixel(511-d,i),original:getPixel(d,i),t))
 end end
 original=image:clone()
 for d=0,19 do for i=0,511 do
  local t=.5*(1-d/20)
  image:putPixel(i,d,mix(original:getPixel(i,d),original:getPixel(i,511-d),t))
  image:putPixel(i,511-d,mix(original:getPixel(i,511-d),original:getPixel(i,d),t))
 end end
 save(image,'floors/'..name);floors[name]=image
end
-- The front face is exactly30px, matching the existing unit elevation offset.
for _,theme in ipairs({'nature','dungeon'}) do
 local image=Image(140,104,ColorMode.RGB)
 local top=floors[theme=='nature' and 'woodland' or 'flagstone']
 for y=0,103 do for x=0,139 do
  local pixel=top:getPixel((x*2)%512,(y*2)%512)
  if y>=74 then
   pixel=mix(floors.cave:getPixel((x*3)%512,((y-74)*3+110)%512),rgba(20,21,20),.23)
   if x%46<2 and y>78 then pixel=mix(pixel,rgba(15,16,15),.55)end
  end
  if y==74 or y==75 then pixel=mix(pixel,rgba(131,127,105),.48)end
  if y>=101 then pixel=mix(pixel,rgba(12,14,12),.65)end
  image:putPixel(x,y,pixel)
 end end
 save(image,'ledge_'..theme)
end
local props={'oak','pine','dead_tree','bush','stump','fallen_log','branches','boulder','rock_cluster','grass','flowers','mushrooms','crate','barrel','chest','coffin','pillar','broken_pillar','arch','wall','rubble','brazier','altar','statue','bones','spike_fence','bone_totem','sacks'}
local result={}
for _,name in ipairs(props) do
 local original=Image{fromFile=root..'/assets_src/environment/props/'..name..'/render.png'}
 local minx,miny,maxx,maxy=512,512,0,0
 for y=0,511 do for x=0,511 do
  if app.pixelColor.rgbaA(original:getPixel(x,y))>16 then minx=math.min(minx,x);miny=math.min(miny,y);maxx=math.max(maxx,x);maxy=math.max(maxy,y)end
 end end
 assert(maxx>minx and maxy>miny,name..' empty render')
 minx=math.max(0,minx-7);miny=math.max(0,miny-7);maxx=math.min(511,maxx+7);maxy=math.min(511,maxy+7)
 maxy=math.min(511,math.max(maxy,430))
 local image=Image(maxx-minx+1,maxy-miny+1,ColorMode.RGB)
 local cx,cy=256-minx,418-miny
 local rx,ry=math.min(70,(maxx-minx)*.4),11
 for y=0,image.height-1 do for x=0,image.width-1 do
  local d=((x-cx)/rx)^2+((y-cy)/ry)^2
  if d<1 then image:putPixel(x,y,rgba(13,15,12,math.floor(100*(1-d)^2)))end
 end end
 image:drawImage(original,Point(-minx,-miny));save(image,'props/'..name)
 result[#result+1]=string.format('"%s":{"path":"res://assets/combat/environment/props/%s.png","size":[%d,%d],"pivot":[%d,%d]}',name,name,image.width,image.height,256-minx,418-miny)
end
local file=assert(io.open(root..'/assets_src/environment/props.json','w'));file:write('{'..table.concat(result,',')..'}\n');file:close()
local shadow=Image(96,28,ColorMode.RGB)
for y=0,27 do for x=0,95 do
 local d=((x-47.5)/47)^2+((y-13.5)/13)^2
 if d<1 then shadow:putPixel(x,y,rgba(10,12,10,math.floor(110*(1-d)^2)))end
end end
save(shadow,'contact_shadow')
print('WORLD_ASEPRITE_PASS '..#props..' props, 4 seamless floors, 2 ledges')
