-- New plates only; preserve the accepted marches_map and existing campaign art.
local root = assert(app.params['root'], 'root required')
local names = {'world_atlas','blackwood_map','highlands_map','coast_map'}
local source = app.fs.joinPath(root,'assets_src/world_atlas/2026-11-04')
local editable = app.fs.joinPath(root,'assets_src/aseprite/world_atlas')
local output = app.fs.joinPath(root,'assets/ui/campaign')
local from_editable = app.params['from_editable'] == '1'
app.fs.makeAllDirectories(editable)
for _,name in ipairs(names) do
  local input = from_editable and app.fs.joinPath(editable,name..'.aseprite') or app.fs.joinPath(source,name..'-source.png')
  app.command.OpenFile{filename=input,ui=false}
  local sprite = app.activeSprite
  sprite.layers[1].name = 'Engraved terrain and landmarks'
  if not from_editable then sprite:saveAs(app.fs.joinPath(editable,name..'.aseprite')) end
  sprite:saveCopyAs(app.fs.joinPath(output,name..'.png'))
  print(name..': '..sprite.width..'x'..sprite.height)
  sprite:close()
end
