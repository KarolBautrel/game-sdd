extends RefCounted
const R := preload("res://scripts/domain/strategic_region.gd")
const W := R.W
const Disputes := preload("res://scripts/domain/world_life_disputes.gd")
static func initial(s: Dictionary) -> Dictionary:
	var p := {"outposts":{},"campaigns":{},"seq":0,"initial_guards":36,"casualties":0,"recruited":0,"reserve":{},"captures":0,"dispute":{}}
	for faction: String in s.strategy_world.core.factions: p.reserve[faction]=18
	for row: Array in [["river_watch","River Watch","river_league","town_ravenford"],["iron_redoubt","Iron Redoubt","iron_march","black_keep"],["thorn_gate","Thorn Gate","thornwood_accord","thornhaven"]]:
		var origin := R.G.point(s.region.sites[row[3]].position)
		var point: Vector2=R.G.Gen.navigation(s.region.base).nearest(origin+Vector2(-.055,.04),origin)
		p.outposts[row[0]]={"id":row[0],"name":row[1],"kind":"landmark","owner":row[2],"position":R.G.Terrain.packed(point),"home":row[3],"garrison":12,"cooldown":0,"recruit_tick":48,"history":[]}
	return p

static func note(s: Dictionary, post: Dictionary, text: String) -> void:
	R._note(s,"outpost_campaign",post.id,post.name+": "+text)

static func returning(s: Dictionary, a: Dictionary) -> void:
	var path: Array=R.G.Gen.navigation(s.region.base).route(R.G.point(a.position),R.G.point(s.region.sites[a.home].position))
	a.path=path;a.status="returning"

static func tick(s: Dictionary, life: Dictionary) -> void:
	var p: Dictionary=life.politics;var now := int(s.strategy_world.core.tick)
	Disputes.tick(s,p)
	for id: String in R.C.S.sorted_ids(p.outposts):
		var post: Dictionary=p.outposts[id]
		if now>=post.recruit_tick and post.garrison<12 and p.reserve[post.owner]>0 and R.C._spend(s.strategy_world,post.owner,{"coin":2}):
			post.garrison+=1;post.recruit_tick=now+48;p.reserve[post.owner]-=1;p.recruited+=1
	for id: String in R.C.S.sorted_ids(p.campaigns):
		var c: Dictionary=p.campaigns[id]
		if c.status in ["occupied","repelled","cancelled"]: continue
		var post: Dictionary=p.outposts[c.target];var a: Dictionary=life.actors[c.actor]
		if post.owner==c.faction or not R.C.S.hostile(s.strategy_world,c.faction,post.owner):
			c.status="cancelled";c.ended_tick=now;returning(s,a);note(s,post,"the offensive was cancelled after diplomacy changed; the hired company is returning.");continue
		if c.status=="warning" and now>=c.ready_tick:
			var path: Array=R.G.Gen.navigation(s.region.base).route(R.G.point(a.position),R.G.point(post.position))
			if path.is_empty(): c.status="cancelled";c.ended_tick=now;returning(s,a);continue
			a.path=path;a.status="outbound";c.status="marching";note(s,post,a.name+" is marching for "+s.strategy_world.core.factions[c.faction].name+".")
		elif c.status=="marching" and a.status=="working":
			c.status="action";note(s,post,a.name+" reached the defenses. The garrison is resisting.")
		elif c.status=="action" and now>=a.ready_tick:
			var roll := int((id+str(s.strategy_world.core.seed)).sha256_text().substr(0,6).hex_to_int()%7)-3
			var win: bool=a.strength+roll>post.garrison
			var lost := mini(int(a.strength),maxi(2,ceili(float(post.garrison)*(.3 if win else .6))))
			a.strength-=lost;life.stats.casualties+=lost
			var guard_loss := int(post.garrison) if win else mini(int(post.garrison),maxi(1,int(a.strength)/4))
			post.garrison-=guard_loss;p.casualties+=guard_loss
			if win:
				var committed := mini(4,int(a.strength));a.strength-=committed;life.stats.transferred+=committed
				post.garrison=committed;post.owner=c.faction;post.cooldown=now+672;post.recruit_tick=now+48
				post.history.append({"tick":now,"campaign":id,"owner":c.faction});c.status="occupied";p.captures+=1
				note(s,post,c.faction.replace("_"," ").capitalize()+" took the outpost after a real assault. A detached garrison holds it; recovery begins.")
			else: c.status="repelled";post.cooldown=now+192;note(s,post,"the assault was repelled with losses. The garrison holds and repairs the defenses.")
			c.ended_tick=now;returning(s,a)
	if now%96!=0: return
	for faction: String in R.C.S.sorted_ids(s.strategy_world.core.factions):
		var active := false
		for c: Dictionary in p.campaigns.values():
			if c.faction==faction and c.status in ["warning","marching","action"]: active=true
		if active: continue
		for id: String in R.C.S.sorted_ids(p.outposts):
			var post: Dictionary=p.outposts[id]
			if now<post.cooldown or post.owner==faction or not R.C.S.hostile(s.strategy_world,faction,post.owner): continue
			for actor_id: String in R.C.S.sorted_ids(life.actors):
				var a: Dictionary=life.actors[actor_id]
				if a.status!="idle" or now<a.ready_tick or a.strength<14: continue
				if not R.C._spend(s.strategy_world,faction,{"coin":20}): break
				a.wallet+=20;life.stats.fees+=20;p.seq+=1
				var campaign := "campaign_%08d" % int(p.seq)
				p.campaigns[campaign]={"id":campaign,"target":id,"faction":faction,"actor":actor_id,"cause":"Existing war and a defended enemy corridor outpost.","status":"warning","created_tick":now,"ready_tick":now+96,"ended_tick":null}
				a.episode=campaign;a.status="working";a.ready_tick=now+96
				note(s,post,s.strategy_world.core.factions[faction].name+" hired "+a.name+" for20coin. One-day warning before the offensive.")
				active=true;break
			if active: break

static func valid(s: Dictionary, life: Dictionary) -> bool:
	var p: Variant=life.politics
	if not W._shape(p,["outposts","campaigns","seq","initial_guards","casualties","recruited","reserve","captures","dispute"]) or not Disputes.valid(s,p.dispute) or not W._registry(p.outposts,3,3) or not W._registry(p.campaigns,0,256) or not W._count(p.seq) or p.seq<p.campaigns.size() or not W._count(p.initial_guards,36,36) or not W._count(p.casualties) or not W._count(p.recruited,0,72) or not W._count(p.captures) or not p.reserve is Dictionary or R.C.S.sorted_ids(p.reserve)!=R.C.S.sorted_ids(s.strategy_world.core.factions): return false
	var reserve := 0
	for v: Variant in p.reserve.values():
		if not W._count(v,0,18): return false
		reserve+=int(v)
	if reserve+int(p.recruited)!=72: return false
	var guards := 0
	for id: String in p.outposts:
		var post: Variant=p.outposts[id]
		if not W._shape(post,["id","name","kind","owner","position","home","garrison","cooldown","recruit_tick","history"]) or post.id!=id or not W._text(post.name) or post.kind!="landmark" or not s.strategy_world.core.factions.has(post.owner) or not s.region.sites.has(post.home) or not R.G.Gen._valid_point(post.position) or not W._count(post.garrison,0,12) or not W._count(post.cooldown) or not W._count(post.recruit_tick) or not post.history is Array: return false
		if not R.G.Gen.navigation(s.region.base).passable(R.G.point(post.position)): return false
		guards+=int(post.garrison)
		for entry: Variant in post.history:
			if not W._shape(entry,["tick","campaign","owner"]) or not W._count(entry.tick,0,int(s.strategy_world.core.tick)) or not p.campaigns.has(entry.campaign) or not s.strategy_world.core.factions.has(entry.owner): return false
	if guards+int(p.casualties)!=int(p.initial_guards)+int(p.recruited)+int(life.stats.transferred): return false
	var committed := {}
	for id: String in p.campaigns:
		var c: Variant=p.campaigns[id]
		if not W._shape(c,["id","target","faction","actor","cause","status","created_tick","ready_tick","ended_tick"]) or c.id!=id or not p.outposts.has(c.target) or not s.strategy_world.core.factions.has(c.faction) or not life.actors.has(c.actor) or not W._text(c.cause) or c.status not in ["warning","marching","action","occupied","repelled","cancelled"] or not W._count(c.created_tick,0,int(s.strategy_world.core.tick)) or c.ready_tick!=c.created_tick+96: return false
		if c.status in ["warning","marching","action"]:
			if c.ended_tick!=null or committed.has(c.actor) or life.actors[c.actor].episode!=id: return false
			committed[c.actor]=true
		elif not W._count(c.ended_tick,c.created_tick,int(s.strategy_world.core.tick)): return false
	return true
