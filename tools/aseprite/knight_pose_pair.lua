-- Presentation021: two exploratory painted poses, not production sprites.
local root=assert(app.params.root)
local base=root..'/assets_src/characters/drawn_knight_pose_pair/2026-11-03'
local src=root..'/assets_src/aseprite/characters/drawn_knight_pose_pair/2026-11-03'
local pc=app.pixelColor
local f=assert(io.open(root..'/tools/aseprite/style_studies.lua','r'))
local glyphs=assert(load('return '..assert(f:read('*a'):match('local glyphs=(%b{})'))))();f:close()
local function text(im,str,x,y,s,c)
 for ch in str:gmatch('.') do local g=glyphs[ch]
  if g then local yy=0;for line in g:gmatch('[^/]+') do
   for xx=1,#line do if line:sub(xx,xx)=='1' then im:clear(Rectangle(x+(xx-1)*s,y+yy*s,s,s),c) end end
   yy=yy+1
  end end;x=x+6*s
 end
end
local function source(im,name)
 local sp=Sprite(im.width,im.height,ColorMode.RGB);sp.cels[1].image=im
 sp.layers[1].name='Painted pose concept / two hands / no production separation'
 sp:saveAs(src..'/'..name..'.aseprite');sp:close()
end
local ink=pc.rgba(232,223,204,255);local gold=pc.rgba(193,151,83,255)
local muted=pc.rgba(161,171,177,255);local black=pc.rgba(0,0,0,255)
local comparison=Image(1600,1060,ColorMode.RGB);comparison:clear(black)
text(comparison,'RYCERZ / DWIE POZYCJE WEDLUG ZDJEC',30,24,4,ink)
text(comparison,'OBIE PROBKI: CHWYT DWURECZNY / JELEC POWYZEJ PASA',30,76,2,muted)
local grips=Image(1600,740,ColorMode.RGB);grips:clear(black)
text(grips,'CHWYT Z BLISKA / OBIE POZYCJE',30,24,4,ink)
text(grips,'OSOBNE REFERENCJE POZY / TEN SAM RYCERZ I WYKONCZENIE',30,76,2,muted)
local cfgs={
 {id='front',hair=85,sole=1497,groundx=330,title='A / MIECZ WYSUNIETY Z PRZODU',note='DLONIE DALEJ OD CIALA / OSTRZE UKOSNIE',crop={300,475,430,340}},
 {id='side',hair=149,sole=1515,groundx=475,title='B / MIECZ PRZY BOKU',note='LOKCIE BLIZEJ TULOWIA / OSTRZE PRAWIE PIONOWE',crop={300,500,430,340}}
}
local metadata={status='TWO_PAINTED_POSE_CONCEPTS_PENDING_REVIEW',two_handed=true,
 background='Black review composition; production alpha/weapon-layer cleanup is not claimed for these pose concepts.',
 aseprite=tostring(app.version),variants={}}
for i,cfg in ipairs(cfgs) do
 local x=(i-1)*800;local im=Image{fromFile=base..'/'..cfg.id..'.png'}
 source(im,cfg.id)
 local scale=680/(cfg.sole-cfg.hair+1)
 local image=Image(im);image:resize{width=math.floor(im.width*scale+.5),height=math.floor(im.height*scale+.5),method='bilinear'}
 comparison:drawImage(image,Point(math.floor(x+400-cfg.groundx*scale+.5),math.floor(940-cfg.sole*scale+.5)))
 text(comparison,cfg.title,x+30,125,3,gold);text(comparison,cfg.note,x+30,170,2,muted)
 text(grips,cfg.title,x+30,125,3,gold)
 local r=cfg.crop;local detail=Image(im,Rectangle(r[1],r[2],r[3],r[4]))
 detail:resize{width=650,height=514,method='bilinear'}
 grips:drawImage(detail,Point(x+75,174))
 metadata.variants[cfg.id]={source_size={im.width,im.height},manual_hair_top=cfg.hair,
  manual_sole=cfg.sole,comparison_body_height=680,comparison_scale=scale,
  hands=2,production_weapon_layers=false}
end
text(comparison,'PROBKI POZ DO OCENY / BEZ ANIMACJI I PODMIANY POSTACI W GRZE',30,1015,2,muted)
text(grips,'A: WYSUNIECIE DO PRZODU / B: UGIETE LOKCIE PRZY BOKU / JELEC NAD PASEM',30,706,2,muted)
comparison:saveAs(base..'/comparison.png');source(comparison,'comparison')
grips:saveAs(base..'/grips.png');source(grips,'grips')
local out=assert(io.open(base..'/normalization.json','w'));out:write(json.encode(metadata));out:close()
print('KNIGHT_POSE_PAIR_ASEPRITE_PASS')
