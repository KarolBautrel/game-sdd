local im=Image{fromFile=assert(app.params.input)}
local pc=app.pixelColor
local hist={};for n=0,255 do hist[n+1]=0 end
for it in im:pixels() do local a=pc.rgbaA(it());hist[a+1]=hist[a+1]+1 end
local samples={}
for _,xy in ipairs({{0,0},{15,100},{250,100},{20,600},{600,300},{400,400}}) do
 local p=im:getPixel(xy[1],xy[2]);samples[#samples+1]={xy=xy,rgba={pc.rgbaR(p),pc.rgbaG(p),pc.rgbaB(p),pc.rgbaA(p)}}
end
print(json.encode({width=im.width,height=im.height,samples=samples,hist=hist}))
