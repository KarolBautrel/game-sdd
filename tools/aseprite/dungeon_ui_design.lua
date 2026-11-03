-- Repeatable design/native map exports. Existing assets are never replaced.
local root=assert(app.params['root'],'root required')
local p=function(s)return app.fs.joinPath(root,s)end
local out=p('docs/design/dungeon-ui/art')
local editable=p('assets_src/aseprite/dungeon_ui_design/2026-11-04')
local runtime=p('assets/ui/dungeon/illustrated')
app.fs.makeAllDirectories(out);app.fs.makeAllDirectories(editable)
app.fs.makeAllDirectories(runtime)
app.command.OpenFile{filename=p('assets_src/dungeon_ui_design/2026-11-04/mine-map-source.png'),oneframe=true,ui=false}
local raw=app.activeSprite
app.command.ChangePixelFormat{format='rgb'}
local image=raw.cels[1].image:clone();raw:close()
local function crop(src,x,y,w,h)
 local img=Image(w,h,ColorMode.RGB);img:drawImage(src,Point(-x,-y));return img
end
local function resize(src,w,h)
 local img=Image(w,h,ColorMode.RGB)
 for y=0,h-1 do for x=0,w-1 do
  img:putPixel(x,y,src:getPixel(math.min(src.width-1,math.floor(x*src.width/w)),math.min(src.height-1,math.floor(y*src.height/h))))
 end end
 return img
end
local function save(img,name)
 local sprite=Sprite(img.width,img.height,ColorMode.RGB)
 sprite.cels[1].image=img
 sprite:saveAs(app.fs.joinPath(editable,name..'.aseprite'))
 sprite:saveCopyAs(app.fs.joinPath(out,name..'.png'))
 if name=='mine-chart' then sprite:saveCopyAs(app.fs.joinPath(runtime,'old_mine_chart.png')) end
 sprite:close()
end
save(resize(image,1280,570),'mine-chart')
-- Relative crop of the upper cave-in chamber from the exact retained source.
local area=crop(image,math.floor(image.width*.365),math.floor(image.height*.035),math.floor(image.width*.245),math.floor(image.height*.36))
save(resize(area,320,240),'fallen-stone')
print('Exported parchment mine chart and cave-in vignette through Aseprite.')
