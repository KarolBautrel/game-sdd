-- Reproducible separation of original imagegen production plates in Aseprite.
local root=assert(app.params['root'],'root required')
local path=function(p) return app.fs.joinPath(root,p) end
local output=(app.params['out'] or 'assets/ui/dungeon/ashen')..'/'
local sources=(app.params['sources'] or 'assets_src/aseprite/dungeon_ui/ashen')..'/'
local raw=app.params['raw'] or 'assets_src/ashen_ui/2026-11-04/raw'
local references=app.params['references'] or 'docs/design/exploration-archetypes/2026-11-04'
local portraits=app.params['portraits'] or 'assets/ui/portraits'
local manifest=app.params['manifest'] or 'assets_src/ashen_ui/2026-11-04/components.json'
app.fs.makeAllDirectories(path(output..'mine'))
app.fs.makeAllDirectories(path(sources))
local records={}
local function load(name)
  local sprite=app.open(path(raw..'/'..name..'.png'))
  local image=Image(sprite.spec)
  image:drawSprite(sprite,1)
  sprite:saveAs(path(sources..name..'-plate.aseprite'))
  sprite:close()
  return image
end
local function inside(x,y,polygon)
  local hit=false;local j=#polygon
  for i=1,#polygon do
    local a,b=polygon[i],polygon[j]
    if ((a[2]>y)~=(b[2]>y)) and x<(b[1]-a[1])*(y-a[2])/(b[2]-a[2])+a[1] then hit=not hit end
    j=i
  end
  return hit
end
local function export(source,name,rect,trim,polygon)
  local image=Image(rect[3],rect[4],ColorMode.RGB)
  image:drawImage(source,Point(-rect[1],-rect[2]))
  if polygon then
    for y=0,image.height-1 do for x=0,image.width-1 do
      if not inside(x+.5,y+.5,polygon) then image:putPixel(x,y,0) end
    end end
  end
  if name=='portrait-bran' or name=='portrait-torin' then
    local cx,cy=image.width*.5,image.height*.5
    local radius=math.min(image.width,image.height)*.425
    for y=0,image.height-1 do for x=0,image.width-1 do
      if (x+.5-cx)^2+(y+.5-cy)^2>radius^2 then image:putPixel(x,y,0) end
    end end
  end
  local minx,miny,maxx,maxy=image.width,image.height,-1,-1
  local transparent,opaque=0,0
  for it in image:pixels() do
    local a=app.pixelColor.rgbaA(it())
    if a<10 then transparent=transparent+1 end
    if a>240 then opaque=opaque+1 end
    if a>4 then minx=math.min(minx,it.x);miny=math.min(miny,it.y);maxx=math.max(maxx,it.x);maxy=math.max(maxy,it.y) end
  end
  if trim then
    assert(transparent>100 and opaque>100,'Real alpha required for '..name)
    local cropped=Image(maxx-minx+1,maxy-miny+1,ColorMode.RGB)
    cropped:drawImage(image,Point(-minx,-miny));image=cropped
  end
  local sprite=Sprite(image.width,image.height,ColorMode.RGB)
  sprite.layers[1].name=name;sprite.cels[1].image=image
  local target=name:gsub('/','-')
  sprite:saveAs(path(sources..target..'.aseprite'))
  sprite:saveCopyAs(path(output..name..'.png'));sprite:close()
  records[#records+1]={name=name,width=image.width,height=image.height,transparent=transparent,opaque=opaque,source_rect=rect}
end
local shell=load('shared-shell')
export(shell,'header',{0,0,1672,100})
export(shell,'company',{8,778,1656,163})
export(shell,'paper',{1240,240,380,340})
export(shell,'title-plaque',{1250,133,378,82},false,{{0,18},{18,0},{360,0},{378,18},{378,64},{360,82},{18,82},{0,64}})
export(shell,'button-primary',{1254,600,376,79},false,{{0,18},{20,0},{354,0},{376,18},{376,60},{355,79},{18,79},{0,60}})
export(shell,'button-secondary',{1308,689,270,58},false,{{0,12},{12,0},{258,0},{270,12},{270,46},{258,58},{12,58},{0,46}})
export(shell,'button-return',{1448,14,216,54},false,{{0,20},{18,0},{198,0},{216,20},{216,38},{198,54},{18,54},{0,38}})
local map=load('map-paper-v2')
export(map,'map-paper',{0,0,map.width,map.height})
local inspector=load('inspector-v2')
inspector:resize(456,680)
export(inspector,'inspector',{0,0,456,680})
local rooms=load('mine-vignettes-alpha')
local roomnames={'entrance','crossing','treasure','spider','guarded_treasure','exit','locked'}
for i,name in ipairs(roomnames) do
  local col=(i-1)%4;local row=math.floor((i-1)/4)
  local x,y=math.floor(col*rooms.width/4),math.floor(row*rooms.height/2)
  local right,bottom=math.floor((col+1)*rooms.width/4),math.floor((row+1)*rooms.height/2)
  export(rooms,'mine/'..name,{x,y,right-x,bottom-y},true)
end
local widgets=load('widgets')
local names={'label-slip','selection','seal-mine','portrait-ring','current-pin','lock','state-swash','light'}
for i,name in ipairs(names) do
  local col=(i-1)%4;local row=math.floor((i-1)/4)
  local x,y=math.floor(col*widgets.width/4),math.floor(row*widgets.height/2)
  local right,bottom=math.floor((col+1)*widgets.width/4),math.floor((row+1)*widgets.height/2)
  local rect={x,y,right-x,bottom-y}
  if name=='lock' then rect={520,480,220,330} end
  if name=='state-swash' then rect={790,590,560,190} end
  export(widgets,name,rect,true)
end
for _,theme in ipairs({'dungeon','castle','forest'}) do
  app.fs.makeAllDirectories(path(output..theme))
  local atlas=load(theme..'-vignettes')
  local paper=load(theme..'-paper')
  export(paper,theme..'/map-paper',{0,0,paper.width,paper.height})
  for i,name in ipairs(roomnames) do
    local col=(i-1)%4;local row=math.floor((i-1)/4)
    local x,y=math.floor(col*atlas.width/4),math.floor(row*atlas.height/2)
    local right,bottom=math.floor((col+1)*atlas.width/4),math.floor((row+1)*atlas.height/2)
    export(atlas,theme..'/'..name,{x,y,right-x,bottom-y},true)
  end
  local concept=app.open(path(references..'/'..theme..'.png'))
  local image=Image(concept.spec);image:drawSprite(concept,1);concept:close()
  export(image,'seal-'..theme,{1210,89,112,151},false,{{48,0},{16,8},{5,30},{0,55},{8,78},{23,91},{24,145},{40,131},{51,146},{65,116},{70,91},{90,82},{99,60},{97,34},{87,15},{66,3}})
end
local reference=app.open(path(references..'/mine.png'))
local original=Image(reference.spec);original:drawSprite(reference,1);reference:close()
for _,entry in ipairs({{'torch',589,15,35,47},{'pickaxe',713,17,46,49},{'trap_tools',851,17,50,46},{'bandage',992,15,48,48},{'camping_kit',1140,17,49,49},{'food',1290,17,49,46}}) do
  export(original,'supply-'..entry[1],{entry[2],entry[3],entry[4],entry[5]})
end
for _,name in ipairs({'bran','torin'}) do
  local sprite=app.open(path(portraits..'/'..name..'.png'))
  local image=Image(sprite.spec);image:drawSprite(sprite,1);sprite:close()
  export(image,'portrait-'..name,{0,0,image.width,image.height})
end
local file=assert(io.open(path(manifest),'w'))
file:write(json.encode(records));file:close()
print('Exported '..#records..' Ashen components with real alpha; editable Aseprite sources retained.')
