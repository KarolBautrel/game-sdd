-- Normalize the generated4x4 family into an editable, padded atlas.
local root=assert(app.params['root'],'root required')
local editable=app.fs.joinPath(root,'assets_src/aseprite/region_symbols/region_symbols.aseprite')
local output=app.fs.joinPath(root,'assets/ui/world/region_symbols.png')
app.fs.makeAllDirectories(app.fs.filePath(editable))
app.fs.makeAllDirectories(app.fs.filePath(output))
if app.params['from_editable']=='1' then
  app.command.OpenFile{filename=editable,ui=false}
  app.activeSprite:saveCopyAs(output)
  print('Exported editable region symbols '..app.activeSprite.width..'x'..app.activeSprite.height)
  app.activeSprite:close()
  app.command.OpenFile{filename=app.fs.joinPath(root,'assets_src/aseprite/region_symbols/ground_wash.aseprite'),ui=false}
  app.activeSprite:saveCopyAs(app.fs.joinPath(root,'assets/ui/world/ground_wash.png'))
  app.activeSprite:close()
  return
end
local source=Image{fromFile=app.fs.joinPath(root,'assets_src/region_symbols/2026-11-04/generated-source.png')}
local names={'Conifers','Oaks','Dead trees','Mixed forest','Rolling hills','Brown mountain','Snow peak','Rocky crags','Market town','Harbour town','Dark keep','Ruined abbey','Mine entrance','Dungeon entrance','Bridge NE','Bridge NW'}
local pc=app.pixelColor
local sprite=Sprite(1536,1536,ColorMode.RGB)
sprite.layers[1].name=names[1]
local removed=0
for index,name in ipairs(names) do
  local column=(index-1)%4;local row=math.floor((index-1)/4)
  local x0=math.floor(column*source.width/4);local x1=math.floor((column+1)*source.width/4)
  local y0=math.floor(row*source.height/4);local y1=math.floor((row+1)*source.height/4)
  local image=Image(x1-x0,y1-y0,ColorMode.RGB)
  image:drawImage(source,Point(-x0,-y0))
  local minx,miny,maxx,maxy=image.width,image.height,-1,-1
  for it in image:pixels() do
    local pixel=it();local r,g,b,a=pc.rgbaR(pixel),pc.rgbaG(pixel),pc.rgbaB(pixel),pc.rgbaA(pixel)
    -- Remove saturated red matte residue outside the sepia/olive family.
    if r>180 and g<70 and b<70 and a>0 then a=0;removed=removed+1 end
    local edge=math.min(it.x,it.y,image.width-1-it.x,image.height-1-it.y)
    local fade=math.min(1,math.max(0,edge/7));fade=fade*fade*(3-2*fade)
    a=math.floor(a*fade+.5)
    it(a==0 and 0 or pc.rgba(r,g,b,a))
    if a>=8 then minx=math.min(minx,it.x);maxx=math.max(maxx,it.x);miny=math.min(miny,it.y);maxy=math.max(maxy,it.y) end
  end
  assert(maxx>=minx,'empty symbol '..name)
  local layer=index==1 and sprite.layers[1] or sprite:newLayer()
  layer.name=name
  local at=Point(column*384+math.floor(192-(minx+maxx)/2),row*384+350-maxy)
  if index==1 then sprite.cels[1].image=image;sprite.cels[1].position=at
  else sprite:newCel(layer,1,image,at) end
end
sprite:saveAs(editable)
sprite:saveCopyAs(output)
print('Normalized16 symbols; removed matte pixels='..removed..';1536x1536 with384px cells, pivot192,350')
sprite:close()
app.command.OpenFile{filename=app.fs.joinPath(root,'assets_src/region_symbols/2026-11-04/ground-wash-source.png'),ui=false}
local ground=app.activeSprite
ground.layers[1].name='Continuous engraved ground wash'
ground:saveAs(app.fs.joinPath(root,'assets_src/aseprite/region_symbols/ground_wash.aseprite'))
ground:saveCopyAs(app.fs.joinPath(root,'assets/ui/world/ground_wash.png'))
ground:close()
