local root=assert(app.params.root)
local base=root..'/assets_src/characters/drawn_animation/2026-11-03/knight'
local pc=app.pixelColor;local report={}
for _,spec in ipairs({{'neutral_walk_initial',4,2},{'walk_combat',4,2},{'attacks',4,4},{'reactions',4,4}}) do
 local im=Image{fromFile=base..'/raw/'..spec[1]..'.png'}
 local data={width=im.width,height=im.height,corner=pc.rgbaA(im:getPixel(0,0)),cells={}}
 for row=0,spec[3]-1 do for col=0,spec[2]-1 do
  local x0=math.floor(col*im.width/spec[2]);local y0=math.floor(row*im.height/spec[3])
  local x1=math.floor((col+1)*im.width/spec[2])-1;local y1=math.floor((row+1)*im.height/spec[3])-1
  local minx,miny,maxx,maxy=x1,y1,x0,y0;local count=0
  for y=y0,y1 do for x=x0,x1 do local p=im:getPixel(x,y)
   if pc.rgbaA(p)>=96 then minx=math.min(minx,x);maxx=math.max(maxx,x);miny=math.min(miny,y);maxy=math.max(maxy,y);count=count+1 end
  end end
  data.cells[#data.cells+1]={cell={x0,y0,x1-x0+1,y1-y0+1},bounds={minx-x0,miny-y0,maxx-minx+1,maxy-miny+1},pixels=count}
 end end
 report[spec[1]]=data
end
local f=assert(io.open(base..'/sheet_probe.json','w'));f:write(json.encode(report));f:close()
print(json.encode(report))
