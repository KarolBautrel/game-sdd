extends RefCounted
## Semantic terrain and weighted routes shared by every strategic party.
const PATH := "res://resources/data/world_terrain/living_marches_v1.json"
const TYPES := {
	"R":{"name":"Road","cost":1.0,"color":"d7ad62"},
	"P":{"name":"Plains","cost":1.3,"color":"c5b77c"},
	"F":{"name":"Forest","cost":2.0,"color":"47704b"},
	"H":{"name":"Hills","cost":2.5,"color":"b27d4a"},
	"M":{"name":"Mountain slopes","cost":3.3,"color":"8e7f75"},
	"W":{"name":"Water","cost":0.0,"color":"397d9f"},
	"X":{"name":"High peaks","cost":0.0,"color":"462c43"},
	"B":{"name":"Bridge / ford","cost":1.15,"color":"e8d8b4"}}
const ASPECT := Vector2(16.0/9.0,1)
static var cached: RefCounted
var data: Dictionary={}
var dimensions:=Vector2i.ZERO
var signature: String=""
var grid: WeightedGrid
var recovery_origin:=Vector2i(-1,-1)
var recovery_cells: Dictionary={}

class WeightedGrid extends AStarGrid2D:
	var costs:=PackedFloat32Array()
	var dimensions:=Vector2i.ONE
	func _compute_cost(from_id: Vector2i,to_id: Vector2i) -> float:
		var step: Vector2=Vector2(to_id-from_id)/Vector2(dimensions)*Vector2(16.0/9.0,1)
		return step.length()*(costs[from_id.y*dimensions.x+from_id.x]+costs[to_id.y*dimensions.x+to_id.x])*.5
	func _estimate_cost(from_id: Vector2i,to_id: Vector2i) -> float:
		return (Vector2(to_id-from_id)/Vector2(dimensions)*Vector2(16.0/9.0,1)).length()

static func current() -> RefCounted:
	if cached==null:
		var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		cached=load("res://scripts/domain/terrain_navigation.gd").new()
		if not parsed is Dictionary or not cached.configure(parsed): push_error("Invalid living-world terrain map: "+PATH)
	return cached

static func reload() -> void: cached=null

static func packed(position: Vector2) -> Dictionary:
	# Decimal coordinates roundtrip through Godot's JSON parser without ULP drift.
	# 1e-7 normalized units is less than0.0002px on the source illustration.
	return {"x":float("%.7f" % position.x),"y":float("%.7f" % position.y)}

static func errors(value: Variant) -> Array[String]:
	var result: Array[String]=[]
	if not value is Dictionary: return ["Terrain must be an object."]
	if value.get("version")!=1 or value.get("region")!="living_marches_v1": result.append("Unsupported terrain version/region.")
	for axis in ["width","height"]:
		var number: Variant=value.get(axis)
		if not (number is float or number is int) or not is_finite(float(number)) or float(number)!=floor(float(number)): return ["Dimensions must be finite integers."]
	var width: int=int(value.width)
	var height: int=int(value.height)
	if width<4 or height<4 or width>512 or height>288: return ["Terrain dimensions are outside4..512 /4..288."]
	if value.get("width")!=width or value.get("height")!=height: result.append("Dimensions must be integers.")
	if not value.get("revision") is float and not value.get("revision") is int: return ["Missing revision."]
	if not is_finite(float(value.revision)) or float(value.revision)!=floor(float(value.revision)) or value.revision<1: result.append("Revision must be a positive integer.")
	if not value.get("rows") is Array or value.rows.size()!=height: return ["Wrong row count."]
	for row in value.rows:
		if not row is String or row.length()!=width: return ["Wrong row width."]
		for code in row:
			if not TYPES.has(code): return ["Unknown terrain code: "+code]
	if value.has("crossings"):
		if not value.crossings is Array: return ["Crossings must be an array."]
		var ids: Array[String]=[]
		for crossing in value.crossings:
			if not crossing is Dictionary or not crossing.get("id") is String or not crossing.get("name") is String or not crossing.get("position") is Dictionary: return ["Invalid crossing metadata."]
			if ids.has(crossing.id): return ["Duplicate crossing id."]
			ids.append(crossing.id)
			for axis in ["x","y"]:
				var coordinate: Variant=crossing.position.get(axis)
				if not (coordinate is float or coordinate is int) or not is_finite(float(coordinate)) or coordinate<0 or coordinate>=1: return ["Invalid crossing coordinate."]
	return result

func configure(value: Dictionary) -> bool:
	if not errors(value).is_empty(): return false
	data=value.duplicate(true)
	recovery_origin=Vector2i(-1,-1);recovery_cells.clear()
	dimensions=Vector2i(int(data.width),int(data.height))
	var costs: Array=[]
	for code: String in TYPES: costs.append([code,TYPES[code].cost])
	signature=(str(dimensions)+"|"+str(costs)+"|"+"\n".join(data.rows)).sha256_text()
	grid=WeightedGrid.new()
	grid.dimensions=dimensions
	grid.region=Rect2i(Vector2i.ZERO,dimensions)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	grid.costs.resize(dimensions.x*dimensions.y)
	for y in range(dimensions.y):
		for x in range(dimensions.x):
			var cost: float=TYPES[data.rows[y][x]].cost
			grid.costs[y*dimensions.x+x]=cost
			grid.set_point_solid(Vector2i(x,y),cost==0)
	return true

func cell(position: Vector2) -> Vector2i:
	return Vector2i(position*Vector2(dimensions)).clamp(Vector2i.ZERO,dimensions-Vector2i.ONE)

func center(id: Vector2i) -> Vector2:
	return (Vector2(id)+Vector2(.5,.5))/Vector2(dimensions)

func code_at(position: Vector2) -> String:
	if not position.is_finite() or position.x<0 or position.y<0 or position.x>=1 or position.y>=1 or grid==null: return "W"
	var id:=cell(position)
	return data.rows[id.y][id.x]

func cost_at(position: Vector2) -> float: return float(TYPES[code_at(position)].cost)
func passable(position: Vector2) -> bool: return cost_at(position)>0

func nearest(position: Vector2,connected_to: Vector2=Vector2.INF) -> Vector2:
	if connected_to.is_finite() and recovery_origin!=cell(connected_to):
		recovery_origin=cell(connected_to);recovery_cells.clear()
		var queue: Array[Vector2i]=[recovery_origin]
		if passable(connected_to): recovery_cells[recovery_origin]=true
		var cursor:=0
		while cursor<queue.size() and not recovery_cells.is_empty():
			var at:=queue[cursor];cursor+=1
			for offset: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var next:=at+offset
				if grid.is_in_boundsv(next) and not grid.is_point_solid(next) and not recovery_cells.has(next):
					recovery_cells[next]=true;queue.append(next)
	if passable(position) and (not connected_to.is_finite() or recovery_cells.has(cell(position))): return position
	var best:=Vector2.INF
	var distance:=INF
	for y in range(dimensions.y):
		for x in range(dimensions.x):
			if grid.is_point_solid(Vector2i(x,y)): continue
			if connected_to.is_finite() and not recovery_cells.has(Vector2i(x,y)): continue
			var candidate:=center(Vector2i(x,y))
			var length:=((candidate-position)*ASPECT).length_squared()
			if length<distance: distance=length;best=candidate
	return best

func route(start: Vector2,destination: Vector2) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if not passable(start) or not passable(destination): return result
	var cells:=grid.get_id_path(cell(start),cell(destination))
	if cells.is_empty(): return result
	# Begin with safe center links. Trim only endpoint detours proven safe and
	# no more expensive; never blindly cut a diagonal bank corner.
	for id: Vector2i in cells:
		var position:=center(id)
		result.append(packed(position))
	result.append(packed(destination))
	if result.size()>1:
		var direct: float=route_cost(start,[result[1]])
		if start.is_equal_approx(Vector2(float(result[0].x),float(result[0].y))) or (is_finite(direct) and direct<=route_cost(start,result.slice(0,2))+.0000001):
			result.remove_at(0)
	if result.size()>1:
		var index:=result.size()-2
		var origin:=start if index==0 else Vector2(float(result[index-1].x),float(result[index-1].y))
		var direct: float=route_cost(origin,[result.back()])
		if is_finite(direct) and direct<=route_cost(origin,result.slice(index))+.0000001: result.remove_at(index)
	return result

func _cuts(start: Vector2,end: Vector2) -> Array[float]:
	var result: Array[float]=[0.0,1.0]
	var difference:=end-start
	for axis in range(2):
		if absf(difference[axis])<.00000001: continue
		var low: int=int(floor(minf(start[axis],end[axis])*dimensions[axis]))+1
		var high: int=int(ceil(maxf(start[axis],end[axis])*dimensions[axis]))
		for index in range(low,high):
			var t: float=(float(index)/dimensions[axis]-start[axis])/difference[axis]
			if t>.00000001 and t<.99999999: result.append(t)
	result.sort()
	return result

func line_clear(start: Vector2,end: Vector2) -> bool:
	if not passable(start) or not passable(end): return false
	var cuts:=_cuts(start,end)
	var previous:=cell(start)
	for index in range(1,cuts.size()):
		var midpoint:=start.lerp(end,(cuts[index-1]+cuts[index])*.5)
		if not passable(midpoint): return false
		var next:=cell(midpoint)
		if previous.x!=next.x and previous.y!=next.y:
			if grid.is_point_solid(Vector2i(previous.x,next.y)) or grid.is_point_solid(Vector2i(next.x,previous.y)): return false
		previous=next
	return true

func route_cost(start: Vector2,path: Array) -> float:
	var result:=0.0
	for point: Dictionary in path:
		var end:=Vector2(float(point.x),float(point.y))
		if not line_clear(start,end): return INF
		var cuts:=_cuts(start,end)
		for index in range(1,cuts.size()):
			result+=((end-start)*ASPECT).length()*(cuts[index]-cuts[index-1])*cost_at(start.lerp(end,(cuts[index]+cuts[index-1])*.5))
		start=end
	return result

func walk(unit: Dictionary,path: Array,budget: float,motion: Variant=null) -> bool:
	var position:=Vector2(float(unit.position.x),float(unit.position.y))
	var initial_budget:=budget
	if motion!=null: motion.samples=[{"cost":0.0,"position":packed(position)}]
	while budget>0.00000001 and not path.is_empty():
		var end:=Vector2(float(path[0].x),float(path[0].y))
		if not line_clear(position,end): break
		var origin:=position
		var length:=((end-origin)*ASPECT).length()
		var cuts:=_cuts(origin,end)
		for index in range(1,cuts.size()):
			var cost:=cost_at(origin.lerp(end,(cuts[index]+cuts[index-1])*.5))
			var required:=length*(cuts[index]-cuts[index-1])*cost
			if budget+.000000001>=required:
				position=origin.lerp(end,cuts[index]);budget=maxf(0,budget-required)
			else:
				position=origin.lerp(end,cuts[index-1]+budget/(length*cost));budget=0
			if motion!=null and required>0.000000001:
				motion.samples.append({"cost":initial_budget-budget,"position":packed(position)})
			if budget<=.00000001: break
		if position.is_equal_approx(end): position=end;path.pop_front()
		elif budget<=.00000001: break
	unit.position=packed(position)
	if motion!=null: motion.remaining=budget
	return path.is_empty()

func connectivity_errors(anchors: Array) -> Array[String]:
	var result: Array[String]=[]
	if anchors.is_empty(): return result
	var origin:=Vector2(float(anchors[0].position.x),float(anchors[0].position.y))
	for anchor: Dictionary in anchors:
		var target:=Vector2(float(anchor.position.x),float(anchor.position.y))
		if not passable(target): result.append(str(anchor.id)+" is blocked.")
		elif route(origin,target).is_empty(): result.append(str(anchor.id)+" is disconnected.")
	return result

static func save_map(path: String,value: Dictionary,anchors: Array) -> String:
	var issues:=errors(value)
	if not issues.is_empty(): return issues[0]
	if path==PATH and (int(value.width)!=192 or int(value.height)!=108): return "This region requires a192x108 terrain mask."
	var navigation: RefCounted=load("res://scripts/domain/terrain_navigation.gd").new()
	navigation.configure(value)
	issues=navigation.connectivity_errors(anchors)
	if not issues.is_empty(): return issues[0]
	if path!=PATH and not path.begins_with("user://qa_terrain_"): return "Unsupported terrain destination."
	var text:=JSON.stringify(value,"\t",true,true)+"\n"
	var temporary:=path+".tmp"
	var file:=FileAccess.open(temporary,FileAccess.WRITE)
	if file==null: return "Cannot write terrain temporary file."
	file.store_string(text);file.flush()
	var error:=file.get_error()
	file.close()
	if error!=OK: return "Terrain write failed. Previous map retained."
	if FileAccess.file_exists(path):
		var backup: String="user://terrain_editor_previous.json" if path==PATH else path+".previous"
		if DirAccess.copy_absolute(path,backup)!=OK: return "Cannot preserve previous map."
	if DirAccess.rename_absolute(temporary,path)!=OK: return "Cannot replace terrain map. Previous map retained."
	reload()
	return ""
