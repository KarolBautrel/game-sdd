local root=assert(app.params.root)
local input=Image{fromFile=root.."/assets_src/portraits/hero-portraits-generated.png"}
app.fs.makeAllDirectories(root.."/assets/ui/portraits")
app.fs.makeAllDirectories(root.."/assets_src/aseprite/portraits")
for index,id in ipairs({"bran","torin"}) do
 local side=math.floor(input.width/2)
 local crop=Image(side,input.height,ColorMode.RGB)
 crop:drawImage(input,Point(-(index-1)*side,0))
 crop:resize(128,128)
 local sprite=Sprite(128,128,ColorMode.RGB)
 sprite.cels[1].image=crop;sprite.layers[1].name="Illustrated pixel portrait"
 sprite:saveAs(root.."/assets_src/aseprite/portraits/"..id..".aseprite")
 crop:saveAs(root.."/assets/ui/portraits/"..id..".png")
 sprite:close()
end
print("HERO_PORTRAITS_PASS 2 independent128px illustrations")
