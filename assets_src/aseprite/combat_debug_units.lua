local output_dir = app.params["output"]

local function rgba(r, g, b, a)
  return Color{r = r, g = g, b = b, a = a or 255}
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

local function draw_unit(image, ox, palette, pose)
  local bob = 0
  local arm = 0
  local weapon_x = 22
  if pose == "move" then
    bob = -2
  elseif pose == "attack" then
    arm = -3
    weapon_x = 26
  end

  rect(image, ox + 11, 24 + bob, 4, 5, palette.boot)
  rect(image, ox + 17, 24 - bob, 4, 5, palette.boot)
  rect(image, ox + 10, 15 + bob, 12, 10, palette.cloth)
  rect(image, ox + 12, 13 + bob, 8, 5, palette.armor)
  rect(image, ox + 13, 8 + bob, 6, 6, palette.skin)
  rect(image, ox + 12, 6 + bob, 8, 3, palette.hair)
  rect(image, ox + 14, 10 + bob, 1, 1, palette.eye)
  rect(image, ox + 18, 10 + bob, 1, 1, palette.eye)

  rect(image, ox + 7, 16 + bob, 4, 7, palette.skin)
  rect(image, ox + 21, 15 + bob + arm, 4, 7, palette.skin)
  rect(image, ox + weapon_x, 8 + bob + arm, 2, 15, palette.weapon)
  rect(image, ox + weapon_x - 1, 7 + bob + arm, 4, 2, palette.weapon_hi)

  rect(image, ox + 7, 25 + bob, 16, 2, palette.shadow)
end

local function make_sheet(filename, palette)
  local sprite = Sprite(96, 32, ColorMode.RGB)
  sprite.filename = app.fs.joinPath(output_dir, filename)
  local image = Image(96, 32, ColorMode.RGB)
  image:clear(rgba(0, 0, 0, 0))

  draw_unit(image, 0, palette, "idle")
  draw_unit(image, 32, palette, "move")
  draw_unit(image, 64, palette, "attack")

  sprite:newCel(sprite.layers[1], 1, image, Point(0, 0))
  sprite:saveAs(sprite.filename)
  sprite:close()
end

make_sheet("player_warrior_sheet.png", {
  skin = rgba(224, 172, 105),
  hair = rgba(80, 49, 30),
  eye = rgba(20, 28, 35),
  cloth = rgba(46, 110, 190),
  armor = rgba(170, 188, 205),
  boot = rgba(55, 42, 32),
  weapon = rgba(112, 120, 130),
  weapon_hi = rgba(220, 228, 238),
  shadow = rgba(52, 55, 50),
})

make_sheet("enemy_raider_sheet.png", {
  skin = rgba(182, 105, 82),
  hair = rgba(45, 34, 28),
  eye = rgba(15, 18, 20),
  cloth = rgba(164, 58, 49),
  armor = rgba(96, 86, 78),
  boot = rgba(43, 34, 28),
  weapon = rgba(96, 98, 100),
  weapon_hi = rgba(198, 205, 210),
  shadow = rgba(52, 55, 50),
})
