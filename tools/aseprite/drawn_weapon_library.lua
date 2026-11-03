local root=assert(app.params.root);local base=root..'/assets_src/characters/drawn_animation/2026-11-03/weapon_library'
local source=root..'/assets_src/aseprite/characters/drawn_animation/2026-11-03/weapon_library'
app.fs.makeAllDirectories(source);app.fs.makeAllDirectories(base..'/props')
local input=Image{fromFile=base..'/raw/weapons.png'};local pc=app.pixelColor
local specs={{'two_handed_sword',0,0,112},{'one_handed_sword',1,0,90},{'kite_shield',2,0,78},
 {'bow',0,1,130},{'arrow',1,1,65},{'dagger_a',2,1,38,0},{'dagger_b',2,1,38,1},
 {'axe',0,2,85},{'spear',1,2,190},{'scabbard',2,2,100}}
local report={generator='built-in imagegen',editor='Aseprite',purpose='independent rigid reference masters; action frames remain painted/baked',props={}}
for _,s in ipairs(specs) do
 local cw=input.width/3;local ch=input.height/3
 local x0=math.floor(s[2]*cw);local y0=math.floor(s[3]*ch);local width=math.floor(cw)
 if s[5]~=nil then width=math.floor(cw/2);x0=x0+s[5]*width end
 local crop=Image(input,Rectangle(x0,y0,width,math.floor(ch)))
 local bx,by,ex,ey=crop.width,crop.height,-1,-1
 for it in crop:pixels() do local p=it();local r,g,b,a=pc.rgbaR(p),pc.rgbaG(p),pc.rgbaB(p),pc.rgbaA(p)
  if a<32 or (r>220 and g<45 and b<65) or (g>220 and r<70 and b<70) then it(0)
  else bx=math.min(bx,it.x);by=math.min(by,it.y);ex=math.max(ex,it.x);ey=math.max(ey,it.y) end
 end
 assert(ex>bx and ey>by,'Empty weapon '..s[1])
 local master=Image(crop,Rectangle(bx,by,ex-bx+1,ey-by+1));master:saveAs(base..'/props/'..s[1]..'_master.png')
 local scale=s[4]/math.max(master.width,master.height)
 master:resize{width=math.max(1,math.floor(master.width*scale+.5)),height=math.max(1,math.floor(master.height*scale+.5)),method='bilinear'}
 local native=Image(master.width+8,master.height+8,ColorMode.RGB);native:drawImage(master,Point(4,4))
 native:saveAs(base..'/props/'..s[1]..'.png')
 local sprite=Sprite(native.width,native.height,ColorMode.RGB);sprite.layers[1].name='Independent rigid '..s[1]
 sprite.cels[1].image=native;sprite:newTag(1,1).name=s[1];sprite:saveAs(source..'/'..s[1]..'.aseprite');sprite:close()
 local opened=assert(app.open(source..'/'..s[1]..'.aseprite'));local check=Image(native.width,native.height,ColorMode.RGB);check:drawSprite(opened,1)
 for it in check:pixels() do assert(it()==native:getPixel(it.x,it.y),'Weapon source roundtrip') end
 opened:close();report.props[#report.props+1]={id=s[1],size={native.width,native.height},target_long_side=s[4],roundtrip='PASS'}
end
local f=assert(io.open(base..'/weapon_manifest.json','w'));f:write(json.encode(report));f:close()
print('DRAWN_WEAPON_LIBRARY_PASS '..#specs..' independent props')
