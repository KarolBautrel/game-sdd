local root=assert(app.params.root)
local base=root..'/assets_src/characters/drawn_animation/2026-11-03/'
local out=base..'refinements/motion_balance/'
app.fs.makeAllDirectories(out)
local views={'south_east','south','east','north_east','north'}
local idles=Image(384*4,320*5,ColorMode.RGB)
local walks=Image(384*4,320*10,ColorMode.RGB)
for row,view in ipairs(views) do
 local home=base..'knight'..(view=='south_east' and '' or '/directions/'..view)
 for col,spec in ipairs({{'neutral_idle',0},{'neutral_idle',2},{'combat_idle',0},{'combat_idle',2}}) do
  idles:drawImage(Image{fromFile=string.format(home..'/frames/'..spec[1]..'/%03d.png',spec[2])},Point((col-1)*384,(row-1)*320))
 end
 for n=0,7 do
  walks:drawImage(Image{fromFile=string.format(home..'/frames/neutral_walk/%03d.png',n)},Point((n%4)*384,((row-1)*2+n//4)*320))
 end
end
idles:saveAs(out..'knight_idles_reference.png')
walks:saveAs(out..'knight_neutral_walk_reference.png')
print('DRAWN_MOTION_REFERENCES_PASS: SE,S,E,NE,N; 20 idle and 40 walk drawings')
