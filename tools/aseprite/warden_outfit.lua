-- Presentation016: real outfit volume, corrected stance/boots, unchanged face.
local root=assert(app.params.root)
local out=root..'/assets_src/characters/mpfb_warden_outfit/2026-11-02'
local before=root..'/assets_src/characters/mpfb_warden/2026-11-02'
local pc=app.pixelColor
local f=assert(io.open(root..'/tools/aseprite/style_studies.lua','r'))
local src=f:read('*a');f:close()
local glyphs=assert(load('return '..assert(src:match('local glyphs=(%b{})'))))()
local ink=pc.rgba(232,223,204,255);local gold=pc.rgba(193,151,83,255)
local muted=pc.rgba(161,171,177,255);local bg=pc.rgba(25,29,32,255)
local function rect(im,x,y,w,h,c) im:clear(Rectangle(x,y,w,h),c) end
local function text(im,str,x,y,s,c)
 for ch in str:gmatch('.') do
  local g=glyphs[ch]
  if g then local yy=0;for line in g:gmatch('[^/]+') do
   for xx=1,#line do if line:sub(xx,xx)=='1' then rect(im,x+(xx-1)*s,y+yy*s,s,s,c) end end
   yy=yy+1
  end end
  x=x+6*s
 end
end
local function load(base,name,size)
 local im=Image{fromFile=base..'/renders/'..name..'.png'}
 if size then im:resize{width=size,height=size,method='bilinear'} end
 return im
end
local function save(im,name)
 local sp=Sprite(im.width,im.height,ColorMode.RGB);sp.cels[1].image=im
 sp.layers[1].name='Actual model renders / physical outfit and fit comparison'
 sp:saveAs(out..'/'..name..'.aseprite');sp:saveAs(out..'/'..name..'.png');sp:close()
end
local function crop_alpha(im)
 local x0,y0,x1,y1=im.width,im.height,0,0
 for it in im:pixels() do if pc.rgbaA(it())>25 then
  x0=math.min(x0,it.x);y0=math.min(y0,it.y);x1=math.max(x1,it.x);y1=math.max(y1,it.y)
 end end
 local copy=Image(x1-x0+1,y1-y0+1,ColorMode.RGB);copy:drawImage(im,Point(-x0,-y0));return copy
end
local earth=Image{fromFile=root..'/assets/combat/environment/floors/earth.png'}
earth:resize{width=256,height=256,method='bilinear'}
local shadow=Image{fromFile=root..'/assets/combat/environment/contact_shadow.png'}
shadow:resize{width=84,height=32,method='bilinear'}
local function ground(w,h)
 local im=Image(w,h,ColorMode.RGB)
 for y=0,h-1,256 do for x=0,w-1,256 do im:drawImage(earth,Point(x,y)) end end
 return im
end
local p=Image(1600,1330,ColorMode.RGB);p:clear(bg)
text(p,'STRAZNIK / ZBROJA I PASY W 3D',36,24,4,ink)
text(p,'POPRAWIONA POSTAWA / MNIEJSZE BUTY / ZACHOWANA TWARZ MPFB',38,75,2,muted)
for _,x in ipairs({18,818}) do rect(p,x,111,764,714,pc.rgba(35,40,44,255));rect(p,x,111,764,3,gold) end
p:drawImage(load(out,'three_quarter',720),Point(40,100))
p:drawImage(load(out,'belt',660),Point(870,160))
text(p,'NOWY STROJ I NOGI',40,132,2,gold);text(p,'BRYLA PASA / KLAMRY / PLYT',840,132,2,gold)
text(p,'100 PX NA METR / PRZED - PO',38,851,2,gold)
local pair=ground(764,380)
for i,base in ipairs({before,out}) do
 local im=crop_alpha(load(base,'tactical'));local x=205+(i-1)*350
 pair:drawImage(shadow,Point(x-42,312));pair:drawImage(im,Point(x-math.floor(im.width/2),330-im.height))
end
p:drawImage(pair,Point(18,885))
text(p,'BUTY / PRZED - PO / TEN SAM KADR',838,851,2,gold)
p:drawImage(load(out,'before_boots',380),Point(818,885));p:drawImage(load(out,'boots',380),Point(1198,885))
text(p,'RENDERY RZECZYWISTEGO MODELU / DOL: KOMPOZYCJA NA PODLODZE Z GRY',38,1285,2,muted)
text(p,'STATYCZNA PROPOZYCJA / RIG I ANIMACJE W KOLEJNYM ETAPIE',38,1310,2,muted)
save(p,'proposal')

local c=Image(1800,1570,ColorMode.RGB);c:clear(bg)
text(c,'PRZED - PO / POSTAWA I PRAWDZIWA ZBROJA',36,22,3,ink)
text(c,'STARSZY STROJ / WIEKSZE BUTY',36,68,2,muted)
text(c,'NOWA ANATOMIA / MODELOWANY STROJ',936,68,2,gold)
c:drawImage(load(before,'three_quarter'),Point(0,80));c:drawImage(load(out,'three_quarter'),Point(900,80))
text(c,'BUTY / TA SAMA KAMERA I SKALA',36,990,3,gold)
c:drawImage(load(out,'before_boots',520),Point(190,1030));c:drawImage(load(out,'boots',520),Point(1090,1030))
text(c,'POPRAWIONA POSTAWA CELOWO SIE ROZNI / KAMERA I SWIATLO ZACHOWANE',36,1536,2,muted)
save(c,'comparison')

local v=Image(1600,1120,ColorMode.RGB);v:clear(bg)
text(v,'PRZOD - 3-4 - BOK - TYL',30,20,3,ink)
for i,name in ipairs({'front','three_quarter','side','rear'}) do v:drawImage(load(out,name,400),Point((i-1)*400,70)) end
text(v,'BEZ TEKSTUR / RZECZYWISTA BRYLA',30,510,2,gold)
text(v,'INNE SWIATLO / PRAWDZIWE MATERIALY',830,510,2,gold)
v:drawImage(load(out,'geometry_belt',550),Point(125,550))
v:drawImage(load(out,'changed_light',550),Point(925,550))
save(v,'all_views')
print('WARDEN_OUTFIT_ASEPRITE_PASS 3 editable boards')
