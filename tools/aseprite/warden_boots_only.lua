-- Stage43: the exact reviewed armor/face/pose, modest original-foot shrink only.
local root=assert(app.params.root)
local out=root..'/assets_src/characters/mpfb_warden_boots_only/2026-11-02'
local before=root..'/assets_src/characters/mpfb_warden/2026-11-02'
local pc=app.pixelColor
local file=assert(io.open(root..'/tools/aseprite/style_studies.lua','r'))
local src=file:read('*a');file:close()
local glyphs=assert(load('return '..assert(src:match('local glyphs=(%b{})'))))()
local ink=pc.rgba(232,223,204,255);local gold=pc.rgba(193,151,83,255)
local muted=pc.rgba(161,171,177,255);local bg=pc.rgba(25,29,32,255)
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
local function load(base,name,size)
 local im=Image{fromFile=base..'/renders/'..name..'.png'}
 im:resize{width=size,height=size,method='bilinear'};return im
end
local board=Image(1600,1280,ColorMode.RGB);board:clear(bg)
text(board,'PRZYWROCONY STRAZNIK / TYLKO BUTY',36,24,4,ink)
text(board,'POPRZEDNIA ZBROJA / TWARZ / POSTAWA / TEKSTURY ZACHOWANE',38,75,2,muted)
text(board,'PRZED',40,124,2,muted);text(board,'LEKKO MNIEJSZA STOPA BUTA',840,124,2,gold)
board:drawImage(load(before,'three_quarter',640),Point(80,115))
board:drawImage(load(out,'three_quarter',640),Point(880,115))
text(board,'BUTY / TEN SAM KADR I SWIATLO',38,790,3,gold)
board:drawImage(load(out,'before_boots',400),Point(200,840))
board:drawImage(load(out,'boots',400),Point(1000,840))
text(board,'STOPA BUTA -6 PROCENT / WYSOKOSC I GORNA CHOLEWKA BEZ ZMIAN',38,1250,2,muted)
local sp=Sprite(board.width,board.height,ColorMode.RGB);sp.cels[1].image=board
sp.layers[1].name='Restored original model / only original boots reduced'
sp:saveAs(out..'/proposal.aseprite');sp:saveAs(out..'/proposal.png');sp:close()
print('WARDEN_BOOTS_ONLY_ASEPRITE_PASS')
