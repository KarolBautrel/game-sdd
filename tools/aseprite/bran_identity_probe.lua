-- Native-coordinate contact sheets for recording identity edit masks.
local root=assert(app.params.root)
local base=root..'/assets_src/characters/drawn_animation/2026-11-03/'
local out=root..'/artifacts/bran-identity/'
local pc=app.pixelColor
local views={'south_east','south','east','north_east','north'}
local actions={'neutral_idle','combat_idle','neutral_walk','combat_walk','attack','hit','death'}
local function home(id,v)return base..id..(v=='south_east' and '' or '/directions/'..v) end
local function read(p)local f=assert(io.open(p));local d=json.decode(f:read('*a'));f:close();return d end
local report={}
for _,view in ipairs(views) do
 local board=Image(384*8,320*#actions,ColorMode.RGB)
 report[view]={}
 for row,action in ipairs(actions) do
  report[view][action]={}
  local meta=read(home('knight',view)..'/manifest.json')
  local count
  for _,clip in ipairs(meta.clips) do if clip.id==action then count=clip.frames end end
  for n=0,count-1 do
   local im=Image{fromFile=string.format(home('knight',view)..'/frames/'..action..'/%03d.png',n)}
   local top,cx=nil,nil
   local seen,best={},0
   local ymax=action=='death' and 265 or 145
   for y=85,ymax do for x=100,280 do
    local function warm(xx,yy)
     if xx<100 or xx>280 or yy<85 or yy>ymax then return false end
     local p=im:getPixel(xx,yy);local r,g,b,a=pc.rgbaR(p),pc.rgbaG(p),pc.rgbaB(p),pc.rgbaA(p)
     return a>180 and r>140 and g>90 and b>65 and r-g>20 and g-b>16 and r-g<75
    end
    local key=y*384+x
    if not seen[key] and warm(x,y) then
     local q={{x,y}};seen[key]=true;local k,sum,miny=0,0,320
     for _,p in ipairs(q) do
      k=k+1;sum=sum+p[1];miny=math.min(miny,p[2])
      for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
       local xx,yy=p[1]+d[1],p[2]+d[2];local kk=yy*384+xx
       if not seen[kk] and warm(xx,yy) then seen[kk]=true;q[#q+1]={xx,yy} end
      end
     end
     if k>best then best=k;cx=math.floor(sum/k+.5);top=miny-8 end
    end
   end end
   report[view][action][n+1]={cx,top}
   if cx then
    local red=pc.rgba(255,70,50,255)
    for x=cx-18,cx+18 do im:drawPixel(x,top-2,red);im:drawPixel(x,top+32,red) end
    for y=top-2,top+32 do im:drawPixel(cx-18,y,red);im:drawPixel(cx+18,y,red) end
   end
   board:drawImage(im,Point(n*384,(row-1)*320))
  end
 end
 board:saveAs(out..view..'-probe.png')
end
local f=assert(io.open(out..'head-probe.json','w'));f:write(json.encode(report));f:close()
local refs=Image(384*5,320*2,ColorMode.RGB)
for i,v in ipairs(views) do for j,id in ipairs({'warrior','knight'}) do
 refs:drawImage(Image{fromFile=home(id,v)..'/frames/neutral_idle/000.png'},Point((i-1)*384,(j-1)*320))
end end
refs:saveAs(out..'head-references.png')
print('BRAN_HEAD_PROBE_PASS')
