local output = app.params["output"]
local source = app.params["source"]

if output == nil or output == "" then
  error("missing output path")
end

if source == nil or source == "" then
  error("missing source path")
end

local tile = 76
local columns = 6
local sprite = Sprite(tile * columns, tile, ColorMode.RGB)
sprite.filename = source

local function rgba(r, g, b, a)
  return Color{r = r, g = g, b = b, a = a or 255}
end

local palette = {
  outline = rgba(25, 23, 18),
  deep_shadow = rgba(29, 24, 20),
  contact_shadow = rgba(34, 28, 22, 190),
  ground_dark = rgba(61, 68, 46),
  ground_mid = rgba(91, 103, 63),
  ground_light = rgba(126, 128, 78),
  dirt = rgba(118, 90, 58),
  dirt_dark = rgba(82, 61, 43),
  grass_dark = rgba(35, 73, 40),
  grass_mid = rgba(61, 113, 54),
  grass_light = rgba(126, 158, 78),
  rock_dark = rgba(39, 41, 43),
  rock_mid = rgba(70, 72, 70),
  rock_light = rgba(118, 113, 98),
  rock_cold = rgba(54, 60, 64),
  stone_dark = rgba(78, 55, 38),
  stone_mid = rgba(147, 111, 60),
  stone_light = rgba(213, 178, 94),
  bark_dark = rgba(57, 34, 24),
  bark_mid = rgba(105, 66, 36),
  bark_light = rgba(166, 105, 53),
  leaf_dark = rgba(23, 58, 31),
  leaf_mid = rgba(49, 105, 48),
  leaf_light = rgba(125, 160, 76),
}

local function seed_noise(x, y, salt)
  local n = (x * 1103515245 + y * 12345 + salt * 2654435761) % 4294967296
  n = (n ~ (n >> 13)) % 4294967296
  return n % 100
end

local function put(image, x, y, color)
  if x >= 0 and x < image.width and y >= 0 and y < image.height then
    image:drawPixel(x, y, color)
  end
end

local function rect(image, x, y, w, h, color)
  for py = y, y + h - 1 do
    for px = x, x + w - 1 do
      put(image, px, py, color)
    end
  end
end

local function line(image, x0, y0, x1, y1, color, thickness)
  thickness = thickness or 1
  local dx = math.abs(x1 - x0)
  local sx = x0 < x1 and 1 or -1
  local dy = -math.abs(y1 - y0)
  local sy = y0 < y1 and 1 or -1
  local err = dx + dy
  local x = x0
  local y = y0
  while true do
    local r = math.floor(thickness / 2)
    for oy = -r, r do
      for ox = -r, r do
        put(image, x + ox, y + oy, color)
      end
    end
    if x == x1 and y == y1 then break end
    local e2 = 2 * err
    if e2 >= dy then
      err = err + dy
      x = x + sx
    end
    if e2 <= dx then
      err = err + dx
      y = y + sy
    end
  end
end

local function ellipse(image, cx, cy, rx, ry, color)
  for y = cy - ry, cy + ry do
    for x = cx - rx, cx + rx do
      local nx = (x - cx) / math.max(rx, 1)
      local ny = (y - cy) / math.max(ry, 1)
      if nx * nx + ny * ny <= 1 then
        put(image, x, y, color)
      end
    end
  end
end

local function polygon(image, points, color)
  local min_y = points[1][2]
  local max_y = points[1][2]
  for _, p in ipairs(points) do
    min_y = math.min(min_y, p[2])
    max_y = math.max(max_y, p[2])
  end
  for y = min_y, max_y do
    local xs = {}
    for i = 1, #points do
      local a = points[i]
      local b = points[(i % #points) + 1]
      if a[2] ~= b[2] and y >= math.min(a[2], b[2]) and y < math.max(a[2], b[2]) then
        local t = (y - a[2]) / (b[2] - a[2])
        table.insert(xs, a[1] + (b[1] - a[1]) * t)
      end
    end
    table.sort(xs)
    for i = 1, #xs, 2 do
      local x0 = math.ceil(xs[i])
      local x1 = math.floor(xs[i + 1] or xs[i])
      for x = x0, x1 do
        put(image, x, y, color)
      end
    end
  end
end

sprite.layers[1].name = "combat_terrain_tiles"
local final = sprite.cels[1].image

local ground = final
local shadows = final
local forms = final
local highlights = final
local details = final

local function ox(index)
  return index * tile
end

local function draw_ground_tile(index, salt, green_bias)
  local base_x = ox(index)
  for y = 0, tile - 1 do
    local depth = y / (tile - 1)
    for x = 0, tile - 1 do
      local n = seed_noise(x // 3, y // 3, salt)
      local color = palette.ground_mid
      if n < 24 then color = palette.ground_dark end
      if n > 72 then color = palette.dirt end
      if green_bias and n > 44 and n < 66 then color = palette.grass_mid end
      if depth > 0.72 and n < 60 then color = palette.dirt_dark end
      put(ground, base_x + x, y, color)
    end
  end

  polygon(shadows, {
    {base_x + 7, 57}, {base_x + 38, 70}, {base_x + 69, 57}, {base_x + 65, 71}, {base_x + 11, 71},
  }, rgba(24, 20, 16, 70))

  for i = 0, 24 do
    local x = base_x + 6 + ((i * 17 + salt) % 64)
    local y = 14 + ((i * 23 + salt) % 50)
    line(details, x, y, x + ((i % 3) - 1), y - 3 - (i % 2), i % 4 == 0 and palette.grass_light or palette.grass_dark)
  end

  line(details, base_x + 8, 58, base_x + 38, 70, palette.outline)
  line(details, base_x + 38, 70, base_x + 68, 58, palette.outline)
end

local function draw_floor(index)
  draw_ground_tile(index, 11, true)
  local base_x = ox(index)
  for i = 0, 10 do
    local x = base_x + 10 + ((i * 13) % 55)
    local y = 18 + ((i * 19) % 42)
    rect(details, x, y, 2, 1, i % 2 == 0 and palette.ground_light or palette.dirt)
  end
end

local function draw_boulder(index)
  draw_ground_tile(index, 23, false)
  local base_x = ox(index)
  ellipse(shadows, base_x + 39, 62, 28, 8, palette.contact_shadow)
  polygon(forms, {{base_x+18,39},{base_x+26,20},{base_x+43,14},{base_x+61,25},{base_x+67,47},{base_x+55,62},{base_x+29,61}}, palette.rock_mid)
  polygon(forms, {{base_x+18,39},{base_x+26,20},{base_x+39,30},{base_x+35,61},{base_x+29,61}}, palette.rock_dark)
  polygon(forms, {{base_x+43,14},{base_x+61,25},{base_x+67,47},{base_x+52,43},{base_x+39,30}}, palette.rock_cold)
  polygon(forms, {{base_x+29,61},{base_x+35,41},{base_x+52,43},{base_x+55,62}}, rgba(31, 33, 35))
  polygon(highlights, {{base_x+27,26},{base_x+39,20},{base_x+48,27},{base_x+38,33}}, palette.rock_light)
  polygon(highlights, {{base_x+46,31},{base_x+58,30},{base_x+61,43},{base_x+50,42}}, rgba(86, 86, 82))
  line(details, base_x+23, 43, base_x+36, 39, palette.rock_light)
  line(details, base_x+37, 32, base_x+52, 43, palette.outline)
  line(details, base_x+48, 20, base_x+58, 29, rgba(142, 136, 119))
  line(details, base_x+18, 39, base_x+29, 61, palette.outline)
  line(details, base_x+55, 62, base_x+67, 47, palette.outline)
end

local function draw_highground(index)
  draw_ground_tile(index, 31, false)
  local base_x = ox(index)
  ellipse(shadows, base_x + 39, 62, 31, 8, palette.contact_shadow)
  polygon(forms, {{base_x+10,22},{base_x+64,18},{base_x+70,47},{base_x+38,60},{base_x+7,47}}, palette.stone_mid)
  polygon(forms, {{base_x+7,47},{base_x+38,60},{base_x+38,70},{base_x+8,57}}, palette.stone_dark)
  polygon(forms, {{base_x+38,60},{base_x+70,47},{base_x+67,57},{base_x+38,70}}, rgba(62, 45, 33))
  polygon(highlights, {{base_x+14,25},{base_x+63,22},{base_x+66,30},{base_x+15,33}}, palette.stone_light)
  line(details, base_x+13, 33, base_x+64, 30, rgba(95, 70, 45))
  line(details, base_x+13, 45, base_x+64, 42, rgba(95, 70, 45))
  line(details, base_x+27, 24, base_x+24, 55, rgba(100, 73, 45))
  line(details, base_x+49, 24, base_x+46, 55, rgba(100, 73, 45))
  line(details, base_x+16, 52, base_x+27, 59, rgba(44, 33, 27))
  line(details, base_x+49, 60, base_x+58, 54, rgba(44, 33, 27))
  line(details, base_x+10, 22, base_x+64, 18, rgba(235, 198, 105))
  line(details, base_x+8, 57, base_x+38, 70, palette.outline)
  line(details, base_x+38, 70, base_x+67, 57, palette.outline)
end

local function draw_bush(index)
  draw_ground_tile(index, 43, true)
  local base_x = ox(index)
  ellipse(shadows, base_x + 39, 62, 30, 8, palette.contact_shadow)
  for _, stem in ipairs({22, 34, 48, 57}) do
    line(forms, base_x+stem, 53, base_x+stem-2, 65, palette.bark_dark, 2)
  end
  local blobs = {
    {21,43,15,12,palette.leaf_mid}, {34,34,18,14,rgba(58,125,57)}, {49,37,18,15,rgba(49,112,52)},
    {59,49,13,11,rgba(34,81,39)}, {39,52,21,14,rgba(35,92,43)}
  }
  for _, b in ipairs(blobs) do
    ellipse(forms, base_x+b[1], b[2], b[3], b[4], b[5])
    ellipse(highlights, base_x+b[1]-4, b[2]-4, math.max(3, b[3]//3), math.max(2, b[4]//3), palette.leaf_light)
    ellipse(details, base_x+b[1]+5, b[2]+5, math.max(3, b[3]//3), math.max(2, b[4]//3), palette.leaf_dark)
  end
  for i = 0, 50 do
    local x = base_x + 10 + ((i * 19) % 58)
    local y = 25 + ((i * 29) % 38)
    put(details, x, y, i % 3 == 0 and palette.leaf_light or palette.leaf_dark)
  end
end

local function draw_log(index)
  draw_ground_tile(index, 53, false)
  local base_x = ox(index)
  ellipse(shadows, base_x + 39, 62, 31, 8, palette.contact_shadow)
  polygon(forms, {{base_x+10,42},{base_x+53,29},{base_x+66,38},{base_x+24,55}}, palette.bark_mid)
  polygon(forms, {{base_x+24,55},{base_x+66,38},{base_x+69,48},{base_x+28,66}}, palette.bark_dark)
  polygon(highlights, {{base_x+10,42},{base_x+16,34},{base_x+58,23},{base_x+53,29}}, palette.bark_light)
  ellipse(forms, base_x+15, 44, 8, 10, rgba(118, 78, 45))
  ellipse(details, base_x+15, 44, 4, 6, rgba(58, 38, 29))
  line(details, base_x+17, 39, base_x+57, 28, rgba(184, 124, 64))
  for _, t in ipairs({0.25, 0.48, 0.72}) do
    local x = base_x + math.floor(11 + 48 * t)
    local y = math.floor(42 - 13 * t)
    line(details, x, y, x + 8, y + 8, rgba(48, 31, 23))
  end
end

local function draw_brush_fence(index)
  draw_ground_tile(index, 61, true)
  local base_x = ox(index)
  ellipse(shadows, base_x + 39, 62, 30, 7, palette.contact_shadow)
  for _, stem in ipairs({16, 27, 39, 51, 61}) do
    line(forms, base_x+stem, 47, base_x+stem-2, 63, palette.bark_dark, 2)
  end
  line(forms, base_x+13, 47, base_x+64, 55, palette.bark_mid, 3)
  local blobs = {
    {18,40,11,9,palette.leaf_mid}, {30,43,13,10,rgba(64,126,55)}, {45,43,14,10,rgba(45,103,47)}, {58,48,10,8,rgba(87,137,61)}
  }
  for _, b in ipairs(blobs) do
    ellipse(forms, base_x+b[1], b[2], b[3], b[4], b[5])
    ellipse(highlights, base_x+b[1]-3, b[2]-3, math.max(3,b[3]//3), math.max(2,b[4]//3), palette.leaf_light)
  end
  for i = 0, 34 do
    local x = base_x + 10 + ((i * 11) % 58)
    local y = 32 + ((i * 17) % 25)
    put(details, x, y, i % 2 == 0 and palette.leaf_light or palette.leaf_dark)
  end
end

draw_floor(0)
draw_boulder(1)
draw_highground(2)
draw_bush(3)
draw_log(4)
draw_brush_fence(5)

app.command.SaveFileAs{ filename = source }
app.command.SaveFileCopyAs{ filename = output }
