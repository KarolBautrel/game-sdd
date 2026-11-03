-- Presentation015: actual MPFB pilot renders, editable review boards.
local root=assert(app.params.root)
local out=root..'/assets_src/characters/mpfb_warden/2026-11-02'
local before=root..'/assets_src/characters/surface_refinement/2026-11-02/02_warden'
local pc=app.pixelColor
local file=assert(io.open(root..'/tools/aseprite/style_studies.lua','r'))
local source=file:read('*a');file:close()
local glyphs=assert(load('return '..assert(source:match('local glyphs=(%b{})'))))()
local ink=pc.rgba(232,223,204,255)
local muted=pc.rgba(161,171,177,255)
local gold=pc.rgba(193,151,83,255)
local bg=pc.rgba(25,29,32,255)
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
 sp.layers[1].name='Actual static model renders / MPFB pilot'
 sp:saveAs(out..'/'..name..'.aseprite');sp:saveAs(out..'/'..name..'.png');sp:close()
end
local function crop_alpha(im)
 local x0,y0,x1,y1=im.width,im.height,0,0
 for it in im:pixels() do
  if pc.rgbaA(it())>25 then
   x0=math.min(x0,it.x);y0=math.min(y0,it.y);x1=math.max(x1,it.x);y1=math.max(y1,it.y)
  end
 end
 local cropped=Image(x1-x0+1,y1-y0+1,ColorMode.RGB)
 cropped:drawImage(im,Point(-x0,-y0));return cropped
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
local proposal=Image(1600,1310,ColorMode.RGB);proposal:clear(bg)
text(proposal,'STRAZNIK / MPFB - PROPOZYCJA',36,24,4,ink)
text(proposal,'SPOJNA TWARZ / OSOBNE OCZY I WLOSY / ZACHOWANY MALARSKI STROJ',38,74,2,muted)
for _,x in ipairs({18,818}) do
 rect(proposal,x,111,764,714,pc.rgba(35,40,44,255));rect(proposal,x,111,764,3,gold)
end
proposal:drawImage(load(out,'three_quarter',720),Point(40,100))
proposal:drawImage(load(out,'face_three_quarter',720),Point(840,100))
text(proposal,'POSTAC / RZUT TAKTYCZNY',40,133,2,gold)
text(proposal,'ZBLIZENIE RZECZYWISTEGO MODELU',840,133,2,gold)
text(proposal,'SKALA GRY / PRZED - MPFB',40,851,2,gold)
text(proposal,'MPFB / POWIEKSZENIE 2X',840,851,2,gold)
local pair=ground(764,380)
for i,base in ipairs({before,out}) do
 local im=crop_alpha(load(base,'tactical'))
 local cx=205+(i-1)*350
 pair:drawImage(shadow,Point(cx-42,312))
 pair:drawImage(im,Point(cx-math.floor(im.width/2),330-im.height))
end
proposal:drawImage(pair,Point(18,885))
local zoom=ground(764,380)
local im=crop_alpha(load(out,'tactical'));im:resize{width=im.width*2,height=im.height*2,method='nearest'}
zoom:drawImage(shadow,Point(340,338));zoom:drawImage(im,Point(math.floor((764-im.width)/2),370-im.height))
proposal:drawImage(zoom,Point(818,885))
text(proposal,'DOL: KOMPOZYCJA NA PODLODZE Z GRY / 100 PX NA METR / NIE SCREEN Z GODOTA',38,1280,2,muted)
save(proposal,'proposal')

local comparison=Image(1800,1050,ColorMode.RGB);comparison:clear(bg)
text(comparison,'TWARZ / STARA PROJEKCJA - NOWE MPFB',36,22,3,ink)
text(comparison,'PRZED / TEN SAM KADR I SWIATLO',36,68,2,muted)
text(comparison,'MPFB / TEKSTURA DOPASOWANA DO UV',936,68,2,gold)
comparison:drawImage(load(before,'face'),Point(0,110))
comparison:drawImage(load(out,'face_three_quarter'),Point(900,110))
text(comparison,'STATYCZNY PILOT / BEZ ANIMACJI I PODMIANY POSTACI W GRZE',36,1020,2,muted)
save(comparison,'comparison')

local views=Image(1600,1010,ColorMode.RGB);views:clear(bg)
text(views,'MPFB / PRZOD - 3-4 - BOK - TYL',30,20,3,ink)
for i,name in ipairs({'front','three_quarter','side','rear'}) do
 views:drawImage(load(out,name,400),Point((i-1)*400,70))
end
text(views,'TWARZ / PRZOD - 3-4 - PROFIL - INNE SWIATLO',30,505,2,gold)
for i,name in ipairs({'face_front','face_three_quarter','face_profile','face_changed_light'}) do
 views:drawImage(load(out,name,400),Point((i-1)*400,555))
end
text(views,'RENDERY PRAWDZIWEGO MODELU / ZRODLA BLEND I FBX / WYGLAD DO AKCEPTACJI',30,980,2,muted)
save(views,'all_views')
print('MPFB_WARDEN_ASEPRITE_PASS 3 editable review boards')
