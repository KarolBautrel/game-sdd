local root=app.params['root'];assert(root,'root required')
local source=app.fs.joinPath(root,'assets_src/aseprite/equipment')
app.fs.makeAllDirectories(source)
for _,name in ipairs({'leather_boots','steel_boots','leather_cap','closed_helm','weathered_cuirass'}) do
  app.command.OpenFile{filename=app.fs.joinPath(root,'assets_src/equipment-icons/'..name..'.png'),ui=false}
  local sprite=app.activeSprite
  app.command.SpriteSize{ui=false,width=96,height=96,method='nearest'}
  sprite:saveAs(app.fs.joinPath(source,name..'.aseprite'))
  sprite:saveCopyAs(app.fs.joinPath(root,'assets/ui/campaign/items/'..name..'.png'))
  sprite:close()
end
print('EQUIPMENT_ICON_ASEPRITE_PASS')
