extends SceneTree
const M := preload("res://scripts/domain/strategist_campaign.gd")
const A := M.A
const P := A.P
const C := A.C
const Recorded := preload("res://scripts/domain/recorded_strategist.gd")
var checks := 0
var failures: Array[String]=[]
var tail: Array=[]
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label);print("FAIL: ",label)
func step(s: Dictionary, action: String, p: Dictionary={}) -> Dictionary:
	var cmd := M.command(s,action,p);var result := M.apply(s,cmd)
	check(result.ok,action+" / "+result.reason)
	if result.ok: tail.append(cmd)
	return result.state
func _initialize() -> void:
	protocol();integration();pruning();concurrent_spending();fixture_replay()
	for failure: String in failures: push_error(failure)
	print("strategist_adapter_tests: %d checks, %d failures" % [checks,failures.size()]);quit(0 if failures.is_empty() else 1)
func protocol() -> void:
	var world := C.initial(2087)
	for id: String in C.S.sorted_ids(world.core.factions):
		var q := P.request(world,id,1,1)
		check(P.request_valid(q),"bounded request "+id)
		check(P.encoded(q)==P.encoded(JSON.parse_string(P.encoded(q))),"request JSON normalization")
		var raw := Recorded.reply(q);var reply: Dictionary=JSON.parse_string(raw)
		check(P.reply_reason(q,reply)=="","authored example follows real protocol")
		check(not q.observation.has("company") and not q.observation.has("plans") and not q.observation.own.has("other_policies"),"individual observation privacy")
		for other: String in world.core.factions:
			if other!=id: check(not P.encoded(q).contains(P.encoded(world.rules.policies[other])),"no foreign private policy")
		for mutate: Callable in [
			func(v): v.schema=true,
			func(v): v.decision_id=true,
			func(v): v.version=true,
			func(v): v.generation+=1,
			func(v): v.observation_hash="0".repeat(64),
			func(v): v.goal_id="invented_goal",
			func(v): v.intent_ids=["unknown_candidate"],
			func(v): v.cited_events=["invented_victory"],
			func(v): v.supporting=["spawn_army"],
			func(v): v.reason_code="the_model_won",
			func(v): v.public_summary="x".repeat(181),
			func(v): v.execute="OS.execute",
			func(v): v.contingencies=[{"predicate":"invented_war","intent_id":"unknown"}],
			func(v): v.supporting=["trade","trade"],
		]:
			var bad := reply.duplicate(true);mutate.call(bad)
			check(P.reply_reason(q,bad)!="","untrusted reply rejects without effects")
		for mutate: Callable in [func(v): v.schema=true,func(v): v.request_id=true,func(v): v.observation_hash=true,func(v): v.version=true,func(v): v.observation.tick=true,func(v): v.requested_review_tick=true,func(v): v.observation.own.private_plans={},func(v): v.capabilities.predicates=true]:
			var bad := q.duplicate(true);mutate.call(bad)
			check(not P.request_valid(bad),"malformed saved request fails closed")
	check(not P.intent_valid({"action":"propose_peace","payload":{"id":true,"target":"river_league"}}),"boolean candidate identifier rejects without diagnostics")
func integration() -> void:
	var s := M.initial();check(M.valid(s),"fresh opt-in v4")
	var checkpoint := s.duplicate(true);tail=[]
	var ordinary := M.command(s,"advance",{"ticks":24})
	var classic := M.R.apply(M.regional(s),ordinary);var composed := M.apply(s,ordinary)
	check(classic.ok and composed.ok,"both native formats accept the same ordinary command")
	check(P.encoded(classic.state)==P.encoded(M.regional(composed.state)),"v4 classic mode preserves the exact v3 baseline")
	s=step(s,"model_mode",{"mode":"recorded"})
	s=step(s,"advance",{"ticks":192});check(s.strategist.pending.is_empty(),"do not override opening commitment")
	s=step(s,"advance",{"ticks":72})
	check(s.strategist.pending.size()==1,"staggered first request after opening commitment")
	if s.strategist.pending.is_empty(): return
	var id: String=s.strategist.pending.keys()[0];var q: Dictionary=s.strategist.pending[id].request
	check(q.observation_tick==264 and q.apply_by_tick==288,"fixed future execution boundary")
	s=step(s,"model_dispatch",{"request_id":q.request_id})
	check(s.strategist.budget.calls==1 and s.strategist.budget.tokens>512,"durable bounded reservation before transport")
	var raw := Recorded.reply(q)
	s=step(s,"model_reply",{"request_id":q.request_id,"raw":raw})
	check(s.strategy_world.core.tick==264 and s.strategist.totals.accepted==0,"reply queues without advancing/effects")
	var before := P.encoded(s)
	var duplicate := M.apply(s,M.command(s,"model_reply",{"request_id":q.request_id,"raw":raw}))
	check(not duplicate.ok and P.encoded(duplicate.state)==before,"duplicate queued reply is atomic rejection")
	s=step(s,"advance",{"ticks":24})
	check(s.strategist.totals.accepted==1 and not s.strategist.pending.has(id),"accepted at fixed boundary once")
	check(s.strategy_world.plans[id].selected_tick==288 and s.strategy_world.plans[id].reason==JSON.parse_string(raw).reason_code,"actual authoritative plan changed")
	var selected: Array=JSON.parse_string(raw).intent_ids
	check(s.strategist.journal[0].executions.size()==selected.size(),"accepted plan records exactly its selected immediate operator attempts")
	check(C.S.reconciles(s.strategy_world),"accepted model actions preserve economy conservation")
	check(M.valid(JSON.parse_string(P.encoded(s))),"v4 exact JSON continuation")
	var replay := M.replay(checkpoint,tail)
	check(replay.ok and P.encoded(replay.state)==P.encoded(s),"checkpoint plus recorded command tail replays without transport")
	var broken_tail := tail.duplicate(true);broken_tail.append(tail.back())
	check(not M.replay(checkpoint,broken_tail).ok,"replay rejects duplicated command")
	check(not M.apply(s,tail.back()).ok,"successful sequence rejects old command")
	# The next staggered request receives no response; time and classic policy continue.
	s=step(s,"advance",{"ticks":168});s=step(s,"advance",{"ticks":24})
	check(s.strategist.totals.fallback>=1 and s.strategist.journal.back().reason=="missing","missing reply falls back at deadline")
	check(C.S.reconciles(s.strategy_world),"offline fallback preserves real world accounting")
	# Opening a new mode generation cancels queued work, never resets watermarks.
	s=step(s,"model_mode",{"mode":"classic"});s=step(s,"model_mode",{"mode":"recorded"})
	check(s.strategist.generation==3 and s.strategist.pending.is_empty(),"generation switch cancels/coalesces")
	check(not M.apply(s,M.command(s,"model_reply",{"request_id":q.request_id,"raw":raw})).ok,"late old-generation callback rejected")
	# Different legacy versions never acquire an adapter implicitly.
	var legacy := M.R.initial();check(M.R.valid(legacy) and not M.valid(legacy),"v3 remains separate")
	for mutate: Callable in [func(v): v.version=true,func(v): v.strategist.generation=true,func(v): v.strategist.rules.provider="live_unknown"]:
		var bad := s.duplicate(true);mutate.call(bad);check(not M.valid(bad),"bad v4 version/config rejected")
func pruning() -> void:
	var world := C.initial(2087);var a := A.initial(world)
	A.set_mode(a,world,"recorded")
	var oldest := ""
	for week in range(20):
		world.core.tick=264+week*672
		A.review(a,A.observations(world))
		if oldest=="" and not a.pending.is_empty(): oldest=a.pending.values()[0].request.request_id
		world.core.tick+=24
		var result := A.review(a,A.observations(world))
		for id: String in result.plans: world.plans[id]=result.plans[id]
		check(A.valid(a,world),"bounded adapter archival state")
	check(a.journal.size()==64 and a.request_seq>64,"journal prunes only completed records")
	check(A.receive(a,oldest,"{}",int(world.core.tick))!="","archived request still cannot replay")
	check(a.completed.values().all(func(n): return n>0),"per-faction completion watermarks survive archival")
func concurrent_spending() -> void:
	# Two independently affordable offers compete for the same actual20coins.
	var world := C.initial(42);var actor := "cinder_compact"
	world.core.tick=264
	for resource: String in ["coin","ore","timber"]:
		var value := 20 if resource=="coin" else 0
		world.ledger.opening[resource]+=value-int(world.core.factions[actor].stocks[resource]);world.core.factions[actor].stocks[resource]=value
	world.rules.policies[actor].production.coin=0;world.rules.policies[actor].consumption.coin=0
	for pair: Array in [["river_league","ore"],["thornwood_accord","timber"]]:
		var seller: String=pair[0];var resource: String=pair[1]
		var missing := maxi(0,12-int(world.core.factions[seller].stocks[resource]));world.core.factions[seller].stocks[resource]+=missing;world.ledger.opening[resource]+=missing
		var why := C._operate(world,seller,"propose_trade",{"id":C.S.next_id(world,"trade"),"seller":seller,"buyer":actor,"resource":resource,"amount":12,"unit_price":1,"source":world.rules.policies[seller].home,"target":world.rules.policies[actor].home})
		check(why=="","ordinary funded incoming offer")
	check(C.S.valid(world),"competing-offer fixture conserves actual sources")
	var a := A.initial(world);A.set_mode(a,world,"recorded");a.next_review[actor]=264
	A.review(a,A.observations(world))
	var q: Dictionary=a.pending[actor].request
	var reply: Dictionary=JSON.parse_string(Recorded.reply(q));reply.intent_ids=[]
	for id: String in q.capabilities.intents:
		if q.capabilities.intents[id].action=="accept_trade": reply.intent_ids.append(id)
	check(reply.intent_ids.size()==2,"both offers independently observed as affordable")
	check(A.dispatch(a,q.request_id,264)=="" and A.receive(a,q.request_id,P.encoded(reply),264)=="","queue two lawful candidates")
	var result := C.apply(world,C.command(world,"world_clock","advance",{"ticks":24}),Callable(),A.hook(a))
	check(result.ok and C.S.reconciles(result.state),"shared operator revalidates simultaneous spending")
	var rejected := false
	for record: Dictionary in a.journal:
		if record.faction_id==actor:
			for outcome: Dictionary in record.executions:
				if outcome.reason=="trade_unfunded": rejected=true
	check(rejected,"second acceptance cannot spend same treasury twice")
func fixture_replay() -> void:
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/strategist_replays/mine_region_2087.json"))
	var checkpoint: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(manifest.checkpoint))
	check(M.valid(checkpoint),"exported checkpoint remains runtime-valid")
	var result := M.replay(checkpoint,manifest.commands)
	check(result.ok and P.digest(result.state)==manifest.expected_digest,"portable checkpoint/tail has exact expected outcome")
