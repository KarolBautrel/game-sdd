extends RefCounted
## Painted symbol composition from the exact semantic snapshot; no gameplay rules.
const Terrain:=preload("res://scripts/domain/terrain_navigation.gd")
const Gen:=preload("res://scripts/domain/region_generator.gd")
const SYMBOLS:=preload("res://assets/ui/world/region_symbols.png")
const SHADER:=preload("res://scripts/presentation/world/generated_ground.gdshader")
const PALETTE:={"R":"b99b5c","P":"baa064","F":"a69960","H":"ad8e58","M":"99815b","W":"527b77","X":"92836b","B":"527b77"}
var geography: Dictionary={}
var symbols: Array=[]
var base: ImageTexture
var codes: ImageTexture
var overlay: ImageTexture
var reference_width:=1672.0
func configure(value: Dictionary) -> void:
	geography=value
	var dimensions:=Vector2i(int(value.terrain.width),int(value.terrain.height))
	var factor:=2.0 if int(value.version)==2 else 1.0
	reference_width=1672.0*factor
	var image:=Image.create(dimensions.x,dimensions.y,false,Image.FORMAT_RGBA8)
	var mask:=Image.create(dimensions.x,dimensions.y,false,Image.FORMAT_RGBA8)
	var tint:=Image.create(dimensions.x,dimensions.y,false,Image.FORMAT_RGBA8)
	for y in range(dimensions.y):
		for x in range(dimensions.x):
			var code: String=geography.terrain.rows[y][x]
			image.set_pixel(x,y,Color(PALETTE[code]))
			var climate:=.5
			if int(value.version)==2:
				var p: Vector2=(Vector2(x,y)+Vector2(.5,.5))/Vector2(dimensions)
				for index in range(2):
					var zone: Dictionary=value.climates[index]
					var delta: Vector2=(p-Vector2(float(zone.position.x),float(zone.position.y)))*Terrain.ASPECT
					climate+=(.5 if index==0 else -.5)*exp(-pow(delta.length()/float(zone.radius),2))
			mask.set_pixel(x,y,Color(1.0 if "WB".contains(code) else 0.0,1.0 if code=="F" else 0.0,{"H":.35,"M":.65,"X":1.0}.get(code,0),clampf(climate,0,1)))
			tint.set_pixel(x,y,Color(Terrain.TYPES[code].color))
	base=ImageTexture.create_from_image(image);codes=ImageTexture.create_from_image(mask);overlay=ImageTexture.create_from_image(tint)
	symbols.clear()
	var nav: RefCounted=Gen.navigation(geography)
	var rng:=RandomNumberGenerator.new();rng.seed=int(geography.seed)*31+int(geography.attempt)
	var mountain_positions: Array[Vector2]=[]
	for y in range(4,dimensions.y-4,3):
		for x in range(4,dimensions.x-4,3):
			var position: Vector2=nav.center(Vector2i(x,y))+Vector2(rng.randf_range(-1.1,1.1),rng.randf_range(-1.1,1.1))/Vector2(dimensions)
			var code: String=nav.code_at(position)
			var slot:=-1;var size:=Vector2.ZERO
			if code=="F" and rng.randf()<.96:
				var clear:=true
				for dy in range(-3,4):
					for dx in range(-3,4):
						if dx*dx+dy*dy<=9 and "RWB".contains(nav.code_at(position+Vector2(dx,dy)/Vector2(dimensions))): clear=false
				if clear: slot=[0,0,1,3][rng.randi_range(0,3)];size=Vector2.ONE*rng.randf_range(58,76)
			elif code=="X": slot=6 if rng.randf()<.28 else 5;size=Vector2.ONE*rng.randf_range(105,135)
			elif code=="M" and rng.randf()<.65: slot=5 if rng.randf()<.65 else 7;size=Vector2.ONE*rng.randf_range(80,105)
			elif code=="H" and rng.randf()<.10: slot=4;size=Vector2.ONE*rng.randf_range(70,96)
			if slot<0: continue
			if code in ["M","X"]:
				var separated:=true
				for previous: Vector2 in mountain_positions:
					if ((position-previous)*Terrain.ASPECT).length()<.067/factor: separated=false;break
				if not separated: continue
				mountain_positions.append(position)
			var free:=true
			for site: Dictionary in geography.sites:
				if ((position-Vector2(float(site.position.x),float(site.position.y)))*Terrain.ASPECT).length()<.065/factor: free=false
			if free: symbols.append({"slot":slot,"position":position,"size":size})
	for index in range(6):
		var entry: Dictionary=geography.sites[index]
		symbols.append({"slot":[8,9,10,12,7,11][index],"position":Vector2(float(entry.position.x),float(entry.position.y)),"size":Vector2.ONE*[140,135,155,120,100,140][index]})
	for bridge: Dictionary in geography.bridges:
		var span:=Vector2(float(bridge.to.x)-float(bridge.from.x),float(bridge.to.y)-float(bridge.from.y))*Terrain.ASPECT
		if absf(span.x)>.0001 and absf(span.y)>.0001 and absf(span.x/span.y)>.6 and absf(span.x/span.y)<1.7:
			symbols.append({"slot":14 if bridge.orientation=="ne" else 15,"position":Vector2(float(bridge.position.x),float(bridge.position.y)),"size":Vector2.ONE*112,"pivot":Vector2(.5,.65)})
	symbols.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.position.y<b.position.y)
func background() -> TextureRect:
	var rect:=TextureRect.new();rect.texture=base;rect.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;rect.stretch_mode=TextureRect.STRETCH_SCALE
	rect.mouse_filter=Control.MOUSE_FILTER_IGNORE;rect.show_behind_parent=true
	var material:=ShaderMaterial.new();material.shader=SHADER;material.set_shader_parameter("terrain_codes",codes);material.set_shader_parameter("chart_seed",float(geography.seed))
	material.set_shader_parameter("terrain_texel",Vector2(1.0/float(geography.terrain.width),1.0/float(geography.terrain.height)))
	material.set_shader_parameter("climate_enabled",int(geography.version)==2)
	if ResourceLoader.exists("res://assets/ui/world/ground_wash.png"):
		material.set_shader_parameter("ground_wash",load("res://assets/ui/world/ground_wash.png"));material.set_shader_parameter("has_ground",true)
	rect.material=material
	return rect
func draw_features(canvas: CanvasItem,paper: Rect2,semantic: bool=false) -> void:
	var scale:=paper.size.x/reference_width
	for path: Array in geography.road_paths:
		var points:=PackedVector2Array()
		for position: Dictionary in path: points.append(paper.position+paper.size*Vector2(float(position.x),float(position.y)))
		if points.size()>1:
			canvas.draw_polyline(points,Color("684b2d"),maxf(2,6*scale),true)
			canvas.draw_polyline(points,Color("d5b879"),maxf(1,3.5*scale),true)
	for bridge: Dictionary in geography.bridges:
		var a:=paper.position+paper.size*Vector2(float(bridge.from.x),float(bridge.from.y))
		var b:=paper.position+paper.size*Vector2(float(bridge.to.x),float(bridge.to.y))
		var normal: Vector2=(b-a).normalized().orthogonal()*7*scale
		canvas.draw_line(a+Vector2(2,3)*scale,b+Vector2(2,3)*scale,Color("2a271a70"),20*scale,true)
		canvas.draw_colored_polygon(PackedVector2Array([a-normal,b-normal,b+normal,a+normal]),Color("b9a47b"))
		for sign_value in [-1,1]:
			canvas.draw_line(a+normal*sign_value,b+normal*sign_value,Color("5d4b34"),3*scale,true)
			canvas.draw_line(a+normal*sign_value+Vector2(0,-2)*scale,b+normal*sign_value+Vector2(0,-2)*scale,Color("ddc89c"),1.5*scale,true)
		var joints: int=maxi(2,int(a.distance_to(b)/(8*scale)))
		for index in range(1,joints):
			var center:=a.lerp(b,float(index)/joints)
			canvas.draw_line(center-normal*.72,center+normal*.72,Color("826b49"),maxf(.7,scale),true)
	for symbol: Dictionary in symbols:
		var size: Vector2=symbol.size*scale
		var position: Vector2=paper.position+paper.size*Vector2(symbol.position)-size*Vector2(symbol.get("pivot",Vector2(.5,350.0/384.0)))
		if not Rect2(position,size).intersects(Rect2(Vector2.ZERO,canvas.size)): continue
		var slot: int=int(symbol.slot)
		canvas.draw_texture_rect_region(SYMBOLS,Rect2(position,size),Rect2(Vector2(slot%4,slot/4)*384,Vector2(384,384)))
	if semantic: canvas.draw_texture_rect(overlay,paper,false,Color(1,1,1,.5))
