-- Presentation021 correction: user-referenced shoulder-side guard.
local root=assert(app.params.root)
local base=root..'/assets_src/characters/drawn_knight_guard_side/2026-11-03'
local source=root..'/assets_src/aseprite/characters/drawn_knight_guard_side/2026-11-03'
local pc=app.pixelColor
local function read(path) local f=assert(io.open(path,'r'));local s=f:read('*a');f:close();return s end
local config=json.decode(read(base..'/separation.json'))
local padding=config.source_top_padding
-- Authored coordinates refer to unchanged square generator inputs. Extend the
-- source canvas upward for a full-length sword without shrinking the body.
for _,poly in ipairs({config.guard_polygon,config.handle_polygon}) do
 for _,p in ipairs(poly) do p[2]=p[2]+padding end
end
for _,poly in ipairs(config.glove_polygons) do for _,p in ipairs(poly) do p[2]=p[2]+padding end end
for _,cfg in pairs(config.variants) do
 for _,key in ipairs({'guard_center','pommel_center','source_blade_root','source_blade_tip'}) do cfg[key][2]=cfg[key][2]+padding end
end
local colors=assert(load('return '..assert(read(root..'/tools/aseprite/drawn_knight_static.lua'):match('local colors=(%b{})'))))()
local glyphs=assert(load('return '..assert(read(root..'/tools/aseprite/style_studies.lua'):match('local glyphs=(%b{})'))))()
local palette={}
for _,h in ipairs(colors) do palette[#palette+1]={tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16)} end
local function inside(poly,x,y)
 local hit=false;local j=#poly
 for i=1,#poly do local a,b=poly[i],poly[j]
  if (a[2]>y)~=(b[2]>y) and x<(b[1]-a[1])*(y-a[2])/(b[2]-a[2])+a[1] then hit=not hit end
  j=i
 end
 return hit
end
local function hand(x,y)
 for _,p in ipairs(config.glove_polygons) do if inside(p,x,y) then return true end end
 return false
end
local function clean(im,pixel)
 local cache={}
 for it in im:pixels() do local p=it();local a=pc.rgbaA(p)
  if a<(pixel and 128 or 20) then it(0)
  elseif pixel then
   local c=cache[p]
   if not c then local r,g,b=pc.rgbaR(p),pc.rgbaG(p),pc.rgbaB(p);local best=math.huge
    for _,v in ipairs(palette) do local d=2*(r-v[1])^2+3*(g-v[2])^2+(b-v[3])^2
     if d<best then best=d;c=pc.rgba(v[1],v[2],v[3],255) end
    end
    cache[p]=c
   end
   it(c)
  end
 end
end
local function bounds(im)
 local x0,y0,x1,y1=im.width,im.height,-1,-1
 for it in im:pixels() do if pc.rgbaA(it())>0 then
  x0=math.min(x0,it.x);y0=math.min(y0,it.y);x1=math.max(x1,it.x);y1=math.max(y1,it.y)
 end end
 assert(x1>=x0);return {x0,y0,x1-x0+1,y1-y0+1}
end
local function stats(im)
 local cs,as={},{};local count=0
 for it in im:pixels() do local p=it();as[pc.rgbaA(p)]=true
  if pc.rgbaA(p)>0 then cs[p]=true;count=count+1 end
 end
 local nc,na=0,0;for _ in pairs(cs) do nc=nc+1 end;for _ in pairs(as) do na=na+1 end
 return {visible_colors=nc,alpha_levels=na,visible_pixels=count,bounds=bounds(im)}
end
local function same(a,b)
 if a.width~=b.width or a.height~=b.height then return false end
 for it in a:pixels() do if it()~=b:getPixel(it.x,it.y) then return false end end
 return true
end
local function sprite_from_layers(images,names,path)
 local sp=Sprite(images[1].width,images[1].height,ColorMode.RGB)
 sp.layers[1].name=names[1];sp.cels[1].image=images[1]
 for i=2,#images do local layer=sp:newLayer();layer.name=names[i];sp:newCel(layer,1,images[i],Point(0,0)) end
 sp:saveAs(path)
 return sp
end
local function nearest(im,x,y)
 x=math.floor(x+.5);y=math.floor(y+.5)
 if x<0 or y<0 or x>=im.width or y>=im.height then return 0 end
 return im:getPixel(x,y)
end
local function sample(im,x,y,pixel)
 if pixel then return nearest(im,x,y) end
 local x0,y0=math.floor(x),math.floor(y);local fx,fy=x-x0,y-y0
 local r,g,b,a=0,0,0,0
 for yy=0,1 do for xx=0,1 do local p=nearest(im,x0+xx,y0+yy)
  local w=(xx==0 and 1-fx or fx)*(yy==0 and 1-fy or fy)
  r=r+pc.rgbaR(p)*w;g=g+pc.rgbaG(p)*w;b=b+pc.rgbaB(p)*w;a=a+pc.rgbaA(p)*w
 end end
 return pc.rgba(math.floor(r+.5),math.floor(g+.5),math.floor(b+.5),math.floor(a+.5))
end

local variants={}
local report={aseprite=tostring(app.version),stage='SIDE_GUARD_AWAITING_VISUAL_REVIEW',
 canvas={280,280},pivot={140,229},requested_source_scale=config.requested_uniform_source_scale,
 palette_limit=#colors,source_top_padding=padding,reference='references/pozycja_miecza.webp',variants={}}
for _,id in ipairs({'pixel','painted'}) do
 local pixel=id=='pixel';local cfg=config.variants[id]
 local input=Image{fromFile=base..'/raw/'..id..'.png'}
 assert(input.width==config.input_canvas[1] and input.height==config.input_canvas[2])
 local raw=Image(input.width,input.height+padding,ColorMode.RGB);raw:drawImage(input,Point(0,padding))
 local body=Image(raw);local gloves=Image(raw.width,raw.height,ColorMode.RGB)
 local sword=Image(raw.width,raw.height,ColorMode.RGB)
 local gx,gy=cfg.guard_center[1],cfg.guard_center[2]
 local px,py=cfg.pommel_center[1],cfg.pommel_center[2]
 local length=math.sqrt((gx-px)^2+(gy-py)^2);local ux,uy=(gx-px)/length,(gy-py)/length
 local nx,ny=-uy,ux
 local sb=cfg.source_blade_root;local tip=cfg.source_blade_tip
 local sourceBladeLength=math.sqrt((tip[1]-sb[1])^2+(tip[2]-sb[2])^2)
 local bl=config.blade_length
 local sux,suy=(tip[1]-sb[1])/sourceBladeLength,(tip[2]-sb[2])/sourceBladeLength
 local snx,sny=-suy,sux
 -- Blade begins just above crossguard on the SAME handle centerline.
 local tx,ty=gx+ux*15,gy+uy*15
 -- Only this bounded sword/hand region changes; avoid point-in-polygon work
 -- over every unchanged background/body pixel in the large generated source.
 for y=10,860 do for x=360,515 do
  local oldt=(x-sb[1])*sux+(y-sb[2])*suy
  local oldd=(x-sb[1])*snx+(y-sb[2])*sny
  local oldblade=oldt>=-15 and oldt<=sourceBladeLength+12 and math.abs(oldd)<=35
  local guard=inside(config.guard_polygon,x,y)
  local handle=inside(config.handle_polygon,x,y)
  local pommel=(x-px)^2+(y-py)^2<=config.pommel_radius^2
  local glove=hand(x,y)
  if oldblade or guard or handle or pommel or glove then body:drawPixel(x,y,0) end
  if glove then gloves:drawPixel(x,y,raw:getPixel(x,y))
  elseif guard or handle or pommel then sword:drawPixel(x,y,raw:getPixel(x,y)) end
  -- Reconstruct only hidden handle pixels beneath the two foreground gloves.
  local ht=(x-gx)*ux+(y-gy)*uy;local hd=(x-gx)*nx+(y-gy)*ny
  if ht< -13 and ht> -length+14 and math.abs(hd)<=config.grip_half_width then
   if glove or pc.rgbaA(sword:getPixel(x,y))==0 then
    local ridge=math.floor((hd/config.grip_half_width+1)*10)
    sword:drawPixel(x,y,pc.rgba(90+ridge,58+ridge//2,37+ridge//3,255))
   end
  end
  local t=(x-tx)*ux+(y-ty)*uy;local d=(x-tx)*nx+(y-ty)*ny
  if t>=-9 and t<=bl then
   local taper=t<bl*.84 and (1-.36*math.max(t,0)/bl) or (.6976*(bl-t)/(bl*.16))
   local half=config.blade_root_half_width*taper
   if math.abs(d)<=half then
    local sampleT=math.max(t,0)*sourceBladeLength/bl
    local p=sample(raw,sb[1]+sux*sampleT+snx*d,sb[2]+suy*sampleT+sny*d,pixel)
    -- Keep sampled painted texture; repair only transparent edge samples.
    if pc.rgbaA(p)<96 then
     local v=d<0 and 175 or 108;p=pc.rgba(v+6,v+7,v+12,255)
    end
    local alpha=pixel and 255 or math.floor(math.min(1,half-math.abs(d)+.5)*255)
    sword:drawPixel(x,y,pc.rgba(pc.rgbaR(p),pc.rgbaG(p),pc.rgbaB(p),alpha))
   end
  end
 end end
 -- Recover tiny floating edge residues of the original blade outside the edit mask.
 for y=0,padding+285 do for x=370,500 do body:drawPixel(x,y,0) end end
 local master=sprite_from_layers({body,sword,gloves},{'01 Body / hidden weapon surfaces not authored','02 Rigid sword / axis corrected','03 Foreground gloves / two-hand grip'},source..'/'..id..'_master.aseprite')
 local masterRender=Image(master);masterRender:saveAs(base..'/'..id..'_source_assembled.png');master:close()
 local rbb=bounds(raw);local groundY=rbb[2]+rbb[4]-1
 local targetSize=math.floor(raw.width*config.requested_uniform_source_scale+.5)
 local scale=targetSize/raw.width
 local targetHeight=math.floor(raw.height*scale+.5)
 local offset=Point(math.floor(140-config.source_ground_x*scale+.5),math.floor(229-groundY*scale+.5))
 local scaled={}
 for _,im in ipairs({body,sword,gloves}) do
  local copy=Image(im);copy:resize{width=targetSize,height=targetHeight,method=pixel and 'nearest' or 'bilinear'}
  clean(copy,pixel)
  scaled[#scaled+1]=copy
 end
 -- Ground on the actual exported sole after alpha cleanup, not faint raw edge
 -- pixels which can reach the generator's canvas boundary.
 local soleImage=Image(scaled[1]);soleImage:drawImage(scaled[3])
 local sole=bounds(soleImage);offset.y=229-(sole[2]+sole[4]-1)
 local native={}
 for _,im in ipairs(scaled) do
  local canvas=Image(280,280,ColorMode.RGB);canvas:drawImage(im,offset);native[#native+1]=canvas
 end
 local sp=sprite_from_layers(native,{'01 Body','02 Rigid sword','03 Foreground gloves'},source..'/'..id..'_native.aseprite')
 if pixel then
  local pal=Palette(#palette+1);pal:setColor(0,Color{r=0,g=0,b=0,a=0})
  for i,c in ipairs(palette) do pal:setColor(i,Color{r=c[1],g=c[2],b=c[3],a=255}) end
  sp:setPalette(pal);sp:saveAs(source..'/'..id..'_native.aseprite')
 end
 local assembled=Image(sp)
 assembled:saveAs(base..'/'..id..'_assembled.png')
 local noSword=Image(280,280,ColorMode.RGB);noSword:drawImage(native[1]);noSword:drawImage(native[3])
 noSword:saveAs(base..'/'..id..'_body_gloves.png');native[2]:saveAs(base..'/'..id..'_sword.png');native[3]:saveAs(base..'/'..id..'_gloves.png')
 sp.layers[2].isVisible=false;assert(same(Image(sp),noSword),'Sword is not independently removable')
 sp.layers[2].isVisible=true;sp:close()
 local loaded=app.open(source..'/'..id..'_native.aseprite')
 assert(#loaded.layers==3 and #loaded.frames==1 and same(Image(loaded),assembled))
 loaded.layers[2].isVisible=false;assert(same(Image(loaded),noSword),'Persisted sword removal failed');loaded:close()
 local st=stats(assembled)
 local bb=st.bounds;assert(bb[1]>3 and bb[2]>3 and bb[1]+bb[3]<276 and bb[2]+bb[4]<276,'Clipping')
 assert(not pixel or (st.visible_colors<=47 and st.alpha_levels==2))
 report.variants[id]={source_size={raw.width,raw.height},actual_uniform_scale=scale,
  canvas_offset={offset.x,offset.y},source_ground_y=groundY,stats=st,body_gloves_stats=stats(noSword),
  sword_stats=stats(native[2]),glove_stats=stats(native[3]),
  guard_canvas={gx*scale+offset.x,gy*scale+offset.y},
  blade_length_native=bl*scale,grip_lateral_from_pivot=gx*scale+offset.x-140,
  grip_points_canvas={{(gx-ux*65)*scale+offset.x,(gy-uy*65)*scale+offset.y},
                      {(gx-ux*140)*scale+offset.x,(gy-uy*140)*scale+offset.y}},
  sword_axis_unit={ux,uy},sword_tip_source={tx+ux*bl,ty+uy*bl},
  sword_axis_cross_product=math.abs((tx+ux*bl-px)*uy-(ty+uy*bl-py)*ux),
  source_roundtrip_exact=true,sword_removal_verified=true}
 variants[#variants+1]={id=id,assembled=assembled,body=noSword,sword=native[2],gloves=native[3],master=masterRender,scale=scale,offset=offset}
end

local ink=pc.rgba(232,223,204,255);local gold=pc.rgba(193,151,83,255)
local muted=pc.rgba(161,171,177,255);local bg=pc.rgba(25,29,32,255)
local function text(im,str,x,y,s,c)
 for ch in str:gmatch('.') do local g=glyphs[ch]
  if g then local yy=0;for line in g:gmatch('[^/]+') do
   for xx=1,#line do if line:sub(xx,xx)=='1' then im:clear(Rectangle(x+(xx-1)*s,y+yy*s,s,s),c) end end
   yy=yy+1
  end end;x=x+6*s
 end
end
local function resized(im,w,h,method) local c=Image(im);c:resize{width=w,height=h,method=method or 'nearest'};return c end
local function saveboard(im,name)
 im:saveAs(base..'/'..name..'.png')
 local sp=sprite_from_layers({im},{'Static review composition / current game ground'},source..'/'..name..'.aseprite');sp:close()
end
local world=json.decode(read(root..'/resources/data/presentation/world_art.json'))
local function prop(im,id,x,y)
 local p=world.assets[id];local image=Image{fromFile=root..'/'..p.path:gsub('res://','')}
 image:resize{width=p.size[1],height=p.size[2],method='nearest'}
 im:drawImage(image,Point(x-p.pivot[1],y-p.pivot[2]))
end
local function board(v,kind,w,h)
 local im=Image(w,h,ColorMode.RGB)
 local floor=Image{fromFile=root..'/assets/combat/environment/floors/'..kind..'.png'}
 for y=0,h-1,512 do for x=0,w-1,512 do im:drawImage(floor,Point(x,y)) end end
 prop(im,'boulder',100,260);prop(im,'bush',w-75,145)
 prop(im,'fallen_log',w-80,h-24);prop(im,'grass',220,h-22)
 local shadow=Image{fromFile=root..'/assets/combat/environment/contact_shadow.png'}
 shadow:resize{width=90,height=26,method='bilinear'}
 im:drawImage(shadow,Point(w//2-45,249));im:drawImage(v.assembled,Point(w//2-140,260-229))
 return im
end
local comparison=Image(1600,1330,ColorMode.RGB);comparison:clear(bg)
text(comparison,'RYCERZ / MIECZ BARDZIEJ Z BOKU',30,24,4,ink)
text(comparison,'RECE PRZY BARKU / PIONOWE OSTRZE / KOREKTA WEDLUG REFERENCJI',30,73,2,muted)
for i,v in ipairs(variants) do local x=(i-1)*800
 text(comparison,i==1 and 'A / PIXEL ART' or 'B / MALARSTWO 2D',x+30,116,3,gold)
 text(comparison,'SKALA PLANSZY 1X / 100 PX NA METR',x+30,154,2,muted)
 local scene=board(v,'woodland',740,320);comparison:drawImage(scene,Point(x+30,184))
 scene:saveAs(base..'/'..v.id..'_board_1x.png')
 text(comparison,'POZA / NATYWNE PIKSELE 3X',x+30,530,2,gold)
 comparison:drawImage(resized(Image(v.assembled,Rectangle(85,4,135,230)),405,690),Point(x+5,572))
 text(comparison,'OBIE REKAWICE / 6X',x+430,590,2,muted)
 comparison:drawImage(resized(Image(v.assembled,Rectangle(101,88,35,38)),210,228),Point(x+455,626))
 text(comparison,'TWARZ / 7X',x+455,895,2,muted)
 comparison:drawImage(resized(Image(v.assembled,Rectangle(124,60,30,30)),210,210),Point(x+455,930))
end
text(comparison,'STATYCZNE PROPOZYCJE NA TEKSTURACH GRY / POPRZEDNIA POZA ZACHOWANA',30,1295,2,muted)
saveboard(comparison,'comparison')

local close=Image(1600,1190,ColorMode.RGB);close:clear(bg)
text(close,'MIECZ Z BOKU / DETAL I CHWYT',30,24,4,ink)
text(close,'A: NATYWNE PIKSELE 4X / B: MALOWANE ZRODLO W TEJ SAMEJ SKALI',30,73,2,muted)
for i,v in ipairs(variants) do local x=(i-1)*800
 text(close,i==1 and 'A / SZCZEGOLOWY PIXEL ART' or 'B / MALARSTWO 2D',x+30,120,3,gold)
 local hi=Image(1120,1120,ColorMode.RGB)
 if i==1 then hi=resized(v.assembled,1120,1120)
 else
  local w=math.floor(v.master.width*v.scale*4+.5)
  local h=math.floor(v.master.height*v.scale*4+.5)
  hi:drawImage(resized(v.master,w,h,'bilinear'),Point(v.offset.x*4,v.offset.y*4))
 end
 close:drawImage(Image(hi,Rectangle(340,16,540,920)),Point(x-30,185))
 text(close,'OBIE DLONIE',x+520,255,2,muted)
 local hands=Image(hi,Rectangle(404,352,144,152))
 close:drawImage(resized(hands,216,228),Point(x+520,292))
 text(close,'MIECZ / WARSTWA',x+500,590,2,muted)
 close:drawImage(resized(Image(v.sword,Rectangle(100,4,35,130)),70,260),Point(x+570,625))
end
text(close,'OSTRZE I REKOJESC NA JEDNEJ OSI / TWARZ I OBA CHWYTY CZYTELNE',30,1150,2,muted)
saveboard(close,'closeup')

local layers=Image(1600,800,ColorMode.RGB);layers:clear(bg)
text(layers,'WARSTWY / CIALO I REKAWICE / SZTYWNY MIECZ',25,25,3,ink)
for i,v in ipairs(variants) do local x=(i-1)*800
 text(layers,i==1 and 'A / PIXEL' or 'B / MALARSTWO',x+30,85,2,gold)
 text(layers,'BEZ MIECZA',x+40,127,2,muted);text(layers,'TYLKO MIECZ',x+440,127,2,muted)
 layers:drawImage(resized(Image(v.body,Rectangle(95,42,135,192)),405,576),Point(x+0,170))
 layers:drawImage(resized(Image(v.sword,Rectangle(100,4,35,130)),140,520),Point(x+450,180))
end
saveboard(layers,'layer_review')
local ground=Image(1600,790,ColorMode.RGB);ground:clear(bg)
text(ground,'POZA BOJOWA / SKALA PLANSZY 1X',30,22,3,ink)
text(ground,'AKTUALNE PODLOZE I ROZMIARY OBIEKTOW / KOMPOZYCJA STATYCZNA',30,58,2,muted)
for i,v in ipairs(variants) do local x=(i-1)*800
 text(ground,i==1 and 'A / PIXEL ART' or 'B / MALARSTWO',x+30,95,2,gold)
 for j,kind in ipairs({'earth','woodland'}) do ground:drawImage(board(v,kind,740,300),Point(x+30,125+(j-1)*325)) end
end
saveboard(ground,'board_scale')
local beforeAfter=Image(1600,1020,ColorMode.RGB);beforeAfter:clear(bg)
text(beforeAfter,'POZYCJA MIECZA / PRZED I PO KOREKCIE',30,24,4,ink)
text(beforeAfter,'TA SAMA SKALA POSTACI / MALARSTWO 2D / NATYWNE PIKSELE 3X',30,73,2,muted)
text(beforeAfter,'PRZED / RECE PRZED TULOWIEM',30,122,3,muted)
text(beforeAfter,'TERAZ / RECE PRZY BOKU I BARKU',830,122,3,gold)
local old=Image{fromFile=root..'/assets_src/characters/drawn_knight_guard/2026-11-03/painted_assembled.png'}
beforeAfter:drawImage(resized(Image(old,Rectangle(85,4,135,230)),405,690),Point(145,180))
beforeAfter:drawImage(resized(Image(variants[2].assembled,Rectangle(85,4,135,230)),405,690),Point(945,180))
text(beforeAfter,'OBIE DLONIE PRZENIESIONE DO BOKU / OSTRZE PRAWIE PIONOWE',30,925,2,gold)
text(beforeAfter,'REFERENCJA POZY: POZYCJA_MIECZA.WEBP / TOZSAMOSC I STROJ RYCERZA ZACHOWANE',30,974,2,muted)
saveboard(beforeAfter,'before_after')
local f=assert(io.open(base..'/normalization.json','w'));f:write(json.encode(report));f:close()
print('DRAWN_KNIGHT_SIDE_GUARD_ASEPRITE_PASS '..json.encode(report))
