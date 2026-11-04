-- Keep the approved campaign hide at source resolution; never tile the export.
local root = app.params["root"]
assert(root and #root > 0, "root required")
local path = function(p) return app.fs.joinPath(root,p) end
app.command.OpenFile{filename=path("assets_src/campaign_ui/materials-source.png"),oneframe=true,ui=false}
local source = app.activeSprite
app.command.ChangePixelFormat{format="rgb"}
local image = source.cels[1].image
local w,h = math.floor(source.width*.43),math.floor(source.height*.43)
local hide = Image(w,h,ColorMode.RGB)
hide:drawImage(image,Point(-math.floor(source.width*.03),-math.floor(source.height*.54)))
local sprite = Sprite(w,h,ColorMode.RGB)
sprite.cels[1].image = hide
app.fs.makeAllDirectories(path("assets_src/aseprite/dungeon_ui"))
app.fs.makeAllDirectories(path("assets/ui/dungeon/materials"))
sprite:saveAs(path("assets_src/aseprite/dungeon_ui/campaign_hide.aseprite"))
sprite:saveCopyAs(path("assets/ui/dungeon/materials/campaign_hide.png"))
sprite:close()
source:close()
print("Exported dungeon campaign hide at source resolution: "..w.."x"..h)

-- User-selected temporary baseline72: retain the original textured borders.
-- The flattened72b exporter is archived under assets_src/ui_review_baselines/.
for _,name in ipairs({"frame_dark","button"}) do
  app.command.OpenFile{filename=path("assets/ui/campaign/"..name..".png"),oneframe=true,ui=false}
  local frame = app.activeSprite
  local pixels = frame.cels[1].image
  local border = name=="button" and 16 or 36
  for y=border,pixels.height-border-1 do
    for x=border,pixels.width-border-1 do
      local p = pixels:getPixel(x,y)
      local edge = math.min(x-border,y-border,pixels.width-border-1-x,pixels.height-border-1-y)
      local weight = .96*math.min(1,edge/6)
      local base = name=="button" and 28 or 21
      pixels:putPixel(x,y,app.pixelColor.rgba(
        math.floor(app.pixelColor.rgbaR(p)*(1-weight)+base*weight),
        math.floor(app.pixelColor.rgbaG(p)*(1-weight)+(base-1)*weight),
        math.floor(app.pixelColor.rgbaB(p)*(1-weight)+(base-3)*weight),app.pixelColor.rgbaA(p)))
    end
  end
  frame:saveAs(path("assets_src/aseprite/dungeon_ui/"..name..".aseprite"))
  frame:saveCopyAs(path("assets/ui/dungeon/materials/"..name..".png"))
  frame:close()
end
