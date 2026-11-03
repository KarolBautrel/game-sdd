-- Quick painted pose study only; not layered production/animation art.
local root=assert(app.params.root)
local base=root..'/assets_src/characters/drawn_knight_waist_sample/2026-11-03'
local src=root..'/assets_src/aseprite/characters/drawn_knight_waist_sample/2026-11-03'
local pc=app.pixelColor
local function read(path) local f=assert(io.open(path,'r'));local s=f:read('*a');f:close();return s end
local glyphs=assert(load('return '..assert(read(root..'/tools/aseprite/style_studies.lua'):match('local glyphs=(%b{})'))))()
local function text(im,str,x,y,s,c)
 for ch in str:gmatch('.') do local g=glyphs[ch]
  if g then local yy=0;for line in g:gmatch('[^/]+') do
   for xx=1,#line do if line:sub(xx,xx)=='1' then im:clear(Rectangle(x+(xx-1)*s,y+yy*s,s,s),c) end end
   yy=yy+1
  end end;x=x+6*s
 end
end
local function bounds(im)
 local x0,y0,x1,y1=im.width,im.height,-1,-1
 for it in im:pixels() do if pc.rgbaA(it())>=128 then
  x0=math.min(x0,it.x);y0=math.min(y0,it.y);x1=math.max(x1,it.x);y1=math.max(y1,it.y)
 end end
 return {x0,y0,x1-x0+1,y1-y0+1}
end
local function save(im,name)
 local sp=Sprite(im.width,im.height,ColorMode.RGB);sp.cels[1].image=im
 sp.layers[1].name='Quick painted pose study / no production layer separation'
 sp:saveAs(src..'/'..name..'.aseprite');sp:close()
end
local sample=Image{fromFile=base..'/sample.png'}
save(sample,'sample')
local old=Image{fromFile=root..'/assets_src/characters/drawn_knight_guard_side/2026-11-03/painted_source_assembled.png'}
local bg=pc.rgba(25,29,32,255);local ink=pc.rgba(232,223,204,255)
local gold=pc.rgba(193,151,83,255);local muted=pc.rgba(161,171,177,255)
local board=Image(1600,1040,ColorMode.RGB);board:clear(bg)
text(board,'PROBKA / JELEC NIZEJ I BLIZEJ TALII',30,24,4,ink)
text(board,'POROWNANIE POZ / PODOBNA WYSOKOSC CIALA / MALARSTWO 2D',30,75,2,muted)
text(board,'WCZESNIEJ / CHWYT PRZY BARKU',30,124,3,muted)
text(board,'PROBKA / JELEC PRZY PASIE',830,124,3,gold)
local notes={}
for i,im in ipairs({old,sample}) do
 local bb=bounds(im);local sole=bb[2]+bb[4]-1
 local hair=i==1 and 413 or 370
 local groundX=i==1 and 615 or 550
 local scale=550/(sole-hair+1)
 local render=Image(im);render:resize{width=math.floor(im.width*scale+.5),height=math.floor(im.height*scale+.5),method='bilinear'}
 board:drawImage(render,Point(math.floor((i-1)*800+400-groundX*scale+.5),math.floor(930-sole*scale+.5)))
 notes[i]={source_size={im.width,im.height},hair_top_approx=hair,source_sole=sole,comparison_scale=scale}
end
text(board,'OBIE DLONIE POD JELCEM / OSTRZE NADAL PIONOWE / SZYBKA PROBA POZY',30,980,2,muted)
board:saveAs(base..'/before_after.png');save(board,'before_after')
local bb=bounds(sample);local sole=bb[2]+bb[4]-1
local scale=165/(sole-370+1)
local render=Image(sample);render:resize{width=math.floor(sample.width*scale+.5),height=math.floor(sample.height*scale+.5),method='bilinear'}
for it in render:pixels() do if pc.rgbaA(it())<20 then it(0) end end
local native=Image(280,280,ColorMode.RGB)
native:drawImage(render,Point(math.floor(140-550*scale+.5),math.floor(229-sole*scale+.5)))
native:saveAs(base..'/native_sample.png');save(native,'native_sample')
local f=assert(io.open(base..'/normalization.json','w'))
f:write(json.encode({aseprite=tostring(app.version),status='EXPLORATORY_PAINTED_POSE_ONLY',comparison=notes,
 native_canvas={280,280},native_body_height_approx=165,body_hair_anchor_is_manual=true,
 production_weapon_layer_separation=false,animation=false}));f:close()
print('WAIST_GUARD_SAMPLE_PASS')
