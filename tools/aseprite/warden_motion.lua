-- Presentation018: editable motion sources and review boards from actual renders.
local root=assert(app.params.root)
local out=root..'/assets_src/characters/warden_motion_pilot/2026-11-03'
app.fs.makeDirectory(out..'/aseprite')
local pc=app.pixelColor
local file=assert(io.open(root..'/tools/aseprite/style_studies.lua','r'))
local src=file:read('*a');file:close()
local glyphs=assert(load('return '..assert(src:match('local glyphs=(%b{})'))))()
local ink=pc.rgba(232,223,204,255);local gold=pc.rgba(193,151,83,255)
local muted=pc.rgba(161,171,177,255);local bg=pc.rgba(25,32,36,255)
local function text(im,str,x,y,s,c)
 for ch in str:gmatch('.') do
  local g=glyphs[ch]
  if g then local yy=0;for line in g:gmatch('[^/]+') do
   for xx=1,#line do if line:sub(xx,xx)=='1' then im:clear(Rectangle(x+(xx-1)*s,y+yy*s,s,s),c) end end
   yy=yy+1
  end end
  x=x+6*s
 end
end
local function frame(clip,view,f)
 return Image{fromFile=out..'/renders/'..clip..'/'..view..'/'..string.format('%03d',f)..'.png'}
end
local function save(im,name)
 local sp=Sprite(im.width,im.height,ColorMode.RGB);sp.cels[1].image=im
 sp.layers[1].name='Actual native Blender renders / review annotations'
 sp:saveAs(out..'/'..name..'.aseprite');sp:saveAs(out..'/'..name..'.png');sp:close()
end
local clips={{'Idle',48},{'Walk',32},{'Sword',40}}
local views={'three_quarter','front','side','rear'}
local pixel_stats={}
for _,clip in ipairs(clips) do
 for _,view in ipairs(views) do
  local sp=Sprite(384,384,ColorMode.RGB);sp.layers[1].name='Native Blender motion / 24fps source'
  local previous=nil;local changed=0
  for f=0,clip[2]-1 do
   if f>0 then sp:newEmptyFrame() end
   -- Explicit nearest integer milliseconds; avoid Aseprite truncating1/24 to41ms.
   local fr=sp.frames[f+1];fr.duration=.042
   local im=frame(clip[1],view,f)
   local bytes=assert(im.bytes,'Readable RGBA bytes required')
   if previous and previous~=bytes then changed=changed+1 end
   previous=bytes
   if f==0 then sp.cels[1].image=im else sp:newCel(sp.layers[1],fr,im,Point(0,0)) end
  end
  assert(changed>0,'Static rendered sequence: '..clip[1]..'/'..view)
  table.insert(pixel_stats,string.format('{"clip":"%s","view":"%s","frames":%d,"changed_pixel_transitions":%d}',clip[1],view,clip[2],changed))
  sp:saveAs(out..'/aseprite/'..clip[1]..'_'..view..'.aseprite');sp:close()
 end
end
local stats=assert(io.open(out..'/render_pixel_verification.json','w'))
stats:write('{"status":"PASS","reader":"Aseprite native RGBA Image.bytes","sequences":['..table.concat(pixel_stats,',')..']}\n');stats:close()
-- Crop the unused transparent border; retain literal100px/metre render pixels.
local sets={{'Idle',{0,8,16,24,32,40}},{'Walk',{0,4,8,12,16,24}},{'Sword',{0,8,12,17,22,29}}}
local board=Image(1576,1160,ColorMode.RGB);board:clear(bg)
text(board,'STRAZNIK / PIERWSZA PROBA RUCHU',24,22,4,ink)
text(board,'BEZ ZMIANY WYGLADU / 24 FPS / NATYWNE 100 PX NA METR',25,65,2,muted)
for row,set in ipairs(sets) do
 local y=110+(row-1)*345
 text(board,set[1]:upper(),24,y,3,gold)
 for col,f in ipairs(set[2]) do
  local im=Image(frame(set[1],'three_quarter',f),Rectangle(64,50,256,300))
  local x=20+(col-1)*256
  board:drawImage(im,Point(x,y+25))
  text(board,'F'..string.format('%02d',f),x+112,y+320,2,muted)
 end
end
save(board,'motion_review')
local dirs=Image(1576,1170,ColorMode.RGB);dirs:clear(bg)
text(dirs,'KIERUNKI / TEN SAM MODEL I RUCH',24,22,4,ink)
local names={'TRZY CZWARTE','PRZOD','BOK','TYL'}
for col,view in ipairs(views) do
 local x=20+(col-1)*384;text(dirs,names[col],x+55,75,2,gold)
 for row,entry in ipairs({{'Idle',0},{'Walk',8},{'Sword',17}}) do
  dirs:drawImage(frame(entry[1],view,entry[2]),Point(x,80+(row-1)*350))
 end
end
save(dirs,'direction_review')
print('WARDEN_MOTION_ASEPRITE_PASS 12 animation sources, 2 review boards; HTML retains exact24fps')
