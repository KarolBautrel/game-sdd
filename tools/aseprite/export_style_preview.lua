-- Runtime-only derivatives for the opt-in style preview; source studies untouched.
local root=assert(app.params.root)
local source=root..'/assets_src/characters/style_studies/2026-11-02'
local output=root..'/assets/ui/character_studies'
local ids={'a_painterly_veteran','b_ink_warden','c_heroic_miniature'}
local views={'front','three_quarter','side','rear'}
local pc=app.pixelColor
for _,id in ipairs(ids) do
 app.fs.makeAllDirectories(output..'/'..id)
 for _,view in ipairs(views) do
  local im=Image{fromFile=source..'/'..id..'/renders/'..view..'.png'}
  -- Source900px /2.8m ->280px /2.8m =100px/m. Ground pivot(140,229).
  im:resize{width=280,height=280,method='bilinear'}
  for it in im:pixels() do
   local p=it()
   if pc.rgbaA(p)<96 then it(0)
   else it(pc.rgba(math.floor(pc.rgbaR(p)/4)*4,math.floor(pc.rgbaG(p)/4)*4,math.floor(pc.rgbaB(p)/4)*4,255)) end
  end
  im:saveAs(output..'/'..id..'/'..view..'.png')
 end
 local face=Image{fromFile=source..'/'..id..'/renders/face.png'}
 face:resize{width=512,height=512,method='bilinear'}
 face:saveAs(output..'/'..id..'/face.png')
end
print('STYLE_PREVIEW_EXPORT_PASS 12 native views +3 face views')
