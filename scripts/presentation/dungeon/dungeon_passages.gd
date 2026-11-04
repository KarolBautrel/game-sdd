extends Control
## Passive graph ink. Routing happens once per layout, never in _draw or per frame.
const CELL := 16.0
const CLEARANCE := 12.0
var grid_cell := CELL
var room_clearance := CLEARANCE
var parchment_style := false
var routes: Array[Dictionary] = []
var current_id := ""
var selected_id := ""
var _grid := AStarGrid2D.new()
var _obstacles: Array[Rect2] = []

func configure(rooms: Dictionary, corridors: Array, extent: Vector2) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = extent
	_grid.region = Rect2i(Vector2i.ZERO,Vector2i(ceil(extent.x/grid_cell),ceil(extent.y/grid_cell)))
	_grid.cell_size = Vector2(grid_cell,grid_cell)
	_grid.offset = Vector2.ONE*grid_cell*.5
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_grid.update()
	_obstacles.clear()
	for rect: Rect2 in rooms.values():
		_obstacles.append(rect.grow(5))
		var obstacle := rect.grow(room_clearance)
		var first := Vector2i(floor(obstacle.position.x/grid_cell),floor(obstacle.position.y/grid_cell))
		var last := Vector2i(ceil(obstacle.end.x/grid_cell),ceil(obstacle.end.y/grid_cell))
		_grid.fill_solid_region(Rect2i(first,last-first).intersection(_grid.region))
	routes.clear()
	for corridor: Dictionary in corridors:
		var from_id := str(corridor.get("from",""))
		var to_id := str(corridor.get("to",""))
		if not rooms.has(from_id) or not rooms.has(to_id): continue
		var points := _route(rooms[from_id],rooms[to_id])
		if parchment_style: points = _round_ink(points)
		routes.append({"from":from_id,"to":to_id,"points":points})
	queue_redraw()

func select_passage(from_id: String, to_id: String) -> void:
	current_id = from_id
	selected_id = to_id
	queue_redraw()

func route_selected(route: Dictionary) -> bool:
	return (route.from==current_id and route.to==selected_id) or (route.to==current_id and route.from==selected_id)

func _ports(rect: Rect2, target: Vector2) -> Array[Dictionary]:
	var delta := target-rect.get_center()
	var horizontal := Vector2.RIGHT if delta.x>=0 else Vector2.LEFT
	var vertical := Vector2.DOWN if delta.y>=0 else Vector2.UP
	var directions: Array = [horizontal,vertical,-vertical,-horizontal] if absf(delta.x)>=absf(delta.y)*(1.35 if parchment_style else 1.0) else [vertical,horizontal,-horizontal,-vertical]
	var result: Array[Dictionary] = []
	for direction: Vector2 in directions:
		var outside := rect.get_center()+direction*(rect.size*.5+Vector2.ONE*(room_clearance+grid_cell*1.5))
		var cell := Vector2i(floor(outside.x/grid_cell),floor(outside.y/grid_cell))
		if not _grid.is_in_boundsv(cell) or _grid.is_point_solid(cell): continue
		var point := _grid.get_point_position(cell)
		var edge := Vector2(rect.end.x+6 if direction.x>0 else rect.position.x-6,point.y) if direction.x!=0 else Vector2(point.x,rect.end.y+6 if direction.y>0 else rect.position.y-6)
		result.append({"cell":cell,"edge":edge})
	return result

func _route(from: Rect2, to: Rect2) -> PackedVector2Array:
	for start: Dictionary in _ports(from,to.get_center()):
		for finish: Dictionary in _ports(to,from.get_center()):
			var path := _grid.get_point_path(start.cell,finish.cell)
			if path.is_empty(): continue
			var points := PackedVector2Array([start.edge])
			points.append_array(path)
			points.append(finish.edge)
			var simplified := PackedVector2Array([points[0]])
			for index in range(1,points.size()-1):
				var incoming := points[index]-simplified[-1]
				var outgoing := points[index+1]-points[index]
				if not is_zero_approx(incoming.cross(outgoing)): simplified.append(points[index])
			simplified.append(points[-1])
			return _simplify_visible(simplified)
	return PackedVector2Array()

func _simplify_visible(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array([points[0]])
	var index := 0
	while index<points.size()-1:
		var next := index+1
		for candidate in range(points.size()-1,index,-1):
			if _visible(points[index],points[candidate]):
				next=candidate
				break
		result.append(points[next])
		index=next
	return result

func _visible(a: Vector2,b: Vector2) -> bool:
	for rect: Rect2 in _obstacles:
		if rect.has_point(a) or rect.has_point(b): return false
		var corners := PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
		for index in range(4):
			if Geometry2D.segment_intersects_segment(a,b,corners[index],corners[(index+1)%4])!=null: return false
	return true

func _round_ink(points: PackedVector2Array) -> PackedVector2Array:
	if points.size()<3: return points
	var result := PackedVector2Array([points[0]])
	for i in range(1,points.size()-1):
		var corner := points[i]
		var radius := minf(grid_cell*.7,minf(corner.distance_to(points[i-1]),corner.distance_to(points[i+1]))*.2)
		var entry := corner+(points[i-1]-corner).normalized()*radius
		var finish := corner+(points[i+1]-corner).normalized()*radius
		var curve := PackedVector2Array([entry])
		for step in range(1,7):
			var t := step/6.0
			curve.append(entry*(1-t)*(1-t)+corner*2*t*(1-t)+finish*t*t)
		var clear := _visible(result[-1],entry)
		for n in range(1,curve.size()): clear = clear and _visible(curve[n-1],curve[n])
		if clear: result.append_array(curve)
		else: result.append(corner)
	result.append(points[-1])
	return result

func _draw() -> void:
	# Fine brass/ink over parchment; the room plates remain the only hit targets.
	for selected: bool in [false,true]:
		for route: Dictionary in routes:
			if route_selected(route)!=selected: continue
			var points: PackedVector2Array = route.points
			if points.size()<2: continue
			if parchment_style:
				var scale := maxf(.65,grid_cell/8.0)
				draw_polyline(points,Color(.12,.08,.04,.65),7*scale if selected else 5*scale,true)
				draw_polyline(points,Color("edddbd") if selected else Color("c7b99f"),4.5*scale if selected else 2.5*scale,true)
				if selected:
					var tip: Vector2 = points[-1] if route.from==current_id else points[0]
					var behind: Vector2 = points[-2] if route.from==current_id else points[1]
					var direction := (tip-behind).normalized()
					var side := direction.orthogonal()
					draw_colored_polygon(PackedVector2Array([tip+direction*8*scale,tip-direction*8*scale+side*6*scale,tip-direction*8*scale-side*6*scale]),Color("9e392c"))
				continue
			draw_polyline(points,Color(.08,.06,.04,.8),7 if selected else 5,true)
			draw_polyline(points,Color("f0ce85") if selected else Color("ac9267"),3.5 if selected else 2,true)
