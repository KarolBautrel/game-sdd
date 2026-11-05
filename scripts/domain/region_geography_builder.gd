extends RefCounted
## Per-invocation builder: no mutable dimensions leak into another region.
const Terrain:=preload("res://scripts/domain/terrain_navigation.gd")
var W:=192
var H:=108
var SIZE:=Vector2i(192,108)
var version:=1
var last_error: String=""
func _init(generator_version: int=1) -> void:
	version=generator_version
	if version==2: W=384;H=216;SIZE=Vector2i(W,H)
func _point(value: Dictionary) -> Vector2: return Vector2(float(value.x),float(value.y))
func _center(id: int) -> Vector2: return (Vector2(id%W,id/W)+Vector2(.5,.5))/Vector2(W,H)
func _id(point: Vector2) -> int: return clampi(int(point.y*H),0,H-1)*W+clampi(int(point.x*W),0,W-1)
func _inside(cell: Vector2i) -> bool: return cell.x>=2 and cell.x<W-2 and cell.y>=2 and cell.y<H-2
func _distance(a: Vector2,b: Vector2) -> float: return ((a-b)*Terrain.ASPECT).length()
func _noise(seed_value: int,frequency: float) -> FastNoiseLite:
	var noise:=FastNoiseLite.new();noise.seed=seed_value;noise.frequency=frequency;noise.fractal_octaves=4
	return noise
func _orient(point: Vector2,seed_value: int) -> Vector2:
	return Vector2(point.x if seed_value%2==0 else 1-point.x,point.y if seed_value%3!=0 else 1-point.y)
func _rows(cells: Array[String]) -> Array:
	var result: Array=[]
	for y in range(H):
		var line:=""
		for x in range(W): line+=cells[y*W+x]
		result.append(line)
	return result
func _mask(cells: Array[String],crossings: Array=[]) -> Dictionary:
	return {"version":1,"region":"living_marches_v1","revision":1,"width":W,"height":H,"rows":_rows(cells),"crossings":crossings}
func _paint(cells: Array[String],point: Vector2,radius: int,code: String,only: String="") -> void:
	var at:=Vector2i(point*Vector2(W,H))
	for y in range(at.y-radius,at.y+radius+1):
		for x in range(at.x-radius,at.x+radius+1):
			if not _inside(Vector2i(x,y)) or Vector2(x-at.x,y-at.y).length()>radius+.3: continue
			if only!="" and not only.contains(cells[y*W+x]): continue
			cells[y*W+x]=code
func _stroke(cells: Array[String],a: Vector2,b: Vector2,radius: int,code: String,only: String="") -> void:
	var count:=maxi(1,ceili(((b-a)*Vector2(W,H)).length()*2))
	for index in range(count+1): _paint(cells,a.lerp(b,float(index)/count),radius,code,only)
func _component(cells: Array[String]) -> PackedInt32Array:
	var visited:=PackedByteArray();visited.resize(W*H)
	var best:=PackedInt32Array()
	for first in range(W*H):
		if visited[first]!=0 or "WX".contains(cells[first]): continue
		var queue:=PackedInt32Array([first]);visited[first]=1
		var cursor:=0
		while cursor<queue.size():
			var at:=queue[cursor];cursor+=1
			for next in [at-1,at+1,at-W,at+W]:
				if next<0 or next>=W*H or absi(next%W-at%W)>1 or visited[next]!=0 or "WX".contains(cells[next]): continue
				visited[next]=1;queue.append(next)
		if queue.size()>best.size(): best=queue
	return best
func _navigation(mask: Dictionary) -> RefCounted:
	var nav:=Terrain.new();nav.configure(mask);return nav
func attempt(seed_value: int,preset: String,attempt: int) -> Dictionary:
	var derived:=seed_value+attempt*7919
	var rng:=RandomNumberGenerator.new();rng.seed=derived
	var height_noise:=_noise(derived,.024)
	var wet_noise:=_noise(derived+1301,.036)
	var phase:=rng.randf_range(0,TAU)
	var saddle_x:=rng.randf_range(.34,.56)
	var climates: Array=[]
	if version==2:
		for item: Array in [["wetwood",Vector2(.25,.42),.31],["drylands",Vector2(.63,.72),.30],["uplands",Vector2(.55,.27),.27]]:
			var center: Vector2=_orient(item[1]+Vector2(rng.randf_range(-.07,.07),rng.randf_range(-.06,.06)),derived)
			climates.append({"id":item[0],"position":Terrain.packed(center),"radius":item[2]})
	var cells: Array[String]=[];cells.resize(W*H)
	var heights:=PackedFloat32Array();heights.resize(W*H)
	var ridge_power: float=.76 if preset=="highlands" else .64
	var forest_level: float=.40 if preset=="woodland" else (.62 if preset=="highlands" else .50)
	for y in range(H):
		for x in range(W):
			var id:=y*W+x;var p:=_center(id);var q:=_orient(p,derived)
			var coast: float=.80+.045*sin(q.y*11+phase)+.085*height_noise.get_noise_2d(q.y*170,219)
			var land: bool=_inside(Vector2i(x,y)) and q.x<coast and q.y<.91+.025*wet_noise.get_noise_2d(x,300)
			var ridge: float=.28+.09*sin(q.x*7+phase)
			var saddle: float=1-.64*exp(-pow((q.x-saddle_x)/.055,2))
			var elevation: float=.27+.23*height_noise.get_noise_2d(x,y)+ridge_power*saddle*exp(-pow((q.y-ridge)/.095,2))
			var lower_hills: float=.18*exp(-pow((q.y-.74)/.16,2))*(.5+.5*height_noise.get_noise_2d(x+360,y+70))
			elevation=clampf(elevation+lower_hills,0,1)
			heights[id]=elevation if land else -.2
			var wetness: float=.50+.5*wet_noise.get_noise_2d(x,y)
			if version==2:
				var wet: float=exp(-pow(_distance(p,_point(climates[0].position))/float(climates[0].radius),2))
				var dry: float=exp(-pow(_distance(p,_point(climates[1].position))/float(climates[1].radius),2))
				wetness+=wet*.28-dry*.34
				var foothills: float=.15*exp(-pow((q.y-.67)/.12,2))*(.7+.3*height_noise.get_noise_2d(x+90,y+710))
				elevation=clampf(elevation+foothills,0,1);heights[id]=elevation if land else -.2
			cells[id]="W" if not land else ("X" if elevation>.79 else ("M" if elevation>.64 else ("H" if elevation>.48 else ("F" if wetness>forest_level else "P"))))
	# A low-ground channel route is eroded monotonically from a ridge to the sea.
	var river_grid:=AStarGrid2D.new();river_grid.region=Rect2i(Vector2i.ZERO,SIZE);river_grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ALWAYS;river_grid.update()
	for y in range(H):
		for x in range(W):
			var id:=y*W+x
			river_grid.set_point_solid(Vector2i(x,y),not _inside(Vector2i(x,y)))
			river_grid.set_point_weight_scale(Vector2i(x,y),1+maxf(0,heights[id])*maxf(0,heights[id])*12)
	var source:=_pick_river_source(cells,heights,_orient(Vector2(.24+rng.randf_range(-.06,.08),.28),derived))
	last_error="Could not connect a river source to the coast."
	var mouth:=_pick_mouth(cells,_orient(Vector2(.82,.65+rng.randf_range(-.14,.14)),derived))
	if source<0 or mouth<0: return {}
	var raw:=river_grid.get_id_path(Vector2i(source%W,source/W),Vector2i(mouth%W,mouth/W))
	if raw.size()<24: return {}
	var main: Array=[]
	var river_heights: Array=[]
	var channel_elevation:=maxf(0,heights[source])
	for index in range(raw.size()):
		var id: int=raw[index].y*W+raw[index].x
		var position:=_center(id)
		channel_elevation=minf(channel_elevation,maxf(0,heights[id]))
		heights[id]=channel_elevation
		main.append(Terrain.packed(position));river_heights.append(roundi(channel_elevation*1000))
		channel_elevation=maxf(0,channel_elevation-.0007)
		_paint(cells,position,1 if index<raw.size()*.72 else 2,"W")
	var tributary: Array=[]
	var tributary_heights: Array=[]
	var tributary_start:=_pick_river_source(cells,heights,_orient(Vector2(.14,.62),derived),false)
	var join: Vector2i=raw[raw.size()/2]
	if tributary_start>=0:
		var branch:=river_grid.get_id_path(Vector2i(tributary_start%W,tributary_start/W),join)
		var branch_elevation:=maxf(0,heights[tributary_start])
		for at: Vector2i in branch:
			var id: int=at.y*W+at.x
			branch_elevation=minf(branch_elevation,maxf(0,heights[id]))
			heights[id]=branch_elevation
			tributary_heights.append(roundi(branch_elevation*1000))
			var position:=_center(id);tributary.append(Terrain.packed(position));_paint(cells,position,1,"W")
			branch_elevation=maxf(0,branch_elevation-.0007)
		# Erode the receiving channel as well if the tributary reaches lower ground.
		for index in range(raw.size()/2,raw.size()):
			river_heights[index]=mini(int(river_heights[index]),int(tributary_heights.back()))
	var bridges: Array=[];var crossings: Array=[]
	for target_fraction in [.23,.47,.73,.88]:
		var chosen: Dictionary={}
		var target:=clampi(roundi(raw.size()*target_fraction),5,raw.size()-6)
		for offset in range(18):
			var index:=clampi(target+(offset/2)*(1 if offset%2==0 else -1),4,raw.size()-5)
			var flow:=Vector2(raw[index+2]-raw[index-2]).normalized()
			var normal:=Vector2(-flow.y,flow.x).normalized()
			var center:=_center(raw[index].y*W+raw[index].x)
			var a:=center+normal*Vector2(5.5/W,5.5/H)
			var b:=center-normal*Vector2(5.5/W,5.5/H)
			if "WX".contains(cells[_id(a)]) or "WX".contains(cells[_id(b)]): continue
			var near:=false
			for previous: Dictionary in bridges:
				if _distance(center,_point(previous.position))<.09: near=true
			if near: continue
			chosen={"id":"bridge_%d" % (bridges.size()+1),"name":"Stone crossing %d" % (bridges.size()+1),"position":Terrain.packed(center),"from":Terrain.packed(a),"to":Terrain.packed(b),"orientation":"ne" if normal.x*normal.y<0 else "nw"}
			_stroke(cells,a,b,1,"B","W")
			break
		if not chosen.is_empty():
			bridges.append(chosen);crossings.append({"id":chosen.id,"name":chosen.name,"position":chosen.position.duplicate()})
	last_error="Could not form enough safe bank-to-bank crossings."
	if bridges.size()<2: return {}
	var component:=_component(cells)
	var land_count:=0
	for code: String in cells:
		if code!="W": land_count+=1
	last_error="River crossings did not connect enough mainland."
	if component.size()<W*H*.44 or component.size()<land_count*.75: return {}
	var members: Dictionary={}
	for id in component: members[id]=true
	for bridge: Dictionary in bridges:
		if not members.has(_id(_point(bridge.from))) or not members.has(_id(_point(bridge.to))): return {}
	var sites: Array=[]
	var template: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/world_simulations/living_marches_v1.json"))
	var desires: Array[Vector2]=[Vector2(.20,.70),Vector2(.73,.62),Vector2(.64,.25),Vector2(.43,.75),Vector2(.43,.28),Vector2(.22,.40)]
	var contexts: Array[String]=["PH","PH","HM","HM","HM","F"]
	for index in range(6):
		last_error="Could not place separated, accessible sites."
		var desired: Vector2=desires[index]+Vector2(rng.randf_range(-.1,.1),rng.randf_range(-.10,.10))
		desired=_orient(desired,derived)
		var selected:=_pick_site(component,cells,sites,desired,contexts[index],rng)
		if selected<0: return {}
		var site: Dictionary=template.sites[index].duplicate(true);site.position=Terrain.packed(_center(selected));sites.append(site)
	var nav:=_navigation(_mask(cells,crossings))
	var roads: Array=[];var road_paths: Array=[]
	for pair: Array in [[0,1],[0,3],[0,5],[0,4,2],[2,1]]:
		last_error="A required site has no accessible road."
		var path: Array=[]
		var origin:=_point(sites[int(pair[0])].position)
		for stop in pair.slice(1):
			var segment: Array=nav.route(origin,_point(sites[int(stop)].position))
			if segment.is_empty(): return {}
			path.append_array(segment);origin=_point(sites[int(stop)].position)
		path.push_front(sites[int(pair[0])].position.duplicate())
		road_paths.append(path)
		for position: Dictionary in path: _paint(cells,_point(position),0,"R","PF")
		var waypoints: Array=[]
		for index in range(8): waypoints.append(path[roundi(float(index)*(path.size()-1)/7)].duplicate())
		roads.append(waypoints)
	var terrain:=_mask(cells,crossings)
	var prefixes: Array[String]=["Greyfen","Hollowpine","Northbarrow","Ashenvale","Dunmere","Rookfall","Thornmere","Blackwater"]
	var suffixes: Array[String]=["Reach","March","Coast","Highlands","Borderlands"]
	var name: String=prefixes[seed_value%prefixes.size()]+" "+suffixes[(seed_value/7)%suffixes.size()]
	var result: Dictionary={"version":version,"seed":seed_value,"preset":preset,"attempt":attempt,"name":name,"terrain":terrain,"sites":sites,"roads":roads,"road_paths":road_paths,"rivers":[{"points":main,"profile":river_heights},{"points":tributary,"profile":tributary_heights}],"bridges":bridges,"diagnostics":{"land_cells":land_count,"connected_cells":component.size(),"bridges":bridges.size()}}
	if version==2: result.climates=climates
	return result
func _pick_river_source(cells: Array[String],heights: PackedFloat32Array,desired: Vector2,ridge: bool=true) -> int:
	var best:=-1;var score:=-INF
	for id in range(W*H):
		if cells[id]=="W" or _distance(_center(id),desired)>.22: continue
		var value: float=-_distance(_center(id),desired)*4+(float(heights[id]) if ridge else -.3*float(heights[id]))
		if value>score: best=id;score=value
	return best
func _pick_mouth(cells: Array[String],desired: Vector2) -> int:
	var best:=-1;var score:=INF
	for y in range(3,H-3):
		for x in range(3,W-3):
			var id:=y*W+x
			if cells[id]!="W": continue
			if cells[id-1]=="W" and cells[id+1]=="W" and cells[id-W]=="W" and cells[id+W]=="W": continue
			var distance:=_distance(_center(id),desired)
			if distance<score: best=id;score=distance
	return best
func _pick_site(component: PackedInt32Array,cells: Array[String],sites: Array,desired: Vector2,context: String,rng: RandomNumberGenerator) -> int:
	var best:=-1;var score:=-INF
	for id in component:
		if id%2!=0: continue
		var position:=_center(id)
		if position.x<.075 or position.x>.925 or position.y<.10 or position.y>.88 or cells[id]=="B": continue
		var separated:=true
		for site: Dictionary in sites:
			if _distance(position,_point(site.position))<.235: separated=false;break
		if not separated: continue
		var value: float=-_distance(position,desired)*4+(1.0 if context.contains(cells[id]) else 0.0)+rng.randf()*.05
		if value>score: best=id;score=value
	return best
