extends RefCounted
## Immutable physical binding for a fresh four-faction world; never edits old maps.
const Gen := preload("res://scripts/domain/region_generator.gd")
const Terrain := preload("res://scripts/domain/terrain_navigation.gd")
const W := preload("res://scripts/domain/world_strategy.gd")
const SPEED := .007
static var approved: Dictionary={}
static var edge_samples: Dictionary={}

static func point(p: Dictionary) -> Vector2: return Vector2(float(p.x),float(p.y))
static func world_scale(g: Dictionary) -> float: return float(Gen.world_scale(int(g.base.version)))
static func travel_scale(g: Dictionary) -> float: return world_scale(g)/2.0
static func route_ticks(cost: float, g: Dictionary) -> int: return maxi(1,ceili(cost/(SPEED/travel_scale(g))))

static func build(core: Dictionary, preset: String="marches", geography_version: int=2) -> Dictionary:
	if geography_version not in [2,3]: return {}
	var base := Gen.generate(int(core.seed),preset,geography_version)
	if base.is_empty(): return {}
	var nav := Gen.navigation(base)
	var sites := {}
	for entry: Dictionary in base.sites: sites[entry.id]=entry.duplicate(true)
	var origin := point(sites.town_ravenford.position)
	nav.nearest(origin,origin) # Cache the actual reachable mainland component.
	for id: String in ["ironhold","ashmere","thornhaven"]:
		var desired := Vector2(float(core.settlements[id].x),float(core.settlements[id].y))
		var best := Vector2.INF;var score := -INF
		for y in range(6,nav.dimensions.y-6,4):
			for x in range(6,nav.dimensions.x-6,4):
				var cell := Vector2i(x,y)
				if not nav.recovery_cells.has(cell): continue
				var candidate: Vector2=nav.center(cell)
				var clearance := INF
				for entry: Dictionary in sites.values(): clearance=minf(clearance,((candidate-point(entry.position))*Terrain.ASPECT).length())
				if clearance<.17: continue
				var rating := clearance*3-((candidate-desired)*Terrain.ASPECT).length()*.25
				if rating>score: score=rating;best=candidate
		if not best.is_finite(): return {}
		sites[id]={"id":id,"name":core.settlements[id].name,"kind":"town","owner":core.settlements[id].owner_id,"position":Terrain.packed(best)}
	var routes := {}
	for id: String in core.routes:
		var edge: Dictionary=core.routes[id]
		var a := point(sites[edge.a].position);var b := point(sites[edge.b].position)
		var path: Array=[Terrain.packed(a)];path.append_array(nav.route(a,b))
		var cost: float=nav.route_cost(a,path.slice(1))
		if path.size()<2 or not is_finite(cost) or cost<=0: return {}
		cost=float("%.7f" % cost)
		routes[id]={"a":edge.a,"b":edge.b,"points":path,"cost":cost,"ticks":route_ticks(cost,{"base":base})}
	var result := {"schema":"sdd.strategic-geography","version":1,"base":base,"sites":sites,"routes":routes,"checksum":""}
	result.checksum=Gen.checksum(result)
	return result if valid(result) else {}

static func valid(g: Variant) -> bool:
	if not W._shape(g,["schema","version","base","sites","routes","checksum"]) or g.schema!="sdd.strategic-geography" or not W._count(g.version,1,1) or not g.checksum is String or Gen.checksum(g)!=g.checksum: return false
	if not g.base is Dictionary or not W._count(g.base.get("version"),2,3) or not g.base.get("checksum") is String or Gen.checksum(g.base)!=g.base.checksum: return false
	if approved.has(g.checksum): return true
	if not Gen.errors(g.base).is_empty() or not W._registry(g.sites,9,9) or not W._registry(g.routes,7,7): return false
	var nav := Gen.navigation(g.base)
	for id: String in g.sites:
		var site: Variant=g.sites[id]
		if not W._shape(site,["id","name","kind","owner","position"]) or site.id!=id or not W._text(site.name) or site.kind not in ["town","dungeon","landmark"] or not W._id(site.owner) or not Gen._valid_point(site.position) or not nav.passable(point(site.position)): return false
	for original: Dictionary in g.base.sites:
		if g.sites.get(original.id)!={"id":original.id,"name":original.name,"kind":original.kind,"owner":original.owner,"position":original.position}: return false
	for edge: Variant in g.routes.values():
		if not W._shape(edge,["a","b","points","cost","ticks"]) or not W._id(edge.a) or not W._id(edge.b) or not g.sites.has(edge.a) or not g.sites.has(edge.b) or edge.a==edge.b: return false
		if not edge.points is Array or edge.points.size()<2 or edge.points.size()>2000 or not (edge.cost is float or edge.cost is int) or not is_finite(float(edge.cost)) or edge.cost<=0 or not W._count(edge.ticks,1,1000000): return false
		if edge.points.front()!=g.sites[edge.a].position or edge.points.back()!=g.sites[edge.b].position: return false
		for p: Variant in edge.points:
			if not Gen._valid_point(p): return false
		var measured: float=nav.route_cost(point(edge.points[0]),edge.points.slice(1))
		if not is_finite(measured) or absf(measured-float(edge.cost))>.000001 or edge.ticks!=route_ticks(float(edge.cost),g): return false
	if approved.size()>12: approved.erase(approved.keys()[0])
	approved[g.checksum]=true
	return true

static func bind(core: Dictionary, g: Dictionary) -> void:
	for id: String in core.settlements:
		core.settlements[id].x=g.sites[id].position.x;core.settlements[id].y=g.sites[id].position.y
	for id: String in core.routes: core.routes[id].travel_ticks=int(g.routes[id].ticks)
	core.topology_kind="abstract_fixture" # Core format retained; the parent validates physical binding.

static func binding_valid(core: Dictionary, g: Dictionary) -> bool:
	if not valid(g) or core.seed!=g.base.seed or core.routes.size()!=g.routes.size(): return false
	for id: String in core.settlements:
		if not g.sites.has(id) or g.sites[id].owner!=core.settlements[id].owner_id or core.settlements[id].x!=g.sites[id].position.x or core.settlements[id].y!=g.sites[id].position.y: return false
	for id: String in core.routes:
		if not g.routes.has(id) or core.routes[id].a!=g.routes[id].a or core.routes[id].b!=g.routes[id].b or core.routes[id].travel_ticks!=g.routes[id].ticks: return false
	return true

static func edge(g: Dictionary, a: String, b: String) -> Dictionary:
	for e: Dictionary in g.routes.values():
		if (e.a==a and e.b==b) or (e.a==b and e.b==a): return e
	return {}

static func on_edge(g: Dictionary, a: String, b: String, progress: float) -> Vector2:
	var e := edge(g,a,b)
	if e.is_empty(): return point(g.sites[a].position)
	if progress<=0: return point(g.sites[a].position)
	if progress>=1: return point(g.sites[b].position)
	var key: String=g.checksum+"|"+a+"|"+b
	var nav := Gen.navigation(g.base)
	if not edge_samples.has(key):
		var points: Array=e.points.duplicate()
		if e.a!=a: points.reverse()
		var cumulative: Array[float]=[0.0]
		for i in range(1,points.size()): cumulative.append(cumulative.back()+nav.route_cost(point(points[i-1]),[points[i]]))
		if edge_samples.size()>=128: edge_samples.erase(edge_samples.keys()[0])
		edge_samples[key]={"points":points,"cumulative":cumulative}
	var samples: Dictionary=edge_samples[key]
	var wanted := progress*float(e.cost)
	var low := 0;var high: int=samples.points.size()-1
	while high-low>1:
		var mid := (low+high)/2
		if samples.cumulative[mid]<wanted: low=mid
		else: high=mid
	var unit := {"position":samples.points[low]}
	nav.walk(unit,[samples.points[high]],maxf(0,wanted-float(samples.cumulative[low])))
	return point(unit.position)

static func actor_position(g: Dictionary, current: Dictionary, previous: Dictionary={}, phase: float=1.0) -> Vector2:
	if current.edge_to!="":
		var e := edge(g,current.at,current.edge_to)
		var elapsed := float(e.ticks)-float(current.remaining)
		if not previous.is_empty() and previous.at==current.at: elapsed=maxf(0,elapsed-1+phase)
		return on_edge(g,current.at,current.edge_to,elapsed/float(e.ticks))
	if not previous.is_empty() and previous.get("edge_to")==current.at and previous.at!=current.at:
		var e := edge(g,previous.at,current.at)
		return on_edge(g,previous.at,current.at,(float(e.ticks)-1+phase)/float(e.ticks))
	return point(g.sites[current.at].position)
