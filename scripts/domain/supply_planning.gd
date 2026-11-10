extends RefCounted
## Own-stock forecasts only. Actual goods, coin and consent stay with operators.
const S := preload("res://scripts/domain/classic_world_state.gd")
const W := S.W

static func inbound(world: Dictionary, actor: String) -> Dictionary:
	var result := S.stocks()
	for trade: Dictionary in world.trades.values():
		if trade.buyer!=actor or trade.status not in ["transit","waiting"] or S.hostile(world,trade.seller,trade.buyer): continue
		var start: String=trade.edge_to if trade.edge_to!="" else trade.at
		if S.path(world,start,trade.target,[trade.seller,trade.buyer]).is_empty(): continue
		result[trade.resource]+=int(trade.cargo)
	return result

static func free_slots(world: Dictionary) -> int:
	return S.SHIPMENT_LIMIT-world.trades.values().filter(func(t): return t.status in ["transit","waiting"]).size()

static func quote(world: Dictionary, actor: String, resource: String, path: Array, incoming: Dictionary, slots: int) -> Dictionary:
	var ticks := 0;var troops := 0
	for i in range(1,path.size()): ticks+=S.edge_ticks(world,path[i-1],path[i])
	for party: Dictionary in world.core.parties.values():
		if party.faction_id==actor: troops+=int(party.headcount)
	var policy: Dictionary=world.rules.policies[actor]
	var demand := maxi(0,int(policy.consumption[resource])+(ceili(troops/8.0) if resource=="food" else 0)-int(policy.production[resource]))
	var target := mini(int(world.rules.warehouse_cap),int(policy.targets[resource])+ceili(demand*(ticks+24)/96.0))
	return {"lead_ticks":ticks,"net_daily_need":demand,"reorder_target":target,"inbound":int(incoming[resource]),"free_slots":slots}

static func pending(o: Dictionary, resource: String="") -> int:
	var amount := 0
	for offer: Dictionary in o.pending_trades:
		if offer.buyer!=o.actor or offer.expires_tick<=o.tick: continue
		if resource=="": amount+=int(offer.amount)*int(offer.unit_price)
		elif offer.resource==resource: amount+=int(offer.amount)
	return amount

static func coins(o: Dictionary) -> int: return maxi(0,int(o.own.available.coin)-pending(o))

static func offers(o: Dictionary) -> int:
	return o.pending_trades.filter(func(t): return t.expires_tick>o.tick).size()

static func slots(o: Dictionary) -> int:
	var count := S.SHIPMENT_LIMIT
	for entries: Array in [o.markets,o.incoming_trades]:
		for entry: Dictionary in entries: count=mini(count,int(entry.get("supply",{}).get("free_slots",S.SHIPMENT_LIMIT)))
	return count

static func need(o: Dictionary, entry: Dictionary, planned: Dictionary={}) -> int:
	var resource: String=entry.resource;var q: Dictionary=entry.get("supply",{})
	if q.is_empty() and (resource in o.live_trade_resources or pending(o,resource)>0): return 0
	var target := int(q.get("reorder_target",o.own.policy.targets[resource]))
	return maxi(0,target-int(o.own.available[resource])-int(q.get("inbound",0))-pending(o,resource)-int(planned.get(resource,0)))

static func pending_pair(o: Dictionary, market: Dictionary) -> bool:
	return o.pending_trades.any(func(t): return t.expires_tick>o.tick and t.buyer==o.actor and t.seller==market.seller and t.resource==market.resource)
