-- Explicit2D reuse, never labelled as independently drawn additional views.
local root=assert(app.params.root);local id=assert(app.params.id)
local from=assert(app.params.from);local to=assert(app.params.to)
local stem='/characters/drawn_animation/2026-11-03/'..id
local right=root..'/assets_src'..stem..(from=='south_east' and '' or '/directions/'..from)
local target=root..'/assets_src'..stem..'/directions/'..to
local source=root..'/assets_src/aseprite'..stem..'/directions/'..to
app.fs.makeAllDirectories(target);app.fs.makeAllDirectories(source)
local function read(p)local f=assert(io.open(p));local x=json.decode(f:read('*a'));f:close();return x end
local function write(p,x)local f=assert(io.open(p,'w'));f:write(json.encode(x));f:close() end
local raw=read(right..'/manifest.json');local proof=read(right..'/export_report.json')
local manifest={id=raw.id,title=raw.title,canvas={raw.canvas[1],raw.canvas[2]},
 pivot={raw.pivot[1],raw.pivot[2]},pixels_per_metre=raw.pixels_per_metre,body_height=raw.body_height,clips={}}
for _,c in ipairs(raw.clips) do
 local entry={id=c.id,title=c.title,mode=c.mode,loop=c.loop,frames=c.frames,atlas=c.atlas,
  source_sheet=c.source_sheet,source_first=c.source_first,scale=c.scale,durations={}}
 for i,d in ipairs(c.durations) do entry.durations[i]=d end
 manifest.clips[#manifest.clips+1]=entry
end
assert(#proof.clipping==0 and proof.saved_source_roundtrip=='PASS','Unverified mirror source')
local W,H=manifest.canvas[1],manifest.canvas[2]
assert(#manifest.clips>=7 and W>=320 and H>=320,'Invalid mirror manifest')
local report={status='TECHNICAL_MIRROR_PASS_VISUAL_REVIEW_PENDING',id=id,view=to,mirror_of=from,
 canvas={W,H},pivot=manifest.pivot,clipping={},clips={},saved_source_roundtrip='PASS',
 handedness='reflected with costume asymmetry; presentation only'}
for _,clip in ipairs(manifest.clips) do
 local dir=target..'/frames/'..clip.id;app.fs.makeAllDirectories(dir)
 local atlas=Image(W*clip.frames,H,ColorMode.RGB);local sprite=Sprite(W,H,ColorMode.RGB)
 sprite.layers[1].name='Mirror of '..from..'; handedness reflected'
 for n=1,clip.frames do
  local input=Image{fromFile=string.format(right..'/frames/'..clip.id..'/%03d.png',n-1)}
  local output=Image(W,H,ColorMode.RGB)
  for it in input:pixels() do output:drawPixel(W-1-it.x,it.y,it()) end
  if n==1 then sprite.cels[1].image=output else sprite:newEmptyFrame();sprite:newCel(sprite.layers[1],n,output,Point(0,0)) end
  sprite.frames[n].duration=clip.durations[n]/1000
  output:saveAs(string.format(dir..'/%03d.png',n-1));atlas:drawImage(output,Point((n-1)*W,0))
 end
 sprite:newTag(1,clip.frames).name=clip.id;sprite:saveAs(source..'/'..clip.id..'.aseprite');sprite:close()
 local opened=assert(app.open(source..'/'..clip.id..'.aseprite'))
 assert(#opened.frames==clip.frames and opened.tags[1].name==clip.id,'Mirror source tags/count')
 for n=1,clip.frames do
  local image=Image(W,H,ColorMode.RGB);image:drawSprite(opened,n)
  local png=Image{fromFile=string.format(dir..'/%03d.png',n-1)}
  assert(math.abs(opened.frames[n].duration*1000-clip.durations[n])<1,'Mirror timing')
  for it in image:pixels() do assert(it()==png:getPixel(it.x,it.y),'Mirror saved pixels') end
 end
 opened:close();atlas:saveAs(target..'/'..clip.atlas)
 clip.frame_source='mirrored '..from;clip.mirror_of=from
 report.clips[clip.id]={frame_count=clip.frames,mirror_of=from}
end
manifest.view=to;manifest.exported_views={to};manifest.mirror_of=from
manifest.direction_note='Odbicie: odwraca asymetrię stroju i stronę trzymania broni.'
write(target..'/manifest.json',manifest);write(target..'/export_report.json',report)
write(target..'/mirror_recipe.json',{tool='Aseprite',script='tools/aseprite/mirror_drawn_actions.lua',from=from,to=to,
 operation='horizontal pixel reflection about canvas centre; unchanged pivot and timing',handedness='reflected'})
print('DRAWN_MIRROR_PASS '..id..' '..from..' '..to)
