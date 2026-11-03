-- Presentation022. Actual redrawn source poses, editable clips and native export.
local root=assert(app.params.root)
local id=app.params.id or 'knight'
local view=app.params.view or 'three_quarter'
local suffix=id..(view~='three_quarter' and '/directions/'..view or '')
local base=root..'/assets_src/characters/drawn_animation/2026-11-03/'..suffix
local source=root..'/assets_src/aseprite/characters/drawn_animation/2026-11-03/'..suffix
local pc=app.pixelColor
local function read(path) local f=assert(io.open(path,'r'));local s=f:read('*a');f:close();return json.decode(s) end
local function save(path,value) local f=assert(io.open(path,'w'));f:write(json.encode(value));f:close() end
local cfg=read(base..'/clips_source.json')
local W,H,PX,PY=384,320,192,270
local function neon(p)
 local r,g,b=pc.rgbaR(p),pc.rgbaG(p),pc.rgbaB(p)
 if id~='knight' and not cfg.cleanup_neon then
  return (r>220 and g<45 and b<65) or (g>220 and r<70 and b<70) or (r>220 and b>220 and g<45)
 end
 return (r>150 and g<75 and b<85) or (g>120 and g>r*1.35 and g>b*1.5) or (r>150 and b>150 and g<65)
end
local function clean_sheet(im,matte)
 for it in im:pixels() do local p=it();local a=pc.rgbaA(p)
  if a<32 or neon(p) then it(0)
  elseif matte then
   local r,g,b=pc.rgbaR(p),pc.rgbaG(p),pc.rgbaB(p)
   if a<=196 or (math.min(r,g,b)>205 and math.max(r,g,b)-math.min(r,g,b)<25 and a<250) then it(0)
   else it(pc.rgba(r,g,b,math.floor(math.min(1,(a-196)/59)*255))) end
  end
 end
end
-- Source layouts are drafts. Find actual separate figures per row rather than
-- clipping a lunge/corpse to an assumed equally spaced cell boundary.
local function components(im,y0,y1)
 local width=im.width;local height=y1-y0+1;local active,seen={},{}
 for y=y0,y1 do for x=0,width-1 do
  if pc.rgbaA(im:getPixel(x,y))>=96 then active[(y-y0)*width+x]=true end
 end end
 local result={}
 for yy=0,height-1 do for xx=0,width-1 do local start=yy*width+xx
  if active[start] and not seen[start] then
   local q={start};seen[start]=true;local qi=1
   local c={pixels={},x0=xx,y0=yy,x1=xx,y1=yy,sumx=0,sumy=0}
   while qi<=#q do local index=q[qi];qi=qi+1
    local x=index%width;local y=index//width
    c.pixels[#c.pixels+1]=index;c.sumx=c.sumx+x;c.sumy=c.sumy+y
    c.x0=math.min(c.x0,x);c.x1=math.max(c.x1,x);c.y0=math.min(c.y0,y);c.y1=math.max(c.y1,y)
    for _,d in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do
     local nx,ny=x+d[1],y+d[2]
     if nx>=0 and nx<width and ny>=0 and ny<height then
      local ni=ny*width+nx
      if active[ni] and not seen[ni] then seen[ni]=true;q[#q+1]=ni end
     end
    end
   end
   c.count=#c.pixels;c.cx=c.sumx/c.count;c.cy=c.sumy/c.count;result[#result+1]=c
  end
 end end
 table.sort(result,function(a,b)return a.count>b.count end)
 return result,width,y0
end
local sheets={}
for name,spec in pairs(cfg.sheets) do
 local im=Image{fromFile=base..'/raw/'..name..'.png'}
 clean_sheet(im,spec.matte or false)
 local rows={};local details={}
 -- Generated row spacing is not mathematically uniform. Segment entire figures
 -- before assigning grid order; an equal-height crop can silently cut off boots.
 local cs,width=components(im,0,im.height-1)
 local expected=spec.cols*spec.rows
 assert(#cs>=expected,'Missing figures '..name..' '..#cs)
 local main={};for n=1,expected do main[n]=cs[n] end
 table.sort(main,function(a,b)return a.cy<b.cy end)
 local ordered={}
 for row=0,spec.rows-1 do
  local group={};for col=1,spec.cols do group[col]=main[row*spec.cols+col] end
  table.sort(group,function(a,b)return a.cx<b.cx end)
  for col,c in ipairs(group) do c.col=col-1;c.row=row;ordered[#ordered+1]=c end
 end
 for _,c in ipairs(ordered) do
   local col,row=c.col+1,c.row
   assert(c.x1-c.x0<im.width/spec.cols*1.45,'Merged source figures '..name)
   local mask={};for _,p in ipairs(c.pixels) do mask[p]=true end
   -- Attach only nearby smaller islands belonging to this figure, e.g. a free
   -- scabbard tip. Saturated generation residue has already been removed.
   for n=expected+1,#cs do local small=cs[n]
    if small.count>=18 and small.count<c.count*.15 then
     local nearest=1;local distance=math.huge
     for k,m in ipairs(ordered) do local d=((small.cx-m.cx)/(im.width/spec.cols))^2+((small.cy-m.cy)/(im.height/spec.rows))^2;if d<distance then nearest=k;distance=d end end
     if ordered[nearest]==c and small.x0>=c.x0-24 and small.x1<=c.x1+24 and small.y0>=c.y0-15 and small.y1<=c.y1+15 then
      for _,p in ipairs(small.pixels) do mask[p]=true end
     end
    end
   end
   local y0=math.max(0,c.y0-16);local y1=math.min(im.height-1,c.y1+16)
   local frame=Image(im.width,y1-y0+1,ColorMode.RGB)
   for p in pairs(mask) do local x=p%width;local y=p//width
    frame:drawPixel(x,y-y0,im:getPixel(x,y))
   end
   -- Retain antialias pixels immediately beside the selected opaque component.
   for y=math.max(0,c.y0-1),math.min(im.height-1,c.y1+1) do for x=math.max(0,c.x0-1),math.min(frame.width-1,c.x1+1) do
    local p=im:getPixel(x,y)
    if pc.rgbaA(p)>=32 and not mask[y*width+x] and
     (mask[y*width+x-1] or mask[y*width+x+1] or mask[(y-1)*width+x] or mask[(y+1)*width+x]) then frame:drawPixel(x,y-y0,p) end
   end end
   local index=row*spec.cols+col
   rows[index]={image=frame,bounds={c.x0,c.y0-y0,c.x1-c.x0+1,c.y1-c.y0+1},
    col=col-1,row=row,width=im.width/spec.cols,source_name=name}
   details[index]={bounds={c.x0,c.y0,c.x1-c.x0+1,c.y1-c.y0+1},pixels=c.count,col=col-1,row=row}
 end
 sheets[name]=rows
 save(base..'/'..name..'_cells.json',{width=im.width,height=im.height,frames=details,matte_removed=spec.matte or false})
end
local function foot_center(frame)
 local b=frame.bounds;local x0,x1=10000,-1
 for y=math.floor(b[2]+b[4]*.86),b[2]+b[4]-1 do for x=b[1],b[1]+b[3]-1 do
  if pc.rgbaA(frame.image:getPixel(x,y))>=128 then x0=math.min(x0,x);x1=math.max(x1,x) end
 end end
 return (x0+x1)/2
end
local function head_center(frame,height)
 local b=frame.bounds;local y1=math.min(frame.image.height-1,math.floor(b[2]+height*.20))
 local cs=components(frame.image,b[2],y1)
 if #cs>0 then return cs[1].cx end
 return foot_center(frame)
end
local function body_height(frame)
 local b=frame.bounds;local cx=foot_center(frame);local half=b[4]*.19
 local threshold=math.max(7,math.floor(b[4]*.05));local consecutive=0
 for y=b[2],b[2]+b[4]-1 do local count=0
  for x=math.max(0,math.floor(cx-half)),math.min(frame.image.width-1,math.ceil(cx+half)) do
   if pc.rgbaA(frame.image:getPixel(x,y))>=128 then count=count+1 end
  end
  consecutive=count>=threshold and consecutive+1 or 0
  if consecutive>=4 then return b[2]+b[4]-(y-3) end
 end
 return b[4]
end
local report={status='TECHNICAL_SOURCE_EXPORT_PASS_VISUAL_REVIEW_PENDING',id=id,
 canvas={W,H},pivot={PX,PY},body_height_target=171,view=view,
 frame_source='redrawn imagegen keyframes; Aseprite segmentation/normalization',clips={},clipping={}}
local manifest={id=id,title=cfg.title,view=view,canvas={W,H},pivot={PX,PY},
 pixels_per_metre=100,body_height=171,clips={},exported_views={view}}
local contact=Image(W*4,H*math.ceil(#cfg.clips/4),ColorMode.RGB)
for clipIndex,clip in ipairs(cfg.clips) do
 local frames={};for n=1,clip.count do frames[n]=sheets[clip.sheet][clip.indices and tonumber(clip.indices[n]) or clip.start+n-1] end
 local first=frames[1];local reference=clip.reference_index and sheets[clip.sheet][clip.reference_index] or first
 local refHeight=clip.reference_height or (cfg.body_scale and body_height(reference)) or reference.bounds[4]
 local scale=171/refHeight
 local root=foot_center(first)-first.col*first.width
 local headX=head_center(first,refHeight)
 local atlas=Image(W*clip.count,H,ColorMode.RGB)
 local sprite=Sprite(W,H,ColorMode.RGB);sprite.layers[1].name='Painted redrawn action frames'
 local metrics={};local durations={};local outDir=base..'/frames/'..clip.id;app.fs.makeAllDirectories(outDir)
 for n,frame in ipairs(frames) do
  local sourceRoot=frame.col*frame.width+root
  if clip.align_head then sourceRoot=head_center(frame,refHeight)-(headX-(first.col*first.width+root)) end
  if clip.align_feet then sourceRoot=foot_center(frame) end
  local resized=Image(frame.image)
  resized:resize{width=math.floor(frame.image.width*scale+.5),height=math.floor(frame.image.height*scale+.5),method='bilinear'}
  local target=Image(W,H,ColorMode.RGB)
  local offset=Point(math.floor(PX-sourceRoot*scale+.5)+(clip.offset_x or 0),math.floor(PY-(frame.bounds[2]+frame.bounds[4]-1)*scale+.5))
  target:drawImage(resized,offset)
  local x0,y0,x1,y1=W,H,-1,-1;local opaque=0
  for it in target:pixels() do local p=it();local a=pc.rgbaA(p)
   if a<48 or neon(p) then it(0)
   else x0=math.min(x0,it.x);y0=math.min(y0,it.y);x1=math.max(x1,it.x);y1=math.max(y1,it.y);opaque=opaque+1 end
  end
  assert(opaque>1000,'Empty/too small frame '..clip.id)
  if x0<3 or y0<3 or x1>W-4 or y1>H-4 then report.clipping[#report.clipping+1]={clip=clip.id,frame=n,bounds={x0,y0,x1,y1}} end
  local duration=tonumber(clip.durations) or tonumber(clip.durations[n]);durations[n]=duration
  if n==1 then sprite.cels[1].image=target else sprite:newEmptyFrame();sprite:newCel(sprite.layers[1],n,target,Point(0,0)) end
  sprite.frames[n].duration=duration/1000
  target:saveAs(string.format(outDir..'/%03d.png',n-1));atlas:drawImage(target,Point((n-1)*W,0))
  metrics[n]={source_bounds=frame.bounds,source_root=sourceRoot,offset={offset.x,offset.y},bounds={x0,y0,x1,y1},pixels=opaque,duration_ms=duration}
 end
 sprite:newTag(1,clip.count).name=clip.id
 sprite:saveAs(source..'/'..clip.id..'.aseprite');sprite:close()
 atlas:saveAs(base..'/'..clip.id..'.png')
 -- Read the saved editable source rather than trusting only in-memory exports.
 local reopened=assert(app.open(source..'/'..clip.id..'.aseprite'))
 assert(#reopened.frames==clip.count,'Saved source frame count '..clip.id)
 assert(reopened.width==W and reopened.height==H,'Saved source canvas '..clip.id)
 assert(#reopened.tags==1 and reopened.tags[1].name==clip.id,'Saved source tag '..clip.id)
 for n=1,clip.count do
  local raster=Image(W,H,ColorMode.RGB);raster:drawSprite(reopened,n)
  local exported=Image{fromFile=string.format(outDir..'/%03d.png',n-1)}
  assert(math.abs(reopened.frames[n].duration*1000-durations[n])<1,'Saved duration '..clip.id)
  for it in raster:pixels() do assert(it()==exported:getPixel(it.x,it.y),'Saved source pixels '..clip.id..' '..n) end
 end
 reopened:close()
 local entry={id=clip.id,title=clip.title,mode=clip.mode,loop=clip.loop,frames=clip.count,durations=durations,
  atlas=clip.id..'.png',source_sheet=clip.sheet,source_first=clip.start,frame_source='redrawn',scale=scale}
 manifest.clips[#manifest.clips+1]=entry
 report.clips[clip.id]={frame_count=clip.count,scale=scale,reference_height=refHeight,metrics=metrics}
 local thumb=Image(atlas,Rectangle(0,0,W,H));contact:drawImage(thumb,Point(((clipIndex-1)%4)*W,math.floor((clipIndex-1)/4)*H))
 print('DRAWN_CLIP '..id..' '..clip.id..' '..clip.count)
end
report.saved_source_roundtrip='PASS'
contact:saveAs(base..'/contact.png');save(base..'/export_report.json',report)
assert(#report.clipping==0,'Clipped native frames '..json.encode(report.clipping))
save(base..'/manifest.json',manifest)
print('DRAWN_ACTION_SHEETS_PASS '..id..' '..#cfg.clips)
