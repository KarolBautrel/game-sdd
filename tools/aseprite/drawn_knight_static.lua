-- Presentation020. All raster normalization and board composition runs in Aseprite.
local root=assert(app.params.root)
local base=root..'/assets_src/characters/drawn_knight/2026-11-03'
local source=root..'/assets_src/aseprite/characters/drawn_knight/2026-11-03'
local pc=app.pixelColor
local report={aseprite=tostring(app.version),canvas={280,280},pivot={140,229},
 body_height=171,pixels_per_metre=100,assumed_height_metres=1.8,camera_elevation=18,
 status='STATIC_PROPOSALS_AWAITING_USER_SELECTION',variants={}}
local function savejson(path,value)
 local f=assert(io.open(path,'w'));f:write(json.encode(value));f:close()
end
local function bbox(im,x0,x1,threshold)
 local a,b,c,d=im.width,im.height,-1,-1
 for y=0,im.height-1 do for x=x0,x1 do
  if pc.rgbaA(im:getPixel(x,y))>=threshold then
   a=math.min(a,x);b=math.min(b,y);c=math.max(c,x);d=math.max(d,y)
  end
 end end
 assert(c>=a,'Empty source region')
 return Rectangle(a,b,c-a+1,d-b+1)
end
local colors={
 '191b21','24242c','302e35','3b3540','493e43','5b4947','6b554f','806252',
 '30283a','38364a','434257','50516a','60627a','74768a','9194a0',
 '30343b','3e434b','505762','646e7b','7c8796','97a4b0','b7c3ca','d9ded8',
 '3b2d25','50382a','664832','805a3c','9a724e','b38d66','d0af83',
 '51422c','6c5737','8b7046','aa8b59','c7a96f','e1c58d',
 '65402e','80543a','9b6848','b97e58','d39a6b','e5b88b','f3d4a8',
 '1d2124','333533','4b4d45','717268'}
local palette={}
for _,h in ipairs(colors) do
 palette[#palette+1]={tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16)}
end
local function clean(im,pixel)
 local cache={}
 for it in im:pixels() do
  local p=it();local a=pc.rgbaA(p)
  if a<(pixel and 128 or 20) then it(0)
  elseif pixel then
   local chosen=cache[p]
   if not chosen then
    local r,g,b=pc.rgbaR(p),pc.rgbaG(p),pc.rgbaB(p)
    local best=math.huge
    for _,v in ipairs(palette) do
     local dist=2*(r-v[1])^2+3*(g-v[2])^2+(b-v[3])^2
     if dist<best then best=dist;chosen=pc.rgba(v[1],v[2],v[3],255) end
    end
    cache[p]=chosen
   end
   it(chosen)
  end
 end
end
local function fit(im,h,method)
 local clone=Image(im)
 clone:resize{width=math.floor(im.width*h/im.height+.5),height=h,method=method}
 return clone
end
local function image_stats(im)
 local colorset,alphaset={},{};local count=0
 for it in im:pixels() do local p=it();local a=pc.rgbaA(p)
  alphaset[a]=true;if a>0 then count=count+1;colorset[p]=true end
 end
 local nc,na=0,0
 for _ in pairs(colorset) do nc=nc+1 end
 for _ in pairs(alphaset) do na=na+1 end
 return {opaque_or_partial_pixels=count,visible_rgba_colors=nc,alpha_levels=na}
end
local variants={}
for _,id in ipairs({'pixel','painted'}) do
 local pixel=id=='pixel'
 local raw=Image{fromFile=base..'/raw/'..id..'.png'}
 local split=math.floor(raw.width*.70)
 local br=bbox(raw,0,split,128)
 local sr=bbox(raw,split+1,raw.width-1,128)
 local bodySource=Image(raw,br);local swordSource=Image(raw,sr)
 -- Retain full-resolution independently editable masters too.
 local master=Sprite(raw.width,raw.height,ColorMode.RGB)
 master.layers[1].name='Body / generated source'
 master.cels[1].image=bodySource;master.cels[1].position=Point(br.x,br.y)
 local sl=master:newLayer();sl.name='Sword / detached generated source'
 master:newCel(sl,1,swordSource,Point(sr.x,sr.y))
 master:saveAs(source..'/'..id..'_master.aseprite');master:close()
 local body=fit(bodySource,171,pixel and 'nearest' or 'bilinear')
 local sword=fit(swordSource,98,pixel and 'nearest' or 'bilinear')
 clean(body,pixel);clean(sword,pixel)
 local bx=140-math.floor(body.width/2);local by=229-body.height
 local grip=Point(bx+math.floor(body.width*.94),by+math.floor(body.height*.505))
 local swordGrip=Point(math.floor(sword.width*.50),math.floor(sword.height*.135))
 local sx,sy=grip.x-swordGrip.x,grip.y-swordGrip.y
 -- Rigid sword behind the glove; body is intentionally above the sword layer.
 local sprite=Sprite(280,280,ColorMode.RGB)
 local weaponLayer=sprite.layers[1];weaponLayer.name='01 Rigid sword / grip '..swordGrip.x..','..swordGrip.y
 sprite.cels[1].image=sword;sprite.cels[1].position=Point(sx,sy)
 local bodyLayer=sprite:newLayer();bodyLayer.name='02 Body and glove / over sword grip'
 sprite:newCel(bodyLayer,1,body,Point(bx,by))
 if pixel then
  local pal=Palette(#palette+1);pal:setColor(0,Color{r=0,g=0,b=0,a=0})
  for index,v in ipairs(palette) do pal:setColor(index,Color{r=v[1],g=v[2],b=v[3],a=255}) end
  sprite:setPalette(pal)
 end
 local assembled=Image(sprite)
 local bodyCanvas=Image(280,280,ColorMode.RGB);bodyCanvas:drawImage(body,Point(bx,by))
 local swordCanvas=Image(280,280,ColorMode.RGB);swordCanvas:drawImage(sword,Point(sx,sy))
 bodyCanvas:saveAs(base..'/'..id..'_body.png')
 swordCanvas:saveAs(base..'/'..id..'_sword.png')
 assembled:saveAs(base..'/'..id..'_assembled.png')
 sprite:saveAs(source..'/'..id..'_native.aseprite')
 sprite:close()
 -- Inspect actual persisted source, not only an in-memory construction.
 local reopened=app.open(source..'/'..id..'_native.aseprite')
 assert(#reopened.layers==2 and #reopened.frames==1)
 local roundtrip=Image(reopened);local exact=true
 for y=0,279 do for x=0,279 do
  if assembled:getPixel(x,y)~=roundtrip:getPixel(x,y) then exact=false end
 end end
 assert(exact,'Source roundtrip differs');reopened:close()
 local stats=image_stats(assembled)
 assert(not pixel or (stats.visible_rgba_colors<=#colors and stats.alpha_levels==2))
 report.variants[id]={raw_size={raw.width,raw.height},body_source_bounds={br.x,br.y,br.width,br.height},
  sword_source_bounds={sr.x,sr.y,sr.width,sr.height},body_size={body.width,body.height},
  body_position={bx,by},sword_size={sword.width,sword.height},sword_position={sx,sy},
  grip_canvas={grip.x,grip.y},grip_sword={swordGrip.x,swordGrip.y},
  palette_limit=pixel and #colors or nil,stats=stats,aseprite_roundtrip_exact=exact}
 variants[#variants+1]={id=id,body=bodyCanvas,sword=swordCanvas,assembled=assembled,rawbody=bodySource}
end

local f=assert(io.open(root..'/tools/aseprite/style_studies.lua','r'))
local glyphs=assert(load('return '..assert(f:read('*a'):match('local glyphs=(%b{})'))))();f:close()
local ink=pc.rgba(232,223,204,255);local gold=pc.rgba(193,151,83,255)
local muted=pc.rgba(161,171,177,255);local bg=pc.rgba(25,29,32,255)
local function text(im,str,x,y,s,c)
 for ch in str:gmatch('.') do
  local g=glyphs[ch]
  if g then local yy=0;for line in g:gmatch('[^/]+') do
   for xx=1,#line do if line:sub(xx,xx)=='1' then
    im:clear(Rectangle(x+(xx-1)*s,y+yy*s,s,s),c)
   end end;yy=yy+1
  end end
  x=x+6*s
 end
end
local function saveboard(im,name)
 im:saveAs(base..'/'..name..'.png')
 local sp=Sprite(im.width,im.height,ColorMode.RGB);sp.cels[1].image=im
 sp.layers[1].name='Static Aseprite composition / actual game textures'
 sp:saveAs(source..'/'..name..'.aseprite');sp:close()
end
local function prop(im,id,x,y)
 local meta=json.decode(assert(io.open(root..'/resources/data/presentation/world_art.json','r')):read('*a')).assets[id]
 local image=Image{fromFile=root..'/'..meta.path:gsub('res://','')}
 image:resize{width=meta.size[1],height=meta.size[2],method='nearest'}
 im:drawImage(image,Point(x-meta.pivot[1],y-meta.pivot[2]))
end
local function board(v,kind,w,h)
 local im=Image(w,h,ColorMode.RGB)
 local floor=Image{fromFile=root..'/assets/combat/environment/floors/'..kind..'.png'}
 for y=0,h-1,512 do for x=0,w-1,512 do im:drawImage(floor,Point(x,y)) end end
 -- Same native prop sizes/pivots and floor tile frequency as EnvironmentArt.
 prop(im,'boulder',110,250);prop(im,'bush',w-90,140)
 prop(im,'fallen_log',w-90,h-30);prop(im,'grass',210,h-35)
 local pivot=Point(w//2,260)
 local sh=Image{fromFile=root..'/assets/combat/environment/contact_shadow.png'}
 sh:resize{width=90,height=26,method='bilinear'}
 im:drawImage(sh,Point(pivot.x-45,pivot.y-11))
 im:drawImage(v.assembled,Point(pivot.x-140,pivot.y-229))
 return im
end
local comparison=Image(1600,1180,ColorMode.RGB);comparison:clear(bg)
text(comparison,'RYCERZ 2D / DWIE PROPOZYCJE',35,25,4,ink)
text(comparison,'WSPOLNY STROJ / WIDOK 3-4 / OSOBNY SZTYWNY MIECZ',37,73,2,muted)
for i,v in ipairs(variants) do
 local x=(i-1)*800
 text(comparison,i==1 and 'A / SZCZEGOLOWY PIXEL ART' or 'B / MALARSTWO 2D',x+30,116,3,gold)
 text(comparison,'SKALA PLANSZY 1X / 100 PX NA METR',x+30,154,2,muted)
 local scene=board(v,'woodland',740,320)
 comparison:drawImage(scene,Point(x+30,184));scene:saveAs(base..'/'..v.id..'_board_1x.png')
 text(comparison,'ZBLIZENIE 3X / TE SAME PIKSELE',x+30,528,2,gold)
 local crop=Image(v.assembled,Rectangle(85,53,125,184))
 crop:resize{width=375,height=552,method='nearest'}
 comparison:drawImage(crop,Point(x+20,562))
 text(comparison,'TWARZ / 8X',x+445,575,2,muted)
 local face=Image(v.assembled,Rectangle(124,57,26,28))
 face:resize{width=208,height=224,method='nearest'}
 comparison:drawImage(face,Point(x+448,609))
 text(comparison,'MIECZ OSOBNO',x+435,864,2,muted)
 local sword=Image(v.sword,Rectangle(153,122,40,113))
 sword:resize{width=60,height=169,method='nearest'}
 comparison:drawImage(sword,Point(x+515,895))
end
text(comparison,'STATYCZNA KOMPOZYCJA NA TEKSTURACH GRY / WYBOR WYGLADU PRZED ANIMACJA',30,1148,2,muted)
saveboard(comparison,'comparison')

-- Show both the honest native-pixel enlargement and the painted source detail.
local closeup=Image(1600,1120,ColorMode.RGB);closeup:clear(bg)
text(closeup,'RYCERZ / ZBLIZENIE WYGLADU',30,24,4,ink)
text(closeup,'A: NATIVE PIXEL 4X / B: MALOWANE ZRODLO W TEJ SAMEJ WIELKOSCI',30,73,2,muted)
for i,v in ipairs(variants) do
 local x=(i-1)*800
 text(closeup,i==1 and 'A / PIXEL ART' or 'B / MALARSTWO 2D',x+30,120,3,gold)
 local hi
 if v.id=='pixel' then
  hi=Image(v.assembled);hi:resize{width=1120,height=1120,method='nearest'}
 else
  local meta=report.variants[v.id]
  local raw=Image{fromFile=base..'/raw/'..v.id..'.png'}
  local sb=meta.sword_source_bounds
  local sword=fit(Image(raw,Rectangle(sb[1],sb[2],sb[3],sb[4])),392,'bilinear')
  local body=fit(v.rawbody,684,'bilinear')
  clean(body,false);clean(sword,false)
  hi=Image(1120,1120,ColorMode.RGB)
  hi:drawImage(sword,Point(meta.sword_position[1]*4,meta.sword_position[2]*4))
  hi:drawImage(body,Point(meta.body_position[1]*4,meta.body_position[2]*4))
 end
 local whole=Image(hi,Rectangle(340,212,500,736))
 closeup:drawImage(whole,Point(x+5,190))
 text(closeup,'TWARZ',x+520,210,2,muted)
 local face=Image(hi,Rectangle(492,228,112,120))
 face:resize{width=224,height=240,method='nearest'}
 closeup:drawImage(face,Point(x+520,245))
 text(closeup,'REKAWICA I CHWYT',x+500,550,2,muted)
 local glove=Image(hi,Rectangle(628,524,88,116))
 glove:resize{width=176,height=232,method='nearest'}
 closeup:drawImage(glove,Point(x+535,584))
 text(closeup,i==1 and '45 UZYTYCH KOLOROW / OSTRA SIATKA' or 'WIDOCZNE POCIAGNIECIA PEDZLA',x+30,980,2,muted)
end
text(closeup,'DETAL ZRODLOWY NIE POWIEKSZA POSTACI W GRZE / SKALA 1X NA OSOBNEJ PLANSZY',30,1060,2,muted)
saveboard(closeup,'closeup')

local environments=Image(1600,790,ColorMode.RGB);environments:clear(bg)
text(environments,'RYCERZ NA PLANSZY / SKALA 1X',30,22,3,ink)
text(environments,'TE SAME TEKSTURY I SKALA OBIEKTOW CO W GRZE / KOMPOZYCJA STATYCZNA',30,58,2,muted)
for i,v in ipairs(variants) do
 local x=(i-1)*800
 text(environments,i==1 and 'A / PIXEL' or 'B / MALARSTWO',x+30,95,2,gold)
 for j,kind in ipairs({'earth','woodland'}) do
  local scene=board(v,kind,740,300)
  environments:drawImage(scene,Point(x+30,125+(j-1)*325))
 end
end
saveboard(environments,'board_scale')
savejson(base..'/normalization.json',report)
print('DRAWN_KNIGHT_ASEPRITE_PASS '..json.encode(report))
