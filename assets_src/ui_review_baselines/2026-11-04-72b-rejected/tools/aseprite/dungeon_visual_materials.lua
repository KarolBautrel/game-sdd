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

-- Preserve brass corners, with constant rail cross-sections and matte infill.
-- Every stretched strip is uniform along its stretching axis: no grain or
-- rivet can turn into a magnified streak when a panel becomes tall/wide.
for _,name in ipairs({"frame_dark","button"}) do
  app.command.OpenFile{filename=path("assets/ui/campaign/"..name..".png"),oneframe=true,ui=false}
  local frame = app.activeSprite
  local pixels = frame.cels[1].image
  local original = pixels:clone()
  local border = name=="button" and 16 or 36
  local base = name=="button" and 28 or 21
  for y=0,pixels.height-1 do
    for x=0,pixels.width-1 do
      local middle_x = x>=border and x<pixels.width-border
      local middle_y = y>=border and y<pixels.height-border
      local sx = middle_x and math.floor(pixels.width*.30) or x
      local sy = middle_y and math.floor(pixels.height*.33) or y
      local p = original:getPixel(sx,sy)
      local r,g,b = app.pixelColor.rgbaR(p),app.pixelColor.rgbaG(p),app.pixelColor.rgbaB(p)
      -- Neutral dark grain becomes matte; warm metal and its shading survive.
      local metal = math.max(0,math.min(1,(r-g)/7,(g-b)/7,(r-18)/30))
      if middle_x and middle_y then metal=0 end
      pixels:putPixel(x,y,app.pixelColor.rgba(
        math.floor(r*metal+base*(1-metal)),
        math.floor(g*metal+(base-1)*(1-metal)),
        math.floor(b*metal+(base-3)*(1-metal)),app.pixelColor.rgbaA(p)))
    end
  end
  frame:saveAs(path("assets_src/aseprite/dungeon_ui/"..name..".aseprite"))
  frame:saveCopyAs(path("assets/ui/dungeon/materials/"..name..".png"))
  frame:close()
end
