-- Repeatable final pixel-asset pipeline. Run with root=<repository>.
local root = app.params["root"]
assert(root and #root > 0, "root required")
local path = function(p) return app.fs.joinPath(root, p) end
local out = path("assets/ui/campaign")
local sources = path("assets_src/aseprite/campaign_ui")
app.fs.makeAllDirectories(out)
app.fs.makeAllDirectories(sources)
app.fs.makeAllDirectories(app.fs.joinPath(out,"items"))
app.fs.makeAllDirectories(app.fs.joinPath(out,"glyphs"))
local function load_image(file)
  app.command.OpenFile{filename=path(file),oneframe=true,ui=false}
  local sprite = app.activeSprite
  app.command.ChangePixelFormat{format="rgb"}
  local image = sprite.cels[1].image:clone()
  sprite:close()
  return image
end
local function crop(image,x,y,w,h)
  local result = Image(math.floor(w),math.floor(h),ColorMode.RGB)
  result:drawImage(image,Point(-math.floor(x),-math.floor(y)))
  return result
end
local function resize(image,w,h)
  local result = Image(w,h,ColorMode.RGB)
  for y=0,h-1 do
    for x=0,w-1 do
      result:putPixel(x,y,image:getPixel(math.min(image.width-1,math.floor(x*image.width/w)),math.min(image.height-1,math.floor(y*image.height/h))))
    end
  end
  return result
end
local function save(image,name)
  local sprite = Sprite(image.width,image.height,ColorMode.RGB)
  sprite.cels[1].image = image
  sprite:saveAs(app.fs.joinPath(sources,name:gsub("/","_")..".aseprite"))
  sprite:saveCopyAs(app.fs.joinPath(out,name..".png"))
  sprite:close()
end
local sheet = load_image("assets_src/campaign_ui/materials-source.png")
local w,h = sheet.width,sheet.height
save(resize(crop(sheet,0,0,w*0.499,h*0.481),256,256),"frame_dark")
save(resize(crop(sheet,w*0.501,0,w*0.499,h*0.481),256,256),"frame_paper")
save(resize(crop(sheet,w*0.505,h*0.487,w*0.49,h*0.501),256,256),"frame_metal")
-- Scale corner art down, then compose a short button without squashing corners.
local metal = resize(crop(sheet,w*0.505,h*0.487,w*0.49,h*0.501),128,128)
local button = Image(128,64,ColorMode.RGB)
for y=0,63 do for x=0,127 do
  local source_y = y < 16 and y or (y >= 48 and 112+y-48 or 16+math.floor((y-16)*96/32))
  button:putPixel(x,y,metal:getPixel(x,source_y))
end end
save(button,"button")
save(resize(crop(sheet,w*0.03,h*0.54,w*0.43,h*0.43),256,256),"leather")
local map = load_image("assets_src/campaign_ui/marches-map-source.png")
save(resize(map,1280,720),"marches_map")
save(resize(crop(map,map.width*0.04,map.height*0.12,map.width*0.40,map.height*0.40),768,432),"ravenford")
local icons = load_image("assets_src/campaign_ui/items-source.png")
local names = {"hero_sword","hero_bow","salvaged_blade","salvaged_shield","patched_leather","rusty_key","generated_old_mine_trinket","amber_idol_chip","bent_mining_token","brass_route_marker","generated_old_mine_relic","old_mine_blade","old_mine_scrip","old_mine_trinket","sealed_oil_twist","legacy_unknown"}
for index,name in ipairs(names) do
  local column,row = (index-1)%4,math.floor((index-1)/4)
  local image = crop(icons,column*icons.width/4,row*icons.height/4,math.floor(icons.width/4),math.floor(icons.height/4))
  save(resize(image,96,96),"items/"..name)
end
local original = load_image("assets_src/vendor/shikashi_fantasy_icons/Shikashi's Fantasy Icons Pack v2/#1 - Transparent Icons.png")
local glyphs = {heart={0,1},food={13,14},bandage={15,9},coin={7,12},tent={3,4},hammer={4,10},book={7,4},oil={10,10},pickaxe={2,10},trap={14,10}}
for name,cell in pairs(glyphs) do
  local image = crop(original,cell[1]*32,cell[2]*32,32,32)
  -- Muted warm palette; original alpha and readable silhouette are retained.
  for y=0,31 do for x=0,31 do
    local pixel = image:getPixel(x,y)
    local r,g,b,a = app.pixelColor.rgbaR(pixel),app.pixelColor.rgbaG(pixel),app.pixelColor.rgbaB(pixel),app.pixelColor.rgbaA(pixel)
    local l = (r*0.28+g*0.59+b*0.13)
    image:putPixel(x,y,app.pixelColor.rgba(math.min(255,math.floor((r*0.45+l*0.55)*1.04)),math.floor(g*0.45+l*0.55),math.floor((b*0.45+l*0.55)*0.88),a))
  end end
  save(image,"glyphs/"..name)
end
local divider = load_image("assets_src/vendor/kenney_fantasy_ui_borders/PNG/Default/Divider/divider-001.png")
for y=0,divider.height-1 do for x=0,divider.width-1 do
  local pixel=divider:getPixel(x,y)
  divider:putPixel(x,y,app.pixelColor.rgba(177,139,75,app.pixelColor.rgbaA(pixel)))
end end
save(divider,"divider")
local slot = load_image("assets_src/vendor/kenney_pixel_ui_pack/9-Slice/Ancient/brown_inlay.png")
save(slot,"slot")
app.fs.makeAllDirectories(app.fs.joinPath(out,"rooms"))
local rooms = load_image("assets_src/campaign_ui/rooms-source.png")
local room_names = {"entrance","tunnel","treasure","spider","exit","locked","shrine","guarded_treasure"}
for index,name in ipairs(room_names) do
  local column,row = (index-1)%4,math.floor((index-1)/4)
  save(resize(crop(rooms,column*rooms.width/4,row*rooms.height/2,rooms.width/4,rooms.height/2),160,120),"rooms/"..name)
end
print("Exported campaign art, sixteen item icons, ten glyphs and eight dungeon vignettes through Aseprite.")
