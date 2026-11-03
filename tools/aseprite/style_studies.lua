-- Actual model comparison assembly. No production sprite is modified.
local root=assert(app.params.root)
local base=root..'/assets_src/characters/style_studies/2026-11-02'
local pc=app.pixelColor
local ids={'a_painterly_veteran','b_ink_warden','c_heroic_miniature'}
local titles={'A / MALARSKI WETERAN','B / MROCZNY KOMIKS','C / HEROICZNA FIGURKA'}
local notes={'SKORA I WELNA / BRYGANTYNA','KONTUR / PLASKIE PLAMY SWIATLA','WIEKSZA TWARZ / MOCNA SYLWETKA'}
local glyphs={
A='01110/10001/10001/11111/10001/10001/10001',B='11110/10001/10001/11110/10001/10001/11110',C='01111/10000/10000/10000/10000/10000/01111',
D='11110/10001/10001/10001/10001/10001/11110',E='11111/10000/10000/11110/10000/10000/11111',F='11111/10000/10000/11110/10000/10000/10000',
G='01111/10000/10000/10111/10001/10001/01111',H='10001/10001/10001/11111/10001/10001/10001',I='11111/00100/00100/00100/00100/00100/11111',
J='00111/00010/00010/00010/10010/10010/01100',K='10001/10010/10100/11000/10100/10010/10001',L='10000/10000/10000/10000/10000/10000/11111',
M='10001/11011/10101/10101/10001/10001/10001',N='10001/11001/11001/10101/10011/10011/10001',O='01110/10001/10001/10001/10001/10001/01110',
P='11110/10001/10001/11110/10000/10000/10000',Q='01110/10001/10001/10001/10101/10010/01101',R='11110/10001/10001/11110/10100/10010/10001',
S='01111/10000/10000/01110/00001/00001/11110',T='11111/00100/00100/00100/00100/00100/00100',U='10001/10001/10001/10001/10001/10001/01110',
V='10001/10001/10001/10001/10001/01010/00100',W='10001/10001/10001/10101/10101/10101/01010',X='10001/10001/01010/00100/01010/10001/10001',
Y='10001/10001/01010/00100/00100/00100/00100',Z='11111/00001/00010/00100/01000/10000/11111',
['0']='01110/10001/10011/10101/11001/10001/01110',['1']='00100/01100/00100/00100/00100/00100/01110',
['2']='01110/10001/00001/00010/00100/01000/11111',['3']='11110/00001/00001/01110/00001/00001/11110',
['4']='00010/00110/01010/10010/11111/00010/00010',['5']='11111/10000/10000/11110/00001/00001/11110',
['6']='01110/10000/10000/11110/10001/10001/01110',['7']='11111/00001/00010/00100/01000/01000/01000',
['8']='01110/10001/10001/01110/10001/10001/01110',['9']='01110/10001/10001/01111/00001/00001/01110',
['/']='00001/00010/00010/00100/01000/01000/10000',['-']='00000/00000/00000/11111/00000/00000/00000',
['.']='00000/00000/00000/00000/00000/00100/00100',[':']='00000/00100/00100/00000/00100/00100/00000'}
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
local ink=pc.rgba(228,218,193,255)
local muted=pc.rgba(157,164,169,255)
local gold=pc.rgba(187,145,77,255)
local function load(id,name,size)
 local im=Image{fromFile=base..'/'..id..'/renders/'..name..'.png'}
 if size then im:resize{width=size,height=size,method='bilinear'} end
 return im
end
local function save(im,name)
 local sp=Sprite(im.width,im.height,ColorMode.RGB);sp.cels[1].image=im
 sp.layers[1].name='Actual Blender renders / Aseprite comparison'
 sp:saveAs(base..'/'..name..'.aseprite');sp:saveAs(base..'/'..name..'.png');sp:close()
end
local W,H=1800,1410
local sheet=Image(W,H,ColorMode.RGB);sheet:clear(pc.rgba(25,29,32,255))
text(sheet,'TRZY KIERUNKI POSTACI',42,30,4,ink)
text(sheet,'PRAWDZIWE MODELE 3D / STATYCZNE PROTOTYPY / BEZ PODMIANY W GRZE',44,77,2,muted)
local earth=Image{fromFile=root..'/assets/combat/environment/floors/earth.png'}
earth:resize{width=256,height=256,method='bilinear'}
local shadow=Image{fromFile=root..'/assets/combat/environment/contact_shadow.png'}
shadow:resize{width=84,height=32,method='bilinear'}
for i,id in ipairs(ids) do
 local x=(i-1)*600
 rect(sheet,x+18,115,564,858,pc.rgba(36,41,45,255))
 rect(sheet,x+18,115,564,3,gold)
 text(sheet,titles[i],x+38,138,3,ink)
 text(sheet,notes[i],x+38,176,2,muted)
 sheet:drawImage(load(id,'three_quarter',660),Point(x-30,200))
 text(sheet,'TWARZ',x+47,763,2,muted);text(sheet,'PROFIL',x+335,763,2,muted)
 sheet:drawImage(load(id,'face',200),Point(x+52,783))
 sheet:drawImage(load(id,'side',275),Point(x+280,751))
 text(sheet,'SKALA PLANSZY / 100 PX NA METR',x+35,1004,2,gold)
 -- Ground texture is retained project art; the character remains exactly384px
 -- canvas at100px/m. This is a reference composite, not a game screenshot.
 local tile=Image(564,292,ColorMode.RGB)
 for xx=0,563,256 do for yy=0,291,256 do tile:drawImage(earth,Point(xx,yy)) end end
 tile:drawImage(shadow,Point(240,216))
 local tact=load(id,'tactical_100ppm')
 tile:drawImage(tact,Point(90,-53))
 sheet:drawImage(tile,Point(x+18,1040))
end
text(sheet,'RENDERY BLENDERA / WSPOLNA KAMERA I SWIATLO / DOL: KOMPOZYCJA NA PODLODZE Z GRY',40,1350,2,muted)
text(sheet,'MODELE NIE MAJA JESZCZE RIGU ANI ANIMACJI. WYBOR STYLU POPRZEDZA WDROZENIE.',40,1380,2,muted)
save(sheet,'comparison')
-- Every real view for inspection, avoiding a flattering single-angle selection.
local views={'front','three_quarter','side','rear'}
local multi=Image(1800,1550,ColorMode.RGB);multi:clear(pc.rgba(25,29,32,255))
text(multi,'PRZOD / 3-4 / BOK / TYL',35,25,3,ink)
for i,id in ipairs(ids) do
 local y=65+(i-1)*490
 text(multi,titles[i],35,y,3,gold)
 for j,v in ipairs(views) do multi:drawImage(load(id,v,465),Point((j-1)*450,y+20)) end
end
save(multi,'all_views')
print('STYLE_COMPARISON_ASEPRITE_PASS')
