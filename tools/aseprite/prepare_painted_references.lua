-- Normalize original concept plates for texture projection, not model evidence.
-- Flood-fill ONLY connected neutral backdrop; preserve enclosed pale skin/steel.
-- Extend edge paint 48px into the cleared background to give projection padding.
local root=assert(app.params.root)
local base=root..'/assets_src/characters/painted_candidates/2026-11-02'
local pc=app.pixelColor
for _,id in ipairs({'01_mercenary','02_warden','03_wayfarer'}) do
 local im=Image{fromFile=base..'/'..id..'/concept.png'}
 local w,h=im.width,im.height
 local eligible,background={},{}
 for it in im:pixels() do
  local p=it();local r,g,b=pc.rgbaR(p),pc.rgbaG(p),pc.rgbaB(p)
  eligible[it.y*w+it.x+1]=b>142 and math.max(r,g,b)-math.min(r,g,b)<26 and r<226
 end
 local queue={};local cursor=1
 local function add(k)
  if eligible[k] and not background[k] then background[k]=true;queue[#queue+1]=k end
 end
 for x=0,w-1 do add(x+1);add((h-1)*w+x+1) end
 for y=0,h-1 do add(y*w+1);add(y*w+w) end
 local function neighbors(k,fn)
  local x=(k-1)%w;local y=(k-1)//w
  if x>0 then fn(k-1) end;if x<w-1 then fn(k+1) end
  if y>0 then fn(k-w) end;if y<h-1 then fn(k+w) end
 end
 while cursor<=#queue do local k=queue[cursor];cursor=cursor+1;neighbors(k,add) end
 local backdropCount=#queue
 local profiles={}
 for _,view in ipairs({'front','side','back'}) do
  local column=({front=0,side=1,back=2})[view];local rows={}
  for y=0,h-1 do
   local runs={};local start=nil
   for x=column*512,(column+1)*512 do
    local inside=x<(column+1)*512 and not background[y*w+x+1]
    if inside and not start then start=x end
    if not inside and start then
     if x-start>=6 then runs[#runs+1]='['..start..','..(x-1)..']' end
     start=nil
    end
   end
   rows[#rows+1]='['..table.concat(runs,',')..']'
  end
  profiles[#profiles+1]='"'..view..'":['..table.concat(rows,',')..']'
 end
 local profileFile=assert(io.open(base..'/'..id..'/projection-silhouette.json','w'))
 profileFile:write('{'..table.concat(profiles,',')..'}');profileFile:close()
 eligible=nil;queue={};cursor=1
 local out=Image(im)
 for k,_ in pairs(background) do out:drawPixel((k-1)%w,(k-1)//w,0) end
 local distance,colors={},{}
 for k,_ in pairs(background) do
  neighbors(k,function(n)
   if not background[n] and distance[n]==nil then
    distance[n]=0;colors[n]=im:getPixel((n-1)%w,(n-1)//w);queue[#queue+1]=n
   end
  end)
 end
 while cursor<=#queue do
  local k=queue[cursor];cursor=cursor+1;local d=distance[k]
  if d<48 then neighbors(k,function(n)
   if background[n] and distance[n]==nil then
    distance[n]=d+1;colors[n]=colors[k];queue[#queue+1]=n
    out:drawPixel((n-1)%w,(n-1)//w,colors[k])
   end
  end) end
 end
 out:saveAs(base..'/'..id..'/projection-padded.png')
 local sp=Sprite(w,h,ColorMode.RGB);sp.cels[1].image=out
 sp.layers[1].name='Original AI paint / connected backdrop removal / 48px edge padding'
 sp:saveAs(base..'/'..id..'/projection-padded.aseprite');sp:close()
 print('PAINTED_REFERENCE_PASS '..id..' backdrop_pixels='..backdropCount..' padded_pixels='..#queue)
end
