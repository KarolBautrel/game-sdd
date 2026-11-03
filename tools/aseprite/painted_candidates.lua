-- Presentation012: real model renders, editable Aseprite comparison sources.
local root=assert(app.params.root)
local base=root..'/assets_src/characters/painted_candidates/2026-11-02'
local old=root..'/assets_src/characters/style_studies/2026-11-02/a_painterly_veteran'
local pc=app.pixelColor
local ids={'01_mercenary','02_warden','03_wayfarer'}
local titles={'I / NAJEMNIK','II / STRAZNIK','III / WEDROWIEC'}
local notes={'BRYGANTYNA / PIKOWANA WELNA','POLPLYTA / WARSTWOWE NARAMIENNIKI','DLUGI KAFTAN / LEKKA SKORA'}
-- Reuse the unchanged project-owned bitmap alphabet, not the old export body.
local fontFile=assert(io.open(root..'/tools/aseprite/style_studies.lua','r'))
local fontSource=fontFile:read('*a');fontFile:close()
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
local function load(folder,name,size)
 local im=Image{fromFile=folder..'/renders/'..name..'.png'}
 if size then im:resize{width=size,height=size,method='bilinear'} end
 return im
end
local function save(im,name)
 local sp=Sprite(im.width,im.height,ColorMode.RGB);sp.cels[1].image=im
 sp.layers[1].name='Actual 3D renders / static proposals / no game integration'
 sp:saveAs(base..'/'..name..'.aseprite');sp:saveAs(base..'/'..name..'.png');sp:close()
end
local earth=Image{fromFile=root..'/assets/combat/environment/floors/earth.png'}
earth:resize{width=256,height=256,method='bilinear'}
local shadow=Image{fromFile=root..'/assets/combat/environment/contact_shadow.png'}
shadow:resize{width=84,height=32,method='bilinear'}
local function ground(w,h,tact)
 local tile=Image(w,h,ColorMode.RGB)
 for x=0,w-1,256 do for y=0,h-1,256 do tile:drawImage(earth,Point(x,y)) end end
 tile:drawImage(shadow,Point(w//2-42,216))
 tile:drawImage(tact,Point(w//2-192,-53))
 return tile
end
local sheet=Image(1800,1430,ColorMode.RGB);sheet:clear(pc.rgba(25,29,32,255))
text(sheet,'MALOWANE POSTACIE / NOWE PROPOZYCJE',40,28,4,ink)
text(sheet,'RENDERY RZECZYWISTYCH MODELI 3D / OSOBNO: REFERENCJE KONCEPCYJNE',42,77,2,muted)
for i,id in ipairs(ids) do
 local x=(i-1)*600;local folder=base..'/'..id
 rect(sheet,x+18,115,564,865,pc.rgba(36,41,45,255));rect(sheet,x+18,115,564,3,gold)
 text(sheet,titles[i],x+38,138,3,ink);text(sheet,notes[i],x+38,177,2,muted)
 sheet:drawImage(load(folder,'three_quarter',660),Point(x-30,200))
 text(sheet,'TWARZ',x+47,775,2,muted);text(sheet,'PROFIL',x+335,775,2,muted)
 sheet:drawImage(load(folder,'face',200),Point(x+52,799))
 sheet:drawImage(load(folder,'side',275),Point(x+280,766))
 text(sheet,'SKALA PLANSZY / 100 PX NA METR',x+35,1004,2,gold)
 sheet:drawImage(ground(564,292,load(folder,'tactical')),Point(x+18,1040))
end
text(sheet,'STATYCZNE PROTOTYPY / TEKSTURY Z ORYGINALNYCH REFERENCJI AI / BEZ RIGU I ANIMACJI',38,1355,2,muted)
text(sheet,'DOL: KOMPOZYCJA NA PODLODZE Z GRY. TO NIE SA SCREENSHOTY Z ROZGRYWKI.',38,1386,2,muted)
save(sheet,'comparison')
local multi=Image(1800,1550,ColorMode.RGB);multi:clear(pc.rgba(25,29,32,255))
text(multi,'PRZOD / 3-4 / BOK / TYL',35,25,3,ink)
for i,id in ipairs(ids) do
 local y=65+(i-1)*490;text(multi,titles[i],35,y,3,gold)
 for j,v in ipairs({'front','three_quarter','side','rear'}) do
  multi:drawImage(load(base..'/'..id,v,465),Point((j-1)*450,y+20))
 end
end
save(multi,'all_views')
local before=Image(1600,1120,ColorMode.RGB);before:clear(pc.rgba(25,29,32,255))
text(before,'STARE A / TRZY NOWE MODELE',35,25,4,ink)
text(before,'GORA: 200 PX NA METR / DOL: 100 PX NA METR / WSPOLNY KAT KAMERY',35,72,2,muted)
for i=1,4 do
 local folder=i==1 and old or base..'/'..ids[i-1]
 local title=i==1 and 'STARE A' or titles[i-1]
 local x=(i-1)*400
 text(before,title,x+25,118,3,gold)
 -- 900px source /2.8m(old) or2.7m(new) -> common200px/m.
 local size=i==1 and 560 or 540
 before:drawImage(load(folder,'three_quarter',size),Point(x+200-size//2,152))
 text(before,'100 PX NA METR',x+30,720,2,muted)
 before:drawImage(ground(384,292,load(folder,i==1 and 'tactical_100ppm' or 'tactical')),Point(x+8,760))
end
text(before,'A ZACHOWANE / NOWE: POZA BEZ BRONI / MODEL I MALOWANIE DO OCENY',35,1080,2,muted)
save(before,'before_after')
print('PAINTED_COMPARISON_ASEPRITE_PASS 3 boards')
