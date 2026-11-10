extends RefCounted
## Deterministic faction-only experiment. No player files, session or transport.
const R := preload("res://scripts/domain/strategic_region.gd")
const A := preload("res://scripts/domain/strategist_adapter.gd")
const Recorded := preload("res://scripts/domain/recorded_strategist.gd")
const C := R.C
const P := A.P

static func initial(world: Dictionary, mode: String) -> Dictionary:
	if not C.S.valid(world) or mode not in ["classic","recorded"]: return {}
	var adapter := A.initial(world)
	if mode=="recorded" and A.set_mode(adapter,world,mode)!="": return {}
	var dispatch_ticks := {}
	for id: String in world.trades:
		if world.trades[id].status in ["transit","waiting"]: dispatch_ticks[id]=int(world.trades[id].accepted_tick)
	return {"world":world.duplicate(true),"adapter":adapter,"stats":{"initial_digest":P.digest(world),"start_tick":int(world.core.tick),"last_event":int(world.event_seq),"steps":0,"food_shortfall_faction_days":0,"food_shortfall_units":0,"waiting_shipment_days":0,"delivery_ticks":[],"dispatch_ticks":dispatch_ticks,"actions":{},"rejections":{},"model_applied":0,"model_blocked":0}}

static func step(experiment: Dictionary, ticks: int=24) -> Dictionary:
	if ticks!=24: return {"ok":false,"reason":"Use a matched24tick boundary.","state":experiment}
	var next := experiment.duplicate(true)
	var adapter: Dictionary=next.adapter;var stats: Dictionary=next.stats
	var adapter_hook := A.hook(adapter)
	var hook := func(phase: String, payload: Dictionary) -> Dictionary:
		var result: Dictionary=adapter_hook.call(phase,payload)
		if phase=="outcomes":
			for outcome: Dictionary in payload.results:
				stats.actions[outcome.action]=int(stats.actions.get(outcome.action,0))+1
				if outcome.reason!="": stats.rejections[outcome.reason]=int(stats.rejections.get(outcome.reason,0))+1
				for record: Dictionary in adapter.journal:
					if record.tick==payload.tick and record.outcome=="accepted" and record.faction_id==outcome.actor:
						stats["model_applied" if outcome.reason=="" else "model_blocked"]+=1;break
		return result
	var tick_hook := func(world: Dictionary) -> void: _sample(stats,world)
	var advanced := C.apply(next.world,C.command(next.world,"world_clock","advance",{"ticks":ticks}),tick_hook,hook)
	if not advanced.ok: return {"ok":false,"reason":advanced.reason,"state":experiment}
	next.world=advanced.state
	for actor: String in C.S.sorted_ids(adapter.pending):
		var pending: Dictionary=adapter.pending[actor]
		if pending.status!="ready": continue
		var id: String=pending.request.request_id;var tick := int(next.world.core.tick)
		var reason := A.dispatch(adapter,id,tick)
		if reason!="": return {"ok":false,"reason":reason,"state":experiment}
		if pending.status=="sent":
			reason=A.receive(adapter,id,Recorded.reply(pending.request),tick)
			if reason!="": return {"ok":false,"reason":reason,"state":experiment}
	if not C.S.reconciles(next.world) or not A.valid(adapter,next.world): return {"ok":false,"reason":"Comparison candidate failed accounting/adapter validation.","state":experiment}
	stats.steps+=1
	return {"ok":true,"reason":"","state":next}

static func _sample(stats: Dictionary, world: Dictionary) -> void:
	if not world.events.is_empty() and world.events.back().sequence>stats.last_event:
		for event: Dictionary in world.events:
			if event.sequence<=stats.last_event: continue
			if event.kind=="trade_dispatched": stats.dispatch_ticks[event.target]=int(event.tick)
			if event.kind=="trade_delivered" and stats.dispatch_ticks.has(event.target):
				stats.delivery_ticks.append(int(event.tick)-int(stats.dispatch_ticks[event.target]))
			if event.kind in ["trade_delivered","convoy_lost"]: stats.dispatch_ticks.erase(event.target)
		stats.last_event=int(world.event_seq)
	if int(world.core.tick)%96!=0: return
	for shortfall: Dictionary in world.shortfalls.values():
		if shortfall.food>0: stats.food_shortfall_faction_days+=1;stats.food_shortfall_units+=int(shortfall.food)
	for trade: Dictionary in world.trades.values():
		if trade.status=="waiting": stats.waiting_shipment_days+=1

static func report(experiment: Dictionary) -> Dictionary:
	var world: Dictionary=experiment.world;var stats: Dictionary=experiment.stats
	var adapter: Dictionary=experiment.adapter;var route_ticks := {}
	for id: String in C.S.sorted_ids(world.core.routes): route_ticks[id]=int(world.core.routes[id].travel_ticks)
	var durations: Array=stats.delivery_ticks.duplicate();durations.sort()
	var cargo := C.S.stocks();var escrow := 0;var active := 0
	for trade: Dictionary in world.trades.values():
		cargo[trade.resource]+=int(trade.cargo);escrow+=int(trade.escrow)
		if trade.status in ["transit","waiting"]: active+=1
	var stocks := {}
	for id: String in C.S.sorted_ids(world.core.factions): stocks[id]=world.core.factions[id].stocks.duplicate(true)
	return {"seed":int(world.core.seed),"premise":world.premise,"mode":adapter.mode,"reply_source":"authored_offline" if adapter.mode=="recorded" else "none","initial_digest":stats.initial_digest,"final_digest":P.digest({"world":world,"adapter":adapter}),"days":(int(world.core.tick)-int(stats.start_tick))/96,"steps":stats.steps,"route_ticks":route_ticks,"metrics":world.metrics.duplicate(true),"ledger":world.ledger.duplicate(true),"ending_stocks":stocks,"unresolved":{"shipments":active,"cargo":cargo,"escrow_coin":escrow},"food_shortfall_faction_days":stats.food_shortfall_faction_days,"food_shortfall_units":stats.food_shortfall_units,"waiting_shipment_days":stats.waiting_shipment_days,"delivery_duration_ticks":{"count":durations.size(),"median":0 if durations.is_empty() else int(durations[durations.size()/2]),"max":0 if durations.is_empty() else int(durations.back())},"action_attempts":stats.actions.duplicate(true),"rejections":stats.rejections.duplicate(true),"strategist":{"totals":adapter.totals.duplicate(true),"applied_actions":stats.model_applied,"blocked_actions":stats.model_blocked,"cost_micros":int(adapter.budget.cost_micros)},"reconciled":C.S.reconciles(world)}

static func table(rows: Array) -> String:
	var output := "# Matched faction diagnostics\n\nAuthored offline examples; no live model. Factions only: company play and wall-time transport are excluded. All starting mines remain occupied.\n\n"
	output+="| Seed | Size | Mode | Days | Delivered | Lost | Wars / peace | Food shortage faction-days | Median delivery ticks | Rejected | Model applied / blocked |\n| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |\n"
	for row: Dictionary in rows:
		output+="| %d | %s | %s | %d | %d | %d | %d / %d | %d | %d | %d | %d / %d |\n" % [row.seed,row.size,row.mode,row.days,row.metrics.trade_delivered,row.metrics.trade_lost,row.metrics.wars,row.metrics.peace,row.food_shortfall_faction_days,row.delivery_duration_ticks.median,row.metrics.rejected_intents,row.strategist.applied_actions,row.strategist.blocked_actions]
	return output
