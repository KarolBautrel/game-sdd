-- Matched stage39 -> stage40 model renders. Existing source assets stay intact.
local root=assert(app.params.root)
local before=root..'/assets_src/characters/painted_candidates/2026-11-02'
local after=root..'/assets_src/characters/surface_refinement/2026-11-02'
local pc=app.pixelColor
local ids={'01_mercenary','02_warden','03_wayfarer'}
local titles={'I / NAJEMNIK','II / STRAZNIK','III / WEDROWIEC'}
local f=assert(io.open(root..'/tools/aseprite/style_studies.lua','r'))
local fontSource=f:read('*a');f:close()
local glyphs=assert(load('return '..assert(fontSource:match('local glyphs=(%b{})'))))()
local function rect(im,x,y,w,h,c) im:clear(Rectangle(x,y,w,h),c) end
local function text(im,str,x,y,size,color)
 for ch in str:gmatch('.') do
  local g=glyphs[ch]
  if g then local yy=0;for line in g:gmatch('[^/]+') do
   for xx=1,#line do if line:sub(xx,xx)=='1' then rect(im,x+(xx-1)*size,y+yy*size,size,size,color) end end
   yy=yy+1
  end end
  x=x+6*size
 end
end
local ink=pc.rgba(232,223,204,255)
local muted=pc.rgba(161,171,177,255)
local gold=pc.rgba(193,151,83,255)
local function load(base,id,view,size)
 local im=Image{fromFile=base..'/'..id..'/renders/'..view..'.png'}
 if size then im:resize{width=size,height=size,method='bilinear'} end
 return im
end
local function save(im,name)
 local sp=Sprite(im.width,im.height,ColorMode.RGB);sp.cels[1].image=im
 sp.layers[1].name='Matched actual Blender models / before and after'
 sp:saveAs(after..'/'..name..'.aseprite');sp:saveAs(after..'/'..name..'.png');sp:close()
end
local earth=Image{fromFile=root..'/assets/combat/environment/floors/earth.png'}
earth:resize{width=256,height=256,method='bilinear'}
local shadow=Image{fromFile=root..'/assets/combat/environment/contact_shadow.png'}
shadow:resize{width=84,height=32,method='bilinear'}
local function ground_pair(id)
 local tile=Image(564,292,ColorMode.RGB)
 for x=0,563,256 do for y=0,291,256 do tile:drawImage(earth,Point(x,y)) end end
 for i,base in ipairs({before,after}) do
  local center=138+(i-1)*270
  tile:drawImage(shadow,Point(center-42,216))
  -- Both384px source canvases remain unscaled, at exactly100px/m.
  tile:drawImage(load(base,id,'tactical'),Point(center-192,-53))
 end
 return tile
end
local sheet=Image(1800,1430,ColorMode.RGB);sheet:clear(pc.rgba(25,29,32,255))
text(sheet,'MNIEJ KANTOW / POROWNANIE PRZED I PO',40,28,4,ink)
text(sheet,'TA SAMA POZA / KAMERA / SKALA / MALOWANY KIERUNEK ZACHOWANY',42,77,2,muted)
for i,id in ipairs(ids) do
 local x=(i-1)*600
 rect(sheet,x+18,115,564,865,pc.rgba(36,41,45,255));rect(sheet,x+18,115,564,3,gold)
 text(sheet,titles[i],x+38,138,3,ink)
 text(sheet,'PRZED',x+80,192,2,muted);text(sheet,'PO',x+410,192,2,gold)
 sheet:drawImage(load(before,id,'three_quarter',450),Point(x-75,210))
 sheet:drawImage(load(after,id,'three_quarter',450),Point(x+225,210))
 text(sheet,'TWARZ I KOLNIERZ',x+38,718,2,muted)
 sheet:drawImage(load(before,id,'face',225),Point(x+18,750))
 sheet:drawImage(load(after,id,'face',225),Point(x+318,750))
 text(sheet,'100 PX NA METR / PRZED - PO',x+35,1004,2,gold)
 sheet:drawImage(ground_pair(id),Point(x+18,1040))
end
text(sheet,'RENDERY RZECZYWISTYCH MODELI / DOL: KOMPOZYCJA NA PODLODZE Z GRY',38,1355,2,muted)
text(sheet,'STATYCZNE ZRODLA POSTACI / WYBOR I ANIMACJE W KOLEJNYM ETAPIE',38,1386,2,muted)
save(sheet,'comparison')
local details=Image(1800,1060,ColorMode.RGB);details:clear(pc.rgba(25,29,32,255))
text(details,'STRAZNIK / TWARZ - KOLNIERZ - RAMIONA',35,20,3,ink)
text(details,'PRZED / ORYGINALNA ROZDZIELCZOSC',35,66,2,muted)
text(details,'PO / ORYGINALNA ROZDZIELCZOSC',935,66,2,gold)
details:drawImage(load(before,'02_warden','face'),Point(0,110))
details:drawImage(load(after,'02_warden','face'),Point(900,110))
text(details,'BEZ ROZMYWANIA BITMAPY / ZMIANA KRZYWIZN I KRAWEDZI MODELU',35,1030,2,muted)
save(details,'details')
local multi=Image(1800,1550,ColorMode.RGB);multi:clear(pc.rgba(25,29,32,255))
text(multi,'NOWE / PRZOD - 3-4 - BOK - TYL',35,25,3,ink)
for i,id in ipairs(ids) do
 local y=65+(i-1)*490;text(multi,titles[i],35,y,3,gold)
 for j,v in ipairs({'front','three_quarter','side','rear'}) do
  multi:drawImage(load(after,id,v,465),Point((j-1)*450,y+20))
 end
end
save(multi,'all_views')
print('SURFACE_COMPARISON_ASEPRITE_PASS 3 editable boards')
