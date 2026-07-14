local output = app.params["output"]
if output == nil or output == "" then
  error("missing output path")
end

local sprite = Sprite(96, 32, ColorMode.RGB)
local cel = sprite.cels[1]
local image = cel.image

local border = Color{ r=224, g=176, b=72, a=255 }
local shadow = Color{ r=42, g=32, b=28, a=255 }
local fill = Color{ r=82, g=68, b=58, a=255 }
local inset = Color{ r=126, g=96, b=60, a=255 }
local shine = Color{ r=246, g=214, b=112, a=255 }

for y = 0, 31 do
  for x = 0, 95 do
    image:putPixel(x, y, fill)
  end
end

for x = 0, 95 do
  image:putPixel(x, 0, border)
  image:putPixel(x, 1, shine)
  image:putPixel(x, 30, shadow)
  image:putPixel(x, 31, shadow)
end

for y = 0, 31 do
  image:putPixel(0, y, border)
  image:putPixel(1, y, shine)
  image:putPixel(94, y, shadow)
  image:putPixel(95, y, shadow)
end

for x = 4, 91 do
  image:putPixel(x, 5, inset)
  image:putPixel(x, 26, shadow)
end

for y = 5, 26 do
  image:putPixel(4, y, inset)
  image:putPixel(91, y, shadow)
end

app.command.SaveFileAs{ filename=output }
