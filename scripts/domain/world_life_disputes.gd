extends RefCounted
## A material corridor dispute; all commitments go through existing classic operators.
const R := preload("res://scripts/domain/strategic_region.gd")
const W := R.W
static func shortage(world: Dictionary) -> bool:
	return W.available(world.core,"iron_march","ore")<int(world.rules.policies.iron_march.targets.ore)/2
static func finish(s: Dictionary, d: Dictionary, reason: String) -> void:
	d.status="settled";d.ended_tick=int(s.strategy_world.core.tick);d.reason=reason
	R._note(s,"corridor_dispute","high_pass",reason)
static func tick(s: Dictionary, p: Dictionary) -> void:
	var world: Dictionary=s.strategy_world;var now := int(world.core.tick)
	if now%24!=0: return
	var key := W.pair_key("iron_march","river_league")
	var hostile := R.C.S.hostile(world,"iron_march","river_league")
	if p.dispute.is_empty():
		if hostile or not shortage(world) or R.C._pact_blocks(world,"iron_march","river_league"): return
		for offer: Dictionary in world.core.pact_offers.values():
			if offer.status=="pending" and W.pair_key(offer.proposer,offer.recipient)==key: return
		var id := R.C.S.next_id(world,"pact")
		if R.C._operate(world,"iron_march","propose_pact",{"id":id,"target":"river_league","kind":"nonaggression","duration_ticks":1344,"valid_for_ticks":96})!="": return
		p.dispute={"status":"requested","created_tick":now,"offer":id,"force":"","warning_until":0,"ended_tick":null,"reason":"The Iron March lacks ore and contests the High Pass corridor; it requests a nonaggression settlement first."}
		R._note(s,"corridor_dispute","high_pass",p.dispute.reason)
		return
	var d: Dictionary=p.dispute
	if d.status=="settled": return
	if d.status=="war":
		if not hostile: finish(s,d,"The corridor war ended in a ceasefire. The opening dispute is settled; damaged outposts recover.")
		return
	if hostile: d.status="war";return
	if W.available(world.core,"iron_march","ore")>=int(world.rules.policies.iron_march.targets.ore) or R.C._pact_blocks(world,"iron_march","river_league"):
		finish(s,d,"Supply recovery or a protected agreement settled the corridor dispute before an offensive.");return
	if d.status=="requested":
		var offer: Dictionary=world.core.pact_offers.get(d.offer,{})
		if offer.get("status") in ["rejected","expired"]:
			d.status="warning";d.warning_until=now+96
			R.C._relation(world,"iron_march","river_league",-5,25)
			R._note(s,"corridor_dispute","high_pass","The border settlement was refused or expired. The Iron March warns of a corridor offensive; it still needs supplies and an actual border force.")
		elif offer.is_empty() or offer.get("status")=="accepted": finish(s,d,"The diplomatic offer is no longer contested; no offensive follows.")
		return
	if now<d.warning_until: return
	if now-int(d.created_tick)>672:
		finish(s,d,"The Iron March could not sustain preparations and abandoned this corridor offensive.");return
	if d.status=="warning":
		for id: String in R.C.S.sorted_ids(world.forces):
			if world.core.parties[id].faction_id!="iron_march": continue
			if R.C._operate(world,"iron_march","mobilize",{"party":id,"route":"pass_road"})=="":
				d.status="preparing";d.force=id
				R._note(s,"corridor_dispute","high_pass","The Iron March paid for a real border mobilization. A declaration still requires the force to reach its staging point.");break
	elif d.status=="preparing":
		if R.C._operate(world,"iron_march","declare_war",{"target":"river_league","route":"pass_road"})=="":
			d.status="war";R._note(s,"corridor_dispute","high_pass","Diplomacy failed and a funded border force is ready. The Iron March declared war over the contested corridor.")
static func valid(s: Dictionary, d: Variant) -> bool:
	if not d is Dictionary: return false
	if d.is_empty(): return true
	if not W._shape(d,["status","created_tick","offer","force","warning_until","ended_tick","reason"]) or d.status not in ["requested","warning","preparing","war","settled"] or not W._count(d.created_tick,0,int(s.strategy_world.core.tick)) or not W._id(d.offer) or not d.force is String or not W._count(d.warning_until) or not d.reason is String or d.reason.length()>256: return false
	if d.force!="" and not s.strategy_world.forces.has(d.force): return false
	return W._count(d.ended_tick,d.created_tick,int(s.strategy_world.core.tick)) if d.status=="settled" else d.ended_tick==null
