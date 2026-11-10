extends RefCounted
## Independent expedition actors; the classic world retains stock/manpower authority.
const R := preload("res://scripts/domain/strategic_region.gd")
const W := R.W
const Regions := preload("res://scripts/domain/world_life_regions.gd")
const P := preload("res://scripts/domain/world_life_politics.gd")
const DAY := 96
const PHASES := ["pressure","warning","commitment","action","resolution","aftermath"]

static func initial(s: Dictionary) -> Dictionary:
	var nav := R.G.Gen.navigation(s.region.base)
	var origin := R.G.point(s.region.sites.town_ravenford.position)
	var p: Vector2=nav.nearest(origin+Vector2(.045,-.035),origin)
	var site := {"id":"road_camp","name":"Briar Road Camp","kind":"dungeon","owner":"neutral","position":R.G.Terrain.packed(p),"family":"bandits","patron":"river_league","home":"town_ravenford","strength":17,"status":"occupied","episode":"episode_00000001","cleared_tick":0,"history":[],"seed":int(s.strategy_world.core.seed)+11}
	var life := {"version":1,"sites":{"road_camp":site},"actors":{},"episodes":{},"seq":1,"events":[],"stats":{"resolved":0,"failed":0,"hired":0,"fees":0,"casualties":0,"recruited":0,"transferred":0},"initial_strength":0,"politics":P.initial(s),"regions":Regions.initial()}
	for entry: Array in [["grey_lances","Grey Lances","town_ravenford",26,"rival"],["ember_rovers","Ember Rovers","ashmere",20,"rival"],["march_lancers","March Lancers","black_keep",24,"retainer"]]:
		life.actors[entry[0]]={"id":entry[0],"name":entry[1],"home":entry[2],"position":s.region.sites[entry[2]].position.duplicate(),"path":[],"status":"idle","episode":"","strength":entry[3],"cap":entry[3],"wallet":8,"ready_tick":0,"role":entry[4]}
		life.initial_strength+=int(entry[3])
	life.episodes[site.episode]=episode(site,0,"Bandits established a camp overlooking the road.")
	var origin2 := R.G.point(s.region.sites.ashmere.position)
	var p2: Vector2=nav.nearest(origin2+Vector2(-.045,-.04),origin2)
	var ruin: Dictionary=site.duplicate(true)
	ruin.merge({"id":"blackroot_ruins","name":"Blackroot Ruins","position":R.G.Terrain.packed(p2),"family":"ruins","patron":"cinder_compact","home":"ashmere","strength":31,"episode":"episode_00000002","seed":int(s.strategy_world.core.seed)+23},true)
	life.sites[ruin.id]=ruin;life.seq=2
	life.episodes[ruin.episode]=episode(ruin,0,"A raider fellowship occupies the ruined shrine and its vault.")

	return life

static func episode(site: Dictionary, tick: int, cause: String) -> Dictionary:
	return {"id":site.episode,"site":site.id,"cause":cause,"created_tick":tick,"phase":"pressure","phase_tick":tick,"actor":"","result":"","attempt":0,"contract":{},"resolved_tick":null}

static func event(s: Dictionary, life: Dictionary, e: Dictionary, text: String) -> void:
	life.events.append({"tick":int(s.strategy_world.core.tick),"source":s.region.sites[life.sites[e.site].home].name,"episode":e.id,"site":e.site,"text":text})
	while life.events.size()>128: life.events.pop_front()

static func phase(s: Dictionary, life: Dictionary, e: Dictionary, value: String, text: String) -> void:
	e.phase=value;e.phase_tick=int(s.strategy_world.core.tick)
	event(s,life,e,text)

static func offer(s: Dictionary, life: Dictionary, e: Dictionary) -> void:
	var site: Dictionary=life.sites[e.site]
	var hold := R.C.S.next_id(s.strategy_world,"hold")
	if R.C._operate(s.strategy_world,site.patron,"reserve_budget",{"id":hold,"resource":"coin","amount":24,"purpose":e.id})!="": return
	e.contract={"issuer":site.patron,"town":site.home,"hold":hold,"gold":24,"xp":8,"status":"offered","claim":"","deadline":0}
	event(s,life,e,"%s offers 24g / 8XP to clear %s. Company claims are exclusive for 5 days; completed work remains payable." % [s.strategy_world.core.factions[site.patron].name,site.name])

static func release(s: Dictionary, c: Dictionary) -> void:
	if not c.is_empty(): R.C._operate(s.strategy_world,c.issuer,"release_budget",{"id":c.hold})

static func pay_npc(s: Dictionary, life: Dictionary, e: Dictionary, actor: Dictionary, success: bool) -> void:
	var c: Dictionary=e.contract
	release(s,c)
	var amount := int(c.gold) if success else 8
	if R.C._spend(s.strategy_world,c.issuer,{"coin":amount}):
		actor.wallet+=amount;life.stats.fees+=amount
	c.status="paid" if success else "closed"

static func send(s: Dictionary, actor: Dictionary, target: Dictionary, status: String) -> bool:
	var nav := R.G.Gen.navigation(s.region.base)
	var path: Array=nav.route(R.G.point(actor.position),R.G.point(target.position))
	if path.is_empty(): return false
	actor.path=path;actor.status=status
	return true

static func resolve(s: Dictionary, life: Dictionary, e: Dictionary, winner: String) -> void:
	if e.resolved_tick!=null: return
	var site: Dictionary=life.sites[e.site]
	site.status="cleared";site.strength=0;site.cleared_tick=int(s.strategy_world.core.tick)
	e.result=winner;e.resolved_tick=int(s.strategy_world.core.tick);life.stats.resolved+=1
	site.history.append(e.id)
	phase(s,life,e,"resolution",site.name+" cleared by "+winner+". The road is safer; the result is permanent for this occupation.")

static func tick(s: Dictionary, life: Dictionary, motion: Dictionary={}) -> void:
	var now := int(s.strategy_world.core.tick)
	for id: String in R.C.S.sorted_ids(life.actors):
		var a: Dictionary=life.actors[id]
		if not a.path.is_empty():
			var detail := {};var budget := .016/R.G.travel_scale(s.region)
			var arrived: bool=R.G.Gen.navigation(s.region.base).walk(a,a.path,budget,detail)
			motion[id]={"budget":budget,"samples":detail.samples,"tick":now}
			if arrived:
				if a.status=="outbound": a.status="working";a.ready_tick=now+12
				else: a.status="idle";a.episode="";a.ready_tick=now+48
		elif a.status=="idle" and now>=a.ready_tick and a.strength<a.cap and a.wallet>=2:
			a.wallet-=2;a.strength+=1;a.ready_tick=now+48;life.stats.recruited+=1
	for id: String in R.C.S.sorted_ids(life.episodes):
		var e: Dictionary=life.episodes[id];var site: Dictionary=life.sites[e.site]
		if e.contract.get("status")=="company" and now>=e.contract.deadline and s.run_context.get("site","")!=e.site:
			e.contract.status="offered";e.contract.claim=""
			phase(s,life,e,"warning","Company exclusivity expired; the unfinished commission is open again.")
		if e.phase=="pressure" and now-int(e.phase_tick)>=48:
			phase(s,life,e,"warning",site.name+": scouts confirm an occupied camp. A paid response is needed.")
		if e.phase=="warning":
			if e.contract.is_empty() or e.contract.status=="closed": offer(s,life,e)
			if not e.contract.is_empty() and e.contract.status=="offered" and now-int(e.phase_tick)>=96:
				for actor_id: String in R.C.S.sorted_ids(life.actors):
					var a: Dictionary=life.actors[actor_id]
					if a.role!="rival" or a.status!="idle" or a.strength<10 or now<a.ready_tick: continue
					if send(s,a,site,"outbound"):
						a.episode=e.id;e.actor=a.id;e.attempt+=1;e.contract.status="npc";e.contract.claim=a.id;life.stats.hired+=1
						phase(s,life,e,"commitment",a.name+" accepted the funded commission and departed for "+site.name+".")
						break
		elif e.phase=="commitment" and life.actors[e.actor].status=="working":
			phase(s,life,e,"action",life.actors[e.actor].name+" reached "+site.name+" and is assaulting the camp.")
		elif e.phase=="action" and now>=life.actors[e.actor].ready_tick:
			var a: Dictionary=life.actors[e.actor]
			var roll := int((str(s.strategy_world.core.seed)+e.id+str(e.attempt)).sha256_text().substr(0,6).hex_to_int()%7)-3
			var success: bool=a.strength+roll>=site.strength
			var losses := mini(int(a.strength),maxi(2,ceili(float(site.strength)*(.22 if success else .45))))
			a.strength-=losses;life.stats.casualties+=losses
			pay_npc(s,life,e,a,success)
			if success: resolve(s,life,e,a.name)
			else:
				site.strength=maxi(1,int(site.strength)-4);life.stats.failed+=1
				phase(s,life,e,"pressure",a.name+" retreated with losses. The camp survives weakened; another response needs new funding.")
				e.phase_tick=now+144
			send(s,a,s.region.sites[a.home],"returning")
		elif e.phase=="resolution" and now-int(e.phase_tick)>=96:
			phase(s,life,e,"aftermath",site.name+": survivors have returned and the cleared-road report is confirmed.")

	for site: Dictionary in life.sites.values(): Regions.raid(s,life,site)
	for id: String in Regions.tick(s,life,motion):
		var site: Dictionary=life.sites[id]
		life.episodes[site.episode]=episode(site,now,"Displaced survivors physically reached the cleared site.")
		event(s,life,life.episodes[site.episode],site.name+": a new band arrived. Earlier clearings remain in the site history.")
	P.tick(s,life)

static func valid(s: Dictionary, l: Variant) -> bool:
	if not W._shape(l,["version","sites","actors","episodes","seq","events","stats","initial_strength","politics","regions"]) or not W._count(l.version,1,1) or not W._registry(l.sites,1,16) or not W._registry(l.actors,1,16) or not W._registry(l.episodes,1,512) or not W._count(l.seq,1) or l.episodes.size()>l.seq or not l.events is Array or l.events.size()>128: return false
	if not W._shape(l.stats,["resolved","failed","hired","fees","casualties","recruited","transferred"]): return false
	for n: Variant in l.stats.values():
		if not W._count(n): return false
	if not l.politics.get("campaigns") is Dictionary: return false
	for e: Variant in l.episodes.values():
		if not e is Dictionary: return false
	var total := 0
	var wallets := 0
	var now := int(s.strategy_world.core.tick)
	var nav := R.G.Gen.navigation(s.region.base)
	for id: String in l.actors:
		var a: Variant=l.actors[id]
		if not W._shape(a,["id","name","home","position","path","status","episode","strength","cap","wallet","ready_tick","role"]) or a.id!=id or a.role not in ["rival","retainer"] or not W._text(a.name) or not s.region.sites.has(a.home) or not R.G.Gen._valid_point(a.position) or not a.path is Array or a.path.size()>2000 or a.status not in ["idle","outbound","working","returning"] or not W._count(a.cap,1,100) or not W._count(a.strength,0,int(a.cap)) or not W._count(a.wallet) or not W._count(a.ready_tick): return false
		if a.episode!="" and not l.episodes.has(a.episode) and not l.politics.campaigns.has(a.episode): return false
		for p: Variant in a.path:
			if not R.G.Gen._valid_point(p): return false
		if not nav.passable(R.G.point(a.position)) or not is_finite(nav.route_cost(R.G.point(a.position),a.path)): return false
		total+=int(a.strength)
		wallets+=int(a.wallet)
	if not W._count(l.initial_strength) or total+int(l.stats.casualties)+int(l.stats.transferred)!=int(l.initial_strength)+int(l.stats.recruited): return false
	if wallets+2*int(l.stats.recruited)!=8*l.actors.size()+int(l.stats.fees): return false
	for id: String in l.sites:
		var p: Variant=l.sites[id]
		if not W._shape(p,["id","name","kind","owner","position","family","patron","home","strength","status","episode","cleared_tick","history","seed"]) or p.id!=id or not W._text(p.name) or p.kind!="dungeon" or p.owner!="neutral" or p.family not in ["bandits","ruins"] or not s.strategy_world.core.factions.has(p.patron) or not s.region.sites.has(p.home) or not R.G.Gen._valid_point(p.position) or not nav.passable(R.G.point(p.position)) or not W._count(p.strength,0,100) or p.status not in ["occupied","cleared"] or not l.episodes.has(p.episode) or not W._count(p.cleared_tick,0,now) or not W._count(p.seed,1) or not p.history is Array: return false
		if (p.status=="cleared")!=(p.strength==0): return false
		if l.episodes[p.episode].get("site")!=id: return false
		var seen := {}
		for old: Variant in p.history:
			if not old is String or seen.has(old) or not l.episodes.has(old) or l.episodes[old].get("site")!=id or l.episodes[old].get("resolved_tick")==null: return false
			seen[old]=true
		if p.status=="cleared" and not seen.has(p.episode): return false
	for id: String in l.episodes:
		var e: Variant=l.episodes[id]
		if not W._shape(e,["id","site","cause","created_tick","phase","phase_tick","actor","result","attempt","contract","resolved_tick"]) or e.id!=id or not l.sites.has(e.site) or e.phase not in PHASES or not W._text(e.cause) or not W._count(e.created_tick,0,now) or not W._count(e.phase_tick) or not W._count(e.attempt) or not e.result is String or (e.actor!="" and not l.actors.has(e.actor)): return false
		if e.resolved_tick!=null and not W._count(e.resolved_tick,e.created_tick,now): return false
		if (e.phase in ["resolution","aftermath"])!=(e.resolved_tick!=null): return false
		if (e.result!="")!=(e.resolved_tick!=null): return false
		if e.phase in ["commitment","action"] and (e.actor=="" or l.actors[e.actor].episode!=id): return false
		var c: Variant=e.contract
		if not c is Dictionary: return false
		if not c.is_empty():
			if not W._shape(c,["issuer","town","hold","gold","xp","status","claim","deadline"]) or c.issuer!=l.sites[e.site].patron or c.town!=l.sites[e.site].home or not W._count(c.gold,24,24) or not W._count(c.xp,8,8) or c.status not in ["offered","npc","company","objective","paid","closed"] or not c.claim is String or not W._count(c.deadline): return false
			if c.status in ["company","objective"] and c.claim!="company": return false
			if c.status=="objective" and e.result!="company": return false
			var hold: Dictionary=s.strategy_world.core.reservations.get(c.hold,{})
			if c.status in ["offered","npc","company","objective"]:
				if hold.is_empty() or hold.status!="reserved" or hold.amount!=24 or hold.purpose!=e.id or hold.faction_id!=c.issuer: return false
			elif not hold.is_empty() and hold.status!="released": return false
	for e: Variant in l.events:
		if not W._shape(e,["tick","source","episode","site","text"]) or not W._count(e.tick,0,now) or not W._text(e.source) or not l.episodes.has(e.episode) or not l.sites.has(e.site) or not e.text is String or e.text.length()>512: return false
	return P.valid(s,l) and Regions.valid(s,l)
