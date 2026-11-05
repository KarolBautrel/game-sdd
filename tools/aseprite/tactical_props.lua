-- Deterministic normalization of stage83's generated painted prop family.
local root=assert(app.params.root,'root required')
local base=app.fs.joinPath(root,'assets_src/tactical_environment/2026-11-05')
local target=app.fs.joinPath(root,'assets/combat/environment/painted_v2')
local editable=app.fs.joinPath(root,'assets_src/aseprite/tactical_environment/painted_props.aseprite')
app.fs.makeAllDirectories(target);app.fs.makeAllDirectories(app.fs.filePath(editable))
local function read(path)local f=assert(io.open(path));local d=json.decode(f:read('*a'));f:close();return d end
local cfg=read(app.fs.joinPath(root,'resources/data/presentation/world_art.json'))
local ids={'oak','pine','dead_tree','bush','stump','fallen_log','boulder','crate','barrel','pillar','broken_pillar','wall','rubble','coffin','brazier','altar'}
if app.params.from_editable=='1' then
 app.command.OpenFile{filename=editable,ui=false};local s=app.activeSprite
 for i,id in ipairs(ids) do
  local p=cfg.assets[id];local out=Image(p.size[1],p.size[2],ColorMode.RGB)
  out:drawImage(s.cels[i].image,Point(0,0));out:saveAs(app.fs.joinPath(target,id..'.png'))
 end
 s:close();print('Exported16 editable painted props');return
end
local source=Image{fromFile=app.fs.joinPath(base,'generated-source.png')}
assert(source.width==source.height,'Expected square source')
local xs={0,342,642,940,1280};local ys={0,360,625,965,1280}
for i=1,5 do xs[i]=math.floor(xs[i]*source.width/1280);ys[i]=math.floor(ys[i]*source.height/1280) end
local pc=app.pixelColor;local sheet=Sprite(384,384,ColorMode.RGB)
sheet.layers[1].name='Painted environment - one prop per frame'
local report={schema='sdd.painted-props-v2',editor=app.version,source_size={source.width,source.height},approval='agent_selected_user_review_pending',assets={}}
for i,id in ipairs(ids) do
 local c=(i-1)%4+1;local r=math.floor((i-1)/4)+1
 local crop=Image(xs[c+1]-xs[c],ys[r+1]-ys[r],ColorMode.RGB)
 crop:drawImage(source,Point(-xs[c],-ys[r]))
 local minx,miny,maxx,maxy=crop.width,crop.height,-1,-1;local fringe=0
 for it in crop:pixels() do
  local p=it();local red,green,blue,alpha=pc.rgbaR(p),pc.rgbaG(p),pc.rgbaB(p),pc.rgbaA(p)
  -- Generated alpha edge occasionally retains saturated matte red/yellow.
  if alpha>0 and ((red>green*1.8 and red>blue*1.8 and red>95) or (red>160 and green>140 and blue<55)) then
   alpha=0;fringe=fringe+1;it(0)
  end
  if alpha>=12 then minx=math.min(minx,it.x);miny=math.min(miny,it.y);maxx=math.max(maxx,it.x);maxy=math.max(maxy,it.y) end
 end
 assert(maxx>=minx,'empty '..id)
 local content=Image(maxx-minx+1,maxy-miny+1,ColorMode.RGB);content:drawImage(crop,Point(-minx,-miny))
 local p=cfg.assets[id];local w,h=p.size[1],p.size[2];local px,py=p.pivot[1],p.pivot[2]
 local scale=math.min((math.min(px,w-px)-5)*2/content.width,(py-5)/content.height)
 content:resize{width=math.max(1,math.floor(content.width*scale)),height=math.max(1,math.floor(content.height*scale)),method='bilinear'}
 local normalized=Image(w,h,ColorMode.RGB);local left=math.floor(px-content.width/2);local top=py-content.height
 assert(left>=3 and top>=3 and left+content.width<=w-3 and py<=h-3,'padding '..id)
 normalized:drawImage(content,Point(left,top));normalized:saveAs(app.fs.joinPath(target,id..'.png'))
 if i>1 then sheet:newFrame() end
 sheet.cels[i].image=normalized;sheet.cels[i].position=Point(0,0)
 sheet.frames[i].duration=1
 report.assets[#report.assets+1]={id=id,path='res://assets/combat/environment/painted_v2/'..id..'.png',size={w,h},pivot={px,py},content_bounds={left,top,content.width,content.height},crop={xs[c],ys[r],xs[c+1],ys[r+1]},removed_fringe=fringe}
end
sheet:saveAs(editable);sheet:close()
local f=assert(io.open(app.fs.joinPath(base,'normalization.json'),'w'));f:write(json.encode(report));f:close()
print('Normalized16 painted props; original canvases/ground anchors preserved')
