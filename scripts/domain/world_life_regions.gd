extends RefCounted
## One global actor clock. District reports never simulate a second copy.
const R := preload("res://scripts/domain/strategic_region.gd")
const W := R.W
const DISTRICTS := {"riverlands":"Western Riverlands","marches":"Central Marches","highlands":"Eastern Highlands"}
static func district(point: Dictionary) -> String:
	return "riverlands" if float(point.x)<1.0/3 else ("marches" if float(point.x)<2.0/3 else "highlands")
static func initial() -> Dictionary:
	return {"reports":{},"bulletins":{},"observations":{},"migrations":{},"reserve":{"bandits":24,"ruins":24},"seq":0,"raids":0}
static func tick(s: Dictionary, life: Dictionary, motion: Dictionary={}) -> Array[String]:
	var r: Dictionary=life.regions;var now := int(s.strategy_world.core.tick)
	var arrived: Array[String]=[]
	var nav := R.G.Gen.navigation(s.region.base)
	for m: Dictionary in r.migrations.values():
		if m.status!="travelling": continue
		var detail := {};var budget := .012/R.G.travel_scale(s.region)
		var reached: bool=nav.walk(m,m.path,budget,detail)
		motion[m.id]={"budget":budget,"samples":detail.samples,"tick":now}
		if reached:
			m.status="arrived";m.arrived_tick=now
			var site: Dictionary=life.sites[m.site]
			if site.status=="cleared":
				site.status="occupied";site.strength=int(m.strength);life.seq+=1
				site.episode="episode_%08d" % int(life.seq);site.seed+=int(life.seq)
				arrived.append(site.id)
	var catalog := R.sites(s,life.sites);catalog.merge(life.politics.outposts)
	var here := R.current(s,catalog)
	if life.sites.has(here):
		var site: Dictionary=life.sites[here]
		r.observations[here]={"tick":now,"episode":site.episode,"status":site.status,"source":"Company observation"}
	if now%96!=0: return arrived
	# Settlement messengers deliver the preceding day's summary, never future facts.
	if R.at_town(s): r.bulletins=r.reports.duplicate(true)
	for id: String in DISTRICTS:
		var threats := 0;var camps := 0;var posts: Array=[]
		for site: Dictionary in life.sites.values():
			if district(site.position)!=id: continue
			camps+=1
			if site.status=="occupied": threats+=1
		for post: Dictionary in life.politics.outposts.values():
			if district(post.position)==id: posts.append(post.name+" / "+s.strategy_world.core.factions[post.owner].name)
		r.reports[id]={"tick":now,"source":"Settlement messengers","threats":threats,"sites":camps,"control":posts}
	for id: String in R.C.S.sorted_ids(life.sites):
		var site: Dictionary=life.sites[id]
		if site.status!="cleared" or now-int(site.cleared_tick)<1344 or r.reserve[site.family]<12: continue
		var incoming := false
		for m: Dictionary in r.migrations.values():
			if m.site==id and m.status=="travelling": incoming=true
		if incoming: continue
		var origin := R.G.point(s.region.sites[site.home].position)
		var source: Vector2=nav.nearest(origin+Vector2(.13,.08),origin)
		var path: Array=nav.route(source,R.G.point(site.position))
		if path.is_empty(): continue
		r.seq+=1;var mid := "migration_%08d" % int(r.seq)
		r.migrations[mid]={"id":mid,"site":id,"family":site.family,"source":"Displaced survivors from the hinterland","position":R.G.Terrain.packed(source),"path":path,"strength":12,"status":"travelling","created_tick":now,"arrived_tick":null}
		r.reserve[site.family]-=12
		R._note(s,"migration",id,"Scouts report a displaced band travelling toward "+site.name+". A new occupation requires its arrival.")
	return arrived

static func raid(s: Dictionary, life: Dictionary, site: Dictionary) -> void:
	var world: Dictionary=s.strategy_world
	if int(world.core.tick)%96!=0 or site.status!="occupied": return
	for id: String in R.C.S.sorted_ids(world.trades):
		var t: Dictionary=world.trades[id]
		if t.status!="transit" or t.cargo<=0: continue
		var position := R.G.actor_position(s.region,t)
		if ((position-R.G.point(site.position))*R.G.Terrain.ASPECT).length()>.085/R.G.travel_scale(s.region): continue
		var guards := 0
		for aid: String in world.forces:
			var army: Dictionary=world.core.parties[aid]
			if army.faction_id not in [t.seller,t.buyer]: continue
			var force: Dictionary=world.forces[aid]
			if force.ready_tick<=world.core.tick and R.G.actor_position(s.region,force).distance_to(position)<.05/R.G.travel_scale(s.region): guards+=int(army.headcount)
		if guards>=site.strength: continue
		world.ledger.lost[t.resource]+=int(t.cargo);world.core.factions[t.buyer].stocks.coin+=int(t.escrow)
		R.C.S.event(world,"convoy_lost","bandits",id,"occupied_road_camp",t.resource,int(t.cargo))
		t.cargo=0;t.escrow=0;t.remaining=0;t.edge_to="";t.status="lost";world.metrics.trade_lost+=1
		life.regions.raids+=1
		R._note(s,"bandit_raid",site.id,site.name+": an unprotected passing convoy was lost; its cargo and escrow were settled once.")
		break

static func valid(s: Dictionary, life: Dictionary) -> bool:
	var r: Variant=life.regions
	if not W._shape(r,["reports","bulletins","observations","migrations","reserve","seq","raids"]) or not W._registry(r.reports,0,3) or not W._registry(r.bulletins,0,3) or not W._registry(r.observations,0,16) or not W._registry(r.migrations,0,4) or not W._shape(r.reserve,["bandits","ruins"]) or not W._count(r.seq,0,4) or r.migrations.size()!=r.seq or not W._count(r.raids): return false
	var committed := {"bandits":0,"ruins":0}
	for id: String in r.migrations:
		var m: Variant=r.migrations[id]
		if not W._shape(m,["id","site","family","source","position","path","strength","status","created_tick","arrived_tick"]) or m.id!=id or not life.sites.has(m.site) or m.family!=life.sites[m.site].family or not W._text(m.source) or not R.G.Gen._valid_point(m.position) or not m.path is Array or not W._count(m.strength,12,12) or m.status not in ["travelling","arrived"] or not W._count(m.created_tick,1344,int(s.strategy_world.core.tick)): return false
		if m.status=="arrived" and not W._count(m.arrived_tick,m.created_tick,int(s.strategy_world.core.tick)): return false
		if m.status=="travelling" and m.arrived_tick!=null: return false
		for point: Variant in m.path:
			if not R.G.Gen._valid_point(point): return false
		if not is_finite(R.G.Gen.navigation(s.region.base).route_cost(R.G.point(m.position),m.path)): return false
		committed[m.family]+=int(m.strength)
	for family: String in committed:
		if not W._count(r.reserve[family],0,24) or r.reserve[family]+committed[family]!=24: return false
	for registry: Dictionary in [r.reports,r.bulletins]:
		for id: String in registry:
			var report: Variant=registry[id]
			if not DISTRICTS.has(id) or not W._shape(report,["tick","source","threats","sites","control"]) or not W._count(report.tick,0,int(s.strategy_world.core.tick)) or not W._text(report.source) or not W._count(report.sites,0,16) or not W._count(report.threats,0,int(report.sites)) or not report.control is Array: return false
			for text: Variant in report.control:
				if not W._text(text): return false
	for id: String in r.observations:
		var o: Variant=r.observations[id]
		if not life.sites.has(id) or not W._shape(o,["tick","episode","status","source"]) or not W._count(o.tick,0,int(s.strategy_world.core.tick)) or not life.episodes.has(o.episode) or o.status not in ["occupied","cleared"] or o.source!="Company observation": return false
	return true
