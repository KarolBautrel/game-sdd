extends RefCounted
## Versioned geography snapshots. No campaign state, saves or renderer mutations.
const Terrain:=preload("res://scripts/domain/terrain_navigation.gd")
const Builder:=preload("res://scripts/domain/region_geography_builder.gd")
const W:=192
const H:=108
const SIZE:=Vector2i(W,H)
const PRESETS: Array[String]=["marches","woodland","highlands"]
const IDS: Array[String]=["town_ravenford","saltwatch","black_keep","dungeon_old_mine","high_pass","sunken_abbey"]
static var snapshots: Dictionary={}
static var navigators: Dictionary={}
static var approved: Dictionary={}
static var last_error: String=""

static func _integer(value: Variant,low: int,high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value==floor(float(value)) and value>=low and value<=high
static func _canonical(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary={}
		for key in value:
			if key!="checksum": result[key]=_canonical(value[key])
		return result
	if value is Array:
		var result: Array=[]
		for item in value: result.append(_canonical(item))
		return result
	if value is float:
		return int(value) if value==floor(value) else float("%.7f" % value)
	return value
static func checksum(value: Dictionary) -> String:
	return JSON.stringify(_canonical(value),"",true,true).sha256_text()
static func _point(value: Dictionary) -> Vector2: return Vector2(float(value.x),float(value.y))
static func _distance(a: Vector2,b: Vector2) -> float: return ((a-b)*Terrain.ASPECT).length()
static func _navigation(mask: Dictionary) -> RefCounted:
	var nav:=Terrain.new();nav.configure(mask);return nav
static func navigation(geography: Dictionary) -> RefCounted:
	var key: String=geography.checksum
	if not navigators.has(key):
		if navigators.size()>=24: navigators.erase(navigators.keys()[0])
		navigators[key]=_navigation(geography.terrain)
	return navigators[key]
static func generate(seed_value: int,preset: String="marches",version: int=1) -> Dictionary:
	last_error=""
	if seed_value<1 or seed_value>1000000000 or not PRESETS.has(preset) or version not in [1,2]:
		last_error="Choose seed 1..1000000000, a supported preset and generator version1 or2."
		return {}
	var key: String="%s:%s:%s" % [version,preset,seed_value]
	if snapshots.has(key): return snapshots[key].duplicate(true)
	for attempt in range(8):
		var builder:=Builder.new(version)
		var result: Dictionary=builder.attempt(seed_value,preset,attempt)
		last_error=builder.last_error
		if result.is_empty(): continue
		result.checksum=checksum(result)
		var issues:=errors(result)
		if not issues.is_empty(): last_error=" ".join(issues);continue
		if snapshots.size()>=16: snapshots.erase(snapshots.keys()[0])
		snapshots[key]=result
		last_error=""
		return result.duplicate(true)
	return {}
static func errors(value: Variant) -> Array[String]:
	if not value is Dictionary: return ["Generated geography is not an object."]
	for key in value:
		if not ["version","seed","preset","attempt","name","terrain","sites","roads","road_paths","rivers","bridges","diagnostics","checksum","climates"].has(key): return ["Unknown geography field."]
	if not _integer(value.get("version"),1,2) or not _integer(value.get("seed"),1,1000000000) or not PRESETS.has(value.get("preset","")): return ["Unsupported generator version, seed or preset."]
	if not value.get("checksum") is String or value.checksum.length()!=64: return ["Missing geography checksum."]
	var digest:=checksum(value)
	if digest!=value.checksum: return ["Geography checksum mismatch."]
	if approved.has(digest): return []
	if not value.get("name") is String or value.name.length()>80 or not _integer(value.get("attempt"),0,7): return ["Invalid region metadata."]
	var issues:=Terrain.errors(value.get("terrain"))
	if not issues.is_empty(): return issues
	var factor:=int(value.version)
	if int(value.terrain.width)!=W*factor or int(value.terrain.height)!=H*factor: return ["Generated terrain dimensions differ."]
	if factor==2:
		if not value.get("climates") is Array or value.climates.size()!=3: return ["Missing large-region climate zones."]
		for index in range(3):
			var zone: Variant=value.climates[index]
			if not zone is Dictionary or zone.get("id")!=["wetwood","drylands","uplands"][index] or not _valid_point(zone.get("position")): return ["Invalid climate zone."]
			var radius: Variant=zone.get("radius")
			if not (radius is int or radius is float) or not is_finite(float(radius)) or radius<.1 or radius>.5: return ["Invalid climate radius."]
	elif value.has("climates"): return ["Classic region cannot contain climate zones."]
	if not value.get("sites") is Array or value.sites.size()!=6 or not value.get("roads") is Array or value.roads.size()!=5 or not value.get("road_paths") is Array or value.road_paths.size()!=5: return ["Missing functional sites or roads."]
	var anchors: Array=[]
	for index in range(6):
		var site: Variant=value.sites[index]
		if not site is Dictionary or site.get("id")!=IDS[index] or not site.get("position") is Dictionary or not site.get("name") is String: return ["Invalid functional site."]
		if not _valid_point(site.position): return ["Invalid site coordinates."]
		if site.get("kind")!=["town","town","town","dungeon","landmark","landmark"][index] or site.get("owner")!=["river_league","river_league","iron_march","bandits","iron_march","neutral"][index]: return ["Site role/owner differs."]
		anchors.append(site)
	var nav:=navigation(value)
	for index in range(6):
		for previous in range(index):
			if _distance(_point(value.sites[index].position),_point(value.sites[previous].position))<.234: return ["Functional sites are too close."]
	for index in range(5):
		var path: Variant=value.road_paths[index]
		var waypoints: Variant=value.roads[index]
		if not path is Array or path.size()<2 or path.size()>2000 or not waypoints is Array or waypoints.size()<5 or waypoints.size()>32: return ["Invalid road path/waypoints."]
		var previous:=Vector2.INF
		for position in path:
			if not _valid_point(position): return ["Invalid road coordinates."]
			var next:=_point(position)
			if not nav.passable(next) or (previous.is_finite() and not nav.line_clear(previous,next)): return ["Road crosses blocked geography."]
			previous=next
		for position in waypoints:
			if not _valid_point(position): return ["Invalid waypoint coordinates."]
			anchors.append({"id":"Road waypoint","position":position})
	issues=nav.connectivity_errors(anchors)
	if not issues.is_empty(): return issues
	if not value.get("bridges") is Array or value.bridges.size()<2 or value.bridges.size()>8 or not value.get("rivers") is Array or value.rivers.size()<1 or value.rivers.size()>3: return ["Missing rivers/crossings."]
	if value.terrain.crossings.size()!=value.bridges.size(): return ["Crossing metadata differs from terrain."]
	var bridge_index:=0
	for bridge in value.bridges:
		if not bridge is Dictionary or not _valid_point(bridge.get("position")) or not _valid_point(bridge.get("from")) or not _valid_point(bridge.get("to")): return ["Invalid bridge."]
		if nav.code_at(_point(bridge.position))!="B" or not nav.line_clear(_point(bridge.from),_point(bridge.to)): return ["Bridge does not join accessible banks."]
		if bridge.get("orientation") not in ["ne","nw"] or not bridge.get("id") is String or not bridge.get("name") is String: return ["Invalid crossing metadata."]
		var crossing: Dictionary=value.terrain.crossings[bridge_index]
		if crossing.id!=bridge.id or crossing.name!=bridge.name or crossing.position!=bridge.position: return ["Crossing metadata differs from terrain."]
		bridge_index+=1
	for river in value.rivers:
		if not river is Dictionary or not river.get("points") is Array or river.points.size()<2 or river.points.size()>2000 or not river.get("profile") is Array or river.profile.size()!=river.points.size(): return ["Invalid river."]
		for position in river.points:
			if not _valid_point(position): return ["Invalid river coordinates."]
			if nav.code_at(_point(position)) not in ["W","B"]: return ["River geometry leaves its channel."]
		var last:=1000000
		for elevation in river.profile:
			if not _integer(elevation,0,last): return ["River channel rises downstream."]
			last=int(elevation)
	for river_index in range(1,value.rivers.size()):
		if not value.rivers[0].points.has(value.rivers[river_index].points.back()): return ["Tributary does not join the main river."]
	if not value.get("diagnostics") is Dictionary: return ["Missing generation diagnostics."]
	for key in ["land_cells","connected_cells","bridges"]:
		if not _integer(value.diagnostics.get(key),1,W*H*factor*factor): return ["Invalid generation diagnostics."]
	if value.diagnostics.bridges!=value.bridges.size() or value.diagnostics.connected_cells>value.diagnostics.land_cells or float(value.diagnostics.connected_cells)<float(value.diagnostics.land_cells)*.75: return ["Disconnected mainland diagnostics."]
	if approved.size()>=32: approved.erase(approved.keys()[0])
	approved[digest]=true
	return []
static func _valid_point(value: Variant) -> bool:
	if not value is Dictionary: return false
	for key in ["x","y"]:
		var number: Variant=value.get(key)
		if not (number is float or number is int) or not is_finite(float(number)) or number<0 or number>=1: return false
	return true
