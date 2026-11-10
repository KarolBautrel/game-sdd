extends RefCounted
## Stage93 pure foundation. No AI, clock advancement or geographic movement yet.
const FIXTURE := "res://resources/data/strategy_worlds/four_factions_foundation_v1.json"
const STOCKS := ["coin","food","ore","timber"]
const ACTIONS := ["reserve_budget","release_budget","propose_pact","accept_pact","reject_pact","withdraw_pact"]
const KINDS := ["nonaggression","defensive_pact"]
const ROOT_KEYS := ["schema","version","simulation_version","content_version","scenario_id","topology_kind","seed","tick","command_seq","planner_mode","factions","settlements","routes","parties","company_reputation","diplomacy","pact_offers","reservations","receipts"]
static var identifier := RegEx.create_from_string("^[a-z][a-z0-9_]{0,63}$")

static func _id(value: Variant) -> bool:
	return value is String and identifier.search(value) != null

static func _count(value: Variant, low: int = 0, high: int = 1000000000) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= low and value <= high and float(value) == floor(float(value))

static func _text(value: Variant) -> bool:
	return value is String and not value.is_empty() and value.length() <= 128

static func _shape(value: Variant, keys: Array) -> bool:
	if not value is Dictionary or value.size() != keys.size(): return false
	for key: String in keys:
		if not value.has(key): return false
	return true

static func _registry(value: Variant, low: int = 0, high: int = 1024) -> bool:
	if not value is Dictionary or value.size() < low or value.size() > high: return false
	for key: Variant in value:
		if not _id(key): return false
	return true

static func pair_key(a: String, b: String) -> String:
	return a+"~"+b if a < b else b+"~"+a

static func initial(seed_value: int = 2087) -> Dictionary:
	if not _count(seed_value,1): return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not valid(value): return {}
	value.seed = seed_value
	return value

static func available(state: Dictionary, faction_id: String, resource: String) -> int:
	if not state.get("factions",{}).has(faction_id) or resource not in STOCKS: return 0
	var total := int(state.factions[faction_id].stocks[resource])
	for hold: Dictionary in state.reservations.values():
		if hold.faction_id == faction_id and hold.resource == resource and hold.status == "reserved": total -= int(hold.amount)
	return total

static func valid(value: Variant) -> bool:
	if not _shape(value,ROOT_KEYS): return false
	var s: Dictionary = value
	if s.schema != "sdd.strategy-world" or not _count(s.version,1,1) or not _count(s.simulation_version,1,1) or not _count(s.content_version,1,1): return false
	if s.topology_kind != "abstract_fixture" or s.planner_mode != "classic" or not _id(s.scenario_id): return false
	if not _count(s.seed,1) or not _count(s.tick) or not _count(s.command_seq): return false
	if not _registry(s.factions,2,12) or not _registry(s.settlements,2,64) or not _registry(s.routes,1,256) or not _registry(s.parties,0,128): return false
	if not _registry(s.company_reputation,2,12) or not _registry(s.reservations) or not _registry(s.pact_offers): return false
	if s.company_reputation.size() != s.factions.size() or not s.diplomacy is Dictionary: return false
	for id: String in s.factions:
		var f: Variant = s.factions[id]
		if not _shape(f,["name","stocks","manpower"]) or not _text(f.name) or not _count(f.manpower): return false
		if not _shape(f.stocks,STOCKS) or not s.company_reputation.has(id) or not _count(s.company_reputation[id],-100,100): return false
		for amount: Variant in f.stocks.values():
			if not _count(amount): return false
	for id: String in s.settlements:
		var town: Variant = s.settlements[id]
		if not _shape(town,["name","owner_id","x","y"]) or not _text(town.name) or not _id(town.owner_id) or not s.factions.has(town.owner_id): return false
		for n: Variant in [town.x,town.y]:
			if not (n is int or n is float) or not is_finite(float(n)) or n < 0 or n > 1: return false
	var adjacent := {}
	for id: String in s.settlements: adjacent[id] = []
	var route_pairs := {}
	for edge: Variant in s.routes.values():
		if not _shape(edge,["a","b","travel_ticks"]) or not _id(edge.a) or not _id(edge.b) or edge.a == edge.b or not _count(edge.travel_ticks,1,1000000): return false
		if not s.settlements.has(edge.a) or not s.settlements.has(edge.b): return false
		var key := pair_key(edge.a,edge.b)
		if route_pairs.has(key): return false
		route_pairs[key] = true
		adjacent[edge.a].append(edge.b); adjacent[edge.b].append(edge.a)
	var queue: Array = [s.settlements.keys()[0]]
	var reached := {}
	while not queue.is_empty():
		var id: String = queue.pop_front()
		if reached.has(id): continue
		reached[id] = true
		queue.append_array(adjacent[id])
	if reached.size() != s.settlements.size(): return false
	var headcounts := {}
	for id: String in s.factions: headcounts[id] = 0
	for party: Variant in s.parties.values():
		if not _shape(party,["faction_id","kind","settlement_id","headcount"]) or not _id(party.faction_id) or not _id(party.settlement_id): return false
		if not s.factions.has(party.faction_id) or not s.settlements.has(party.settlement_id) or party.kind not in ["patrol","caravan"] or not _count(party.headcount): return false
		headcounts[party.faction_id] += int(party.headcount)
	for id: String in headcounts:
		if headcounts[id] > s.factions[id].manpower: return false
	var treaty_index := {}
	var ids: Array = s.factions.keys(); ids.sort()
	if s.diplomacy.size() != ids.size()*(ids.size()-1)/2: return false
	for i in range(ids.size()):
		for j in range(i+1,ids.size()):
			var key := pair_key(ids[i],ids[j])
			var pair: Variant = s.diplomacy.get(key)
			if not _shape(pair,["a","b","stance","treaties"]) or pair.a != ids[i] or pair.b != ids[j] or pair.stance not in ["peace","war"]: return false
			if not pair.treaties is Array or pair.treaties.size() > 1024: return false
			var active_kinds := {}
			for treaty: Variant in pair.treaties:
				if not _shape(treaty,["id","kind","start_tick","end_tick"]) or not _id(treaty.id) or treaty.kind not in KINDS: return false
				if not _count(treaty.start_tick) or treaty.start_tick > s.tick or not _count(treaty.end_tick) or treaty.end_tick <= treaty.start_tick or treaty_index.has(treaty.id): return false
				if treaty.end_tick > s.tick:
					if pair.stance == "war" or active_kinds.has(treaty.kind): return false
					active_kinds[treaty.kind] = true
				treaty_index[treaty.id] = {"pair":key,"treaty":treaty}
	var pending_terms := {}
	for id: String in s.pact_offers:
		var offer: Variant = s.pact_offers[id]
		if not _shape(offer,["id","proposer","recipient","kind","status","signed_by","duration_ticks","created_tick","expires_tick","accepted_tick"]): return false
		if offer.id != id or not _id(offer.proposer) or not _id(offer.recipient) or offer.proposer == offer.recipient or not s.factions.has(offer.proposer) or not s.factions.has(offer.recipient): return false
		if offer.kind not in KINDS or offer.status not in ["pending","accepted","rejected","withdrawn"] or not offer.signed_by is Array: return false
		if not _count(offer.duration_ticks,96,2880) or not _count(offer.created_tick) or offer.created_tick > s.tick or not _count(offer.expires_tick): return false
		if offer.expires_tick-offer.created_tick < 1 or offer.expires_tick-offer.created_tick > 672: return false
		if offer.status == "accepted":
			var endpoints: Array = [offer.proposer,offer.recipient]; endpoints.sort()
			if offer.signed_by != endpoints or not _count(offer.accepted_tick) or offer.accepted_tick < offer.created_tick or offer.accepted_tick >= offer.expires_tick or offer.accepted_tick > s.tick: return false
			if not treaty_index.has(id): return false
			var entry: Dictionary = treaty_index[id]
			if entry.pair != pair_key(offer.proposer,offer.recipient) or entry.treaty.kind != offer.kind or entry.treaty.start_tick != offer.accepted_tick or entry.treaty.end_tick != offer.accepted_tick+offer.duration_ticks: return false
		else:
			if offer.signed_by != [offer.proposer] or offer.accepted_tick != null or treaty_index.has(id): return false
			if offer.status == "pending" and offer.expires_tick > s.tick:
				var key := pair_key(offer.proposer,offer.recipient)
				var terms: String = key+"~"+offer.kind
				if s.diplomacy[key].stance == "war" or _active_kind(s,s.diplomacy[key],offer.kind) or pending_terms.has(terms): return false
				pending_terms[terms] = true
	for id: String in treaty_index:
		if not s.pact_offers.has(id): return false
	for id: String in s.reservations:
		var hold: Variant = s.reservations[id]
		if not _shape(hold,["id","faction_id","resource","amount","purpose","status","created_seq","closed_seq"]) or hold.id != id or not _id(hold.faction_id): return false
		if not s.factions.has(hold.faction_id) or hold.resource not in STOCKS or not _count(hold.amount,1) or not _text(hold.purpose) or hold.status not in ["reserved","released"]: return false
		if not _count(hold.created_seq,1) or hold.created_seq > s.command_seq: return false
		if hold.status == "reserved":
			if hold.closed_seq != null: return false
		elif not _count(hold.closed_seq,int(hold.created_seq)) or hold.closed_seq > s.command_seq: return false
	for id: String in s.factions:
		for resource: String in STOCKS:
			if available(s,id,resource) < 0: return false
	if not s.receipts is Array or s.receipts.size() != mini(int(s.command_seq),64): return false
	var expected: int = int(s.command_seq)-s.receipts.size()+1
	for receipt: Variant in s.receipts:
		if not _shape(receipt,["id","sequence","actor_id","action","target_id","tick"]): return false
		if not _count(receipt.sequence,1) or receipt.sequence != expected or receipt.id != "order_%08d" % expected or not _id(receipt.actor_id) or not s.factions.has(receipt.actor_id) or receipt.action not in ACTIONS or not _count(receipt.tick) or receipt.tick > s.tick: return false
		if not _id(receipt.target_id) or not (s.reservations if receipt.action in ["reserve_budget","release_budget"] else s.pact_offers).has(receipt.target_id): return false
		expected += 1
	return true

static func command(state: Dictionary, actor: String, action: String, payload: Dictionary) -> Dictionary:
	var seq := int(state.command_seq)+1
	return {"id":"order_%08d" % seq,"sequence":seq,"actor_id":actor,"action":action,"payload":payload.duplicate(true)}

static func apply(state: Dictionary, cmd: Dictionary) -> Dictionary:
	if not valid(state): return _rejected(state,"invalid_state")
	if not _shape(cmd,["id","sequence","actor_id","action","payload"]) or not cmd.payload is Dictionary or not _count(cmd.sequence,1): return _rejected(state,"invalid_command")
	if cmd.sequence <= state.command_seq: return _rejected(state,"command_replayed")
	if cmd.sequence != state.command_seq+1 or cmd.id != "order_%08d" % int(cmd.sequence): return _rejected(state,"sequence_mismatch")
	if not _id(cmd.actor_id) or not state.factions.has(cmd.actor_id): return _rejected(state,"unknown_actor")
	if cmd.action not in ACTIONS: return _rejected(state,"unsupported_action")
	var next := state.duplicate(true)
	var reason := _execute(next,cmd)
	if not reason.is_empty(): return _rejected(state,reason)
	next.command_seq = int(cmd.sequence)
	next.receipts.append({"id":cmd.id,"sequence":int(cmd.sequence),"actor_id":cmd.actor_id,"action":cmd.action,"target_id":cmd.payload.id,"tick":int(next.tick)})
	while next.receipts.size() > 64: next.receipts.pop_front()
	if not valid(next): return _rejected(state,"invalid_transition")
	return {"ok":true,"reason":"","state":next}

static func _rejected(state: Dictionary, reason: String) -> Dictionary:
	return {"ok":false,"reason":reason,"state":state.duplicate(true)}

static func _execute(s: Dictionary, cmd: Dictionary) -> String:
	var p: Dictionary = cmd.payload
	if cmd.action == "reserve_budget":
		if not _shape(p,["id","resource","amount","purpose"]) or not _id(p.id) or p.resource not in STOCKS or not _count(p.amount,1) or not _text(p.purpose): return "invalid_payload"
		if s.reservations.has(p.id): return "reservation_exists"
		if available(s,cmd.actor_id,p.resource) < p.amount: return "insufficient_available_stock"
		s.reservations[p.id] = {"id":p.id,"faction_id":cmd.actor_id,"resource":p.resource,"amount":int(p.amount),"purpose":p.purpose,"status":"reserved","created_seq":int(cmd.sequence),"closed_seq":null}
		return ""
	if not _shape(p,["id"]) and cmd.action != "propose_pact": return "invalid_payload"
	if not p.has("id") or not _id(p.id): return "invalid_payload"
	if cmd.action == "release_budget":
		var hold: Dictionary = s.reservations.get(p.id,{})
		if hold.is_empty() or hold.faction_id != cmd.actor_id: return "reservation_not_owned"
		if hold.status != "reserved": return "reservation_closed"
		hold.status = "released"; hold.closed_seq = int(cmd.sequence)
		return ""
	if cmd.action == "propose_pact":
		if not _shape(p,["id","target","kind","duration_ticks","valid_for_ticks"]) or not _id(p.target) or not s.factions.has(p.target) or p.target == cmd.actor_id or p.kind not in KINDS: return "invalid_payload"
		if not _count(p.duration_ticks,96,2880) or not _count(p.valid_for_ticks,1,672): return "invalid_payload"
		if s.pact_offers.has(p.id): return "offer_exists"
		var pair: Dictionary = s.diplomacy[pair_key(cmd.actor_id,p.target)]
		if pair.stance != "peace": return "pair_at_war"
		if _active_kind(s,pair,p.kind): return "pact_exists"
		for offer: Dictionary in s.pact_offers.values():
			if offer.status == "pending" and offer.expires_tick > s.tick and offer.kind == p.kind and pair_key(offer.proposer,offer.recipient) == pair_key(cmd.actor_id,p.target): return "offer_pending"
		s.pact_offers[p.id] = {"id":p.id,"proposer":cmd.actor_id,"recipient":p.target,"kind":p.kind,"status":"pending","signed_by":[cmd.actor_id],"duration_ticks":int(p.duration_ticks),"created_tick":int(s.tick),"expires_tick":int(s.tick)+int(p.valid_for_ticks),"accepted_tick":null}
		return ""
	var offer: Dictionary = s.pact_offers.get(p.id,{})
	if offer.is_empty() or offer.status != "pending": return "offer_not_pending"
	if int(s.tick) >= int(offer.expires_tick): return "offer_expired"
	if cmd.action == "withdraw_pact":
		if cmd.actor_id != offer.proposer: return "not_proposer"
		offer.status = "withdrawn"
	else:
		if cmd.actor_id != offer.recipient: return "not_recipient"
		if cmd.action == "reject_pact": offer.status = "rejected"
		else:
			var key := pair_key(offer.proposer,offer.recipient)
			var pair: Dictionary = s.diplomacy[key]
			if pair.stance != "peace" or _active_kind(s,pair,offer.kind): return "pact_conflict"
			offer.status = "accepted"; offer.signed_by = [pair.a,pair.b]; offer.accepted_tick = int(s.tick)
			pair.treaties.append({"id":offer.id,"kind":offer.kind,"start_tick":int(s.tick),"end_tick":int(s.tick)+int(offer.duration_ticks)})
	return ""

static func _active_kind(state: Dictionary, pair: Dictionary, kind: String) -> bool:
	for treaty: Dictionary in pair.treaties:
		if treaty.kind == kind and treaty.end_tick > state.tick: return true
	return false
