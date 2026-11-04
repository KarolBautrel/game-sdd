extends RefCounted
## Pure local movement. No campaign/session/save access.
const CELL := Vector2(96,48)
const SPEED := 104.0
const RADIUS := 0.16

static func project(point: Vector2) -> Vector2:
	return Vector2((point.x-point.y)*CELL.x/2.0,(point.x+point.y)*CELL.y/2.0)

static func unproject(point: Vector2) -> Vector2:
	return Vector2(point.x/CELL.x+point.y/CELL.y,point.y/CELL.y-point.x/CELL.x)

static func walkable(point: Vector2, map: Dictionary, npcs: Array = []) -> bool:
	for offset in [Vector2(-RADIUS,-RADIUS),Vector2(RADIUS,-RADIUS),Vector2(-RADIUS,RADIUS),Vector2(RADIUS,RADIUS)]:
		var cell:=Vector2i((point+offset).floor())
		if cell.x<0 or cell.y<0 or cell.x>=int(map.width) or cell.y>=int(map.height):return false
		if map.tiles[cell.y*int(map.width)+cell.x].type=="blocked":return false
	for npc: Vector2 in npcs:
		if project(point).distance_to(project(npc))<22.0:return false
	return true

static func move(point: Vector2, axis: Vector2, dt: float, map: Dictionary, npcs: Array = []) -> Vector2:
	var remaining:=maxf(0.0,dt)
	var direction:=axis.limit_length(1.0)
	while remaining>0.000001:
		var step:=minf(remaining,1.0/120.0)
		var offset:=unproject(direction*SPEED*step)
		var target:=point+offset
		if walkable(target,map,npcs):point=target
		else:
			var slide:=point+Vector2(offset.x,0)
			if walkable(slide,map,npcs):point=slide
			slide=point+Vector2(0,offset.y)
			if walkable(slide,map,npcs):point=slide
		remaining-=step
	return point

static func trail_position(trail: Array[Vector2], distance: float, map: Dictionary = {}, npcs: Array = []) -> Vector2:
	if trail.is_empty():return Vector2.ZERO
	for i in range(1,trail.size()):
		var segment:=project(trail[i-1]).distance_to(project(trail[i]))
		if segment>=distance and segment>0:
			var point:=trail[i-1].lerp(trail[i],distance/segment)
			return point if map.is_empty() or walkable(point,map,npcs) else trail[i-1]
		distance-=segment
	return trail.back()

static func nearest(point: Vector2, npcs: Array, distance: float = 100.0, map: Dictionary = {}) -> String:
	var selected:=""
	for npc: Dictionary in npcs:
		var target:=Vector2(npc.position.x,npc.position.y)
		var gap:=project(point).distance_to(project(target))
		if not map.is_empty():
			var clear:=true
			for i in range(1,17):
				if not walkable(point.lerp(target,float(i)/16.0),map):clear=false;break
			if not clear:continue
		if gap<distance or (is_equal_approx(gap,distance) and (selected.is_empty() or str(npc.id)<selected)):
			selected=str(npc.id);distance=gap
	return selected
