extends RefCounted
## Pure observation -> scored plan / bounded intents. No privileged state access.
const S := preload("res://scripts/domain/classic_world_state.gd")
const Supply := preload("res://scripts/domain/supply_planning.gd")

static func _candidate(goal: String, target: String, resource: String, reason: String, economic: int, security: int, claim: int, readiness: int, cost: int, switching: int) -> Dictionary:
	return {"goal":goal,"target":target,"resource":resource,"reason":reason,"scores":{"economic":economic,"security":security,"claim":claim,"readiness":readiness,"cost":cost,"switching":switching}}

static func choose(o: Dictionary) -> Dictionary:
	var personality: Dictionary=o.own.policy.personality
	var candidates: Array=[_candidate("hold","","","rebuild_reserves",0,int(personality.security)/5,0,0,0,0)]
	candidates.append(_candidate("commerce","","","profitable_exports",int(personality.trade)/2,0,0,0,0,0))
	var worst := "";var deficit := 0
	for resource: String in ["food","ore","timber"]:
		var missing := int(o.own.policy.targets[resource])-int(o.own.available[resource])
		if missing>deficit: deficit=missing;worst=resource
	if worst!="": candidates.append(_candidate("supplies","",worst,"reserve_deficit",40+deficit*2,10 if worst=="food" else 0,0,0,-5,0))
	for r: Dictionary in o.relations:
		if r.stance=="war":
			var pressure: bool=r.exhaustion>=24 or r.war_age>=672 or o.own.shortfalls.food>0
			candidates.append(_candidate("peace" if pressure else "defend",r.target,"","war_costs" if pressure else "actual_war",80 if pressure else 0,100+int(r.exhaustion),0,0,-10,0))
		if not o.claim.is_empty() and r.target==o.claim.target and r.stance=="peace" and r.truce_until<=o.tick and r.pacts.is_empty() and (r.grievance>=25 or (r.trust<0 and personality.aggression>=60)):
			var troops := 0
			for force: Dictionary in o.forces: troops+=int(force.headcount)
			var potential := maxi(troops,mini(12,int(o.own.manpower)))
			if potential*2>=r.strength:
				candidates.append(_candidate("claim",r.target,"ore","contested_supply_claim",deficit,0,int(personality.aggression)+int(r.grievance),troops,-20,0))
	for c: Dictionary in candidates:
		if not o.previous.is_empty() and (c.goal!=o.previous.goal or c.target!=o.previous.target): c.scores.switching=-12
		c["total"]=0
		for value: int in c.scores.values(): c.total+=value
		c["tie"]=S.roll(int(o.seed),int(o.tick),o.actor+c.goal+c.target+c.resource,100000)
	candidates.sort_custom(func(a,b): return a.total>b.total if a.total!=b.total else a.tie>b.tie)
	var selected: Dictionary=candidates[0].duplicate(true);selected.erase("total");selected.erase("tie")
	selected.merge({"selected_tick":int(o.tick),"commit_until":int(o.tick)+288,"review_tick":int(o.tick)+672,"horizon_tick":int(o.tick)+1344,"supporting":["trade","guard"] if selected.goal!="hold" else ["rebuild"]})
	return selected

static func _relation(o: Dictionary, target: String) -> Dictionary:
	for r: Dictionary in o.relations:
		if r.target==target: return r
	return {}

static func _preparation_funded(force: Dictionary) -> bool:
	var quote: Dictionary=force.get("mobilization",{})
	return quote.get("staffed",false) and quote.get("funded",false)

static func _pact_pending(o: Dictionary, r: Dictionary, kind: String) -> bool:
	return kind in r.get("pending_pacts",[]) or o.incoming_pacts.any(func(p): return p.proposer==r.target and p.kind==kind and p.expires_tick>o.tick)

static func _peace_pending(o: Dictionary, r: Dictionary) -> bool:
	return r.get("peace_pending",false) or o.incoming_peace.any(func(p): return p.proposer==r.target and p.expires_tick>o.tick)

static func trade_response(o: Dictionary, offer: Dictionary, coins: int, planned: Dictionary={}, sold: Dictionary={}, slots: int=32) -> Dictionary:
	if slots<=0 or int(offer.get("supply",{}).get("free_slots",S.SHIPMENT_LIMIT))<=0: return {}
	var other: String=offer.buyer if offer.seller==o.actor else offer.seller
	var r := _relation(o,other)
	var accept: bool=r.stance=="peace" and r.trust>=-30 and offer.expires_tick>o.tick
	if offer.buyer==o.actor:
		accept=accept and offer.unit_price<=o.own.prices[offer.resource] and coins>=offer.amount*offer.unit_price and Supply.need(o,offer,planned)>0
	else:
		accept=accept and offer.unit_price>=o.own.prices[offer.resource] and int(o.own.available[offer.resource])-int(sold.get(offer.resource,0))-int(offer.amount)>=int(o.own.policy.targets[offer.resource])/2
	return {"action":"accept_trade" if accept else "reject_trade","payload":{"id":offer.id}}

static func intents(o: Dictionary, plan: Dictionary) -> Array:
	var result: Array=[]
	var coins := Supply.coins(o);var planned := {};var sold := {};var slots := Supply.slots(o)
	for offer: Dictionary in o.incoming_peace:
		var r := _relation(o,offer.proposer)
		var accept: bool=r.stance=="war" and (r.exhaustion>=16 or r.war_age>=672 or o.own.shortfalls.food>0)
		result.append({"action":"accept_peace" if accept else "reject_peace","payload":{"id":offer.id}})
	for offer: Dictionary in o.incoming_trades:
		var response := trade_response(o,offer,coins,planned,sold,slots)
		if response.is_empty(): continue
		result.append(response)
		if response.action=="accept_trade":
			slots-=1
			if offer.buyer==o.actor:
				coins-=int(offer.amount)*int(offer.unit_price);planned[offer.resource]=int(planned.get(offer.resource,0))+int(offer.amount)
			else: sold[offer.resource]=int(sold.get(offer.resource,0))+int(offer.amount)
	for offer: Dictionary in o.incoming_pacts:
		var r := _relation(o,offer.proposer)
		var accept: bool=r.trust>=15 and r.stance=="peace"
		result.append({"action":"accept_pact" if accept else "reject_pact","payload":{"id":offer.id}})
	for request: Dictionary in o.aid:
		var r := _relation(o,request.aggressor)
		var ready: bool=o.own.available.coin>=5 and o.own.available.food>=4 and r.pacts.is_empty() and r.truce_until<=o.tick
		ready=ready and o.forces.any(func(f): return f.headcount>=6 and f.edge_to=="" and f.ready_tick<=o.tick and f.mode!="preparing")
		result.append({"action":"respond_aid","payload":{"id":request.id,"accept":ready}})
	var force: Dictionary={}
	for f: Dictionary in o.forces:
		if f.mode not in ["preparing","marching"] and f.ready_tick<=o.tick and (f.headcount>0 or o.own.manpower>=6): force=f;break
	for r: Dictionary in o.relations:
		if r.stance!="war": continue
		if r.exhaustion>=24 or r.war_age>=672 or o.own.shortfalls.food>0:
			if not _peace_pending(o,r): result.append({"action":"propose_peace","payload":{"id":"pending","target":r.target}})
			return result.slice(0,3)
		elif not force.is_empty() and r.route!="" and _preparation_funded(force) and not (force.mode=="holding" and force.mission=="attack"):
			result.append({"action":"mobilize","payload":{"party":force.id,"route":r.route}})
			return result.slice(0,3)
	if plan.goal=="claim" and not o.claim.is_empty() and not force.is_empty():
		var r := _relation(o,o.claim.target)
		if r.stance=="peace" and r.truce_until<=o.tick and r.pacts.is_empty():
			if force.at==o.claim.staging and force.mode=="holding" and force.mission=="border":
				result.append({"action":"declare_war","payload":{"target":o.claim.target,"route":o.claim.route}})
				return result.slice(0,3)
			elif _preparation_funded(force):
				result.append({"action":"mobilize","payload":{"party":force.id,"route":o.claim.route}})
				return result.slice(0,3)
	# Local logistics uses actual deficits even while a strategic goal stays committed.
	var needs: Array=[]
	if Supply.offers(o)<2 and slots>0:
		for resource: String in ["food","ore","timber"]:
			var options: Array=[]
			for market: Dictionary in o.markets:
				if market.resource!=resource or _relation(o,market.seller).trust< -30 or Supply.pending_pair(o,market): continue
				var missing := Supply.need(o,market,planned)
				var amount := mini(int(market.amount),mini(missing,coins/int(market.unit_price)))
				if amount>0: options.append({"market":market,"amount":amount,"missing":missing,"lead":int(market.get("supply",{}).get("lead_ticks",0))})
			if options.is_empty(): continue
			options.sort_custom(func(a,b): return a.lead<b.lead if a.lead!=b.lead else a.market.seller<b.market.seller)
			var first: int=options[0].lead
			options=options.filter(func(x): return x.lead==first)
			var chosen: Dictionary=options[S.roll(int(o.seed),int(o.tick),o.actor+resource,options.size())]
			needs.append(chosen)
	needs.sort_custom(func(a,b): return a.missing>b.missing if a.missing!=b.missing else a.market.resource<b.market.resource)
	if not needs.is_empty():
		var chosen: Dictionary=needs[0];var m: Dictionary=chosen.market
		result.append({"action":"propose_trade","payload":{"id":"pending","seller":m.seller,"buyer":o.actor,"resource":m.resource,"amount":chosen.amount,"unit_price":m.unit_price,"source":m.source,"target":o.own.policy.home}})
		return result.slice(0,3)
	for r: Dictionary in o.relations:
		if r.stance=="peace" and r.deliveries>=3 and r.trust>=20 and r.pacts.is_empty() and not _pact_pending(o,r,"nonaggression"):
			result.append({"action":"propose_pact","payload":{"id":"pending","target":r.target,"kind":"nonaggression","duration_ticks":1344,"valid_for_ticks":96}})
			return result.slice(0,3)
		if r.stance=="peace" and r.deliveries>=8 and r.trust>=30 and "nonaggression" in r.pacts and "defensive_pact" not in r.pacts and not _pact_pending(o,r,"defensive_pact") and o.own.policy.personality.security>=60:
			result.append({"action":"propose_pact","payload":{"id":"pending","target":r.target,"kind":"defensive_pact","duration_ticks":1344,"valid_for_ticks":96}})
			return result.slice(0,3)
	if plan.goal=="commerce" and not force.is_empty() and force.mode=="idle" and o.own_trade_route!="" and _preparation_funded(force):
		result.append({"action":"protect_route","payload":{"party":force.id,"route":o.own_trade_route}})
	return result.slice(0,3)
