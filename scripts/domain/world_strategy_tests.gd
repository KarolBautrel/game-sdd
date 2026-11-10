extends SceneTree
const World := preload("res://scripts/domain/world_strategy.gd")
const Company := preload("res://scripts/session/campaign_session.gd")
var failures: Array[String] = []
var checks := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ",label)

func submit(state: Dictionary, actor: String, action: String, payload: Dictionary) -> Dictionary:
	var before := state.duplicate(true)
	var result := World.apply(state,World.command(state,actor,action,payload))
	check(result.ok and World.valid(result.state), "valid transaction "+action+": "+result.reason)
	check(Company.same_data(state,before), "accepted transaction preserves input")
	return result.state

func reject(state: Dictionary, actor: String, action: String, payload: Dictionary, reason: String) -> void:
	var before := state.duplicate(true)
	var result := World.apply(state,World.command(state,actor,action,payload))
	check(not result.ok and result.reason == reason, "exact rejection "+reason)
	check(Company.same_data(state,before) and Company.same_data(result.state,before), "rejection is atomic "+reason)

func offer_payload(id: String = "trade_peace") -> Dictionary:
	return {"id":id,"target":"iron_march","kind":"nonaggression","duration_ticks":672,"valid_for_ticks":96}

func _initialize() -> void:
	var s := World.initial()
	check(World.valid(s) and s.factions.size() == 4 and s.settlements.size() == 6 and s.diplomacy.size() == 6, "four factions, six towns and six canonical pairs")
	check(World.pair_key("river_league","iron_march") == World.pair_key("iron_march","river_league"), "pair identity is unordered")
	check(World.initial(0).is_empty() and World.initial(1000000001).is_empty(), "invalid seeds do not initialize")
	var holdings: Dictionary = s.factions.duplicate(true)
	s = submit(s,"river_league","reserve_budget",{"id":"ore_plan","resource":"coin","amount":80,"purpose":"reopen trade"})
	check(World.available(s,"river_league","coin") == 40 and Company.same_data(s.factions,holdings), "hold reduces available stock, never holdings")
	reject(s,"river_league","reserve_budget",{"id":"second_plan","resource":"coin","amount":41,"purpose":"other goal"},"insufficient_available_stock")
	reject(s,"iron_march","release_budget",{"id":"ore_plan"},"reservation_not_owned")
	reject(s,"river_league","reserve_budget",{"id":"negative","resource":"coin","amount":-1,"purpose":"invalid"},"invalid_payload")
	reject(s,"river_league","reserve_budget",{"id":"fraction","resource":"coin","amount":1.5,"purpose":"invalid"},"invalid_payload")
	reject(s,"river_league","reserve_budget",{"id":"boolean","resource":"coin","amount":true,"purpose":"invalid"},"invalid_payload")
	s = submit(s,"river_league","release_budget",{"id":"ore_plan"})
	check(World.available(s,"river_league","coin") == 120, "release restores availability")
	reject(s,"river_league","release_budget",{"id":"ore_plan"},"reservation_closed")
	reject(s,"river_league","reserve_budget",{"id":"ore_plan","resource":"coin","amount":1,"purpose":"reuse"},"reservation_exists")
	s = submit(s,"river_league","propose_pact",offer_payload())
	var key := World.pair_key("river_league","iron_march")
	check(s.diplomacy[key].treaties.is_empty() and s.pact_offers.trade_peace.signed_by == ["river_league"], "proposal is not a bilateral agreement")
	reject(s,"river_league","accept_pact",{"id":"trade_peace"},"not_recipient")
	reject(s,"cinder_compact","accept_pact",{"id":"trade_peace"},"not_recipient")
	reject(s,"river_league","propose_pact",offer_payload("duplicate"),"offer_pending")
	s = submit(s,"iron_march","accept_pact",{"id":"trade_peace"})
	check(s.diplomacy[key].treaties.size() == 1 and s.pact_offers.trade_peace.signed_by == ["iron_march","river_league"], "both parties consent to a single canonical treaty")
	check(s.diplomacy[key].treaties[0].end_tick == 672 and s.company_reputation.river_league == 0, "frozen terms and independent company reputation")
	reject(s,"iron_march","accept_pact",{"id":"trade_peace"},"offer_not_pending")
	reject(s,"river_league","propose_pact",offer_payload("already_active"),"pact_exists")
	var alternate := offer_payload("defence_offer"); alternate.kind = "defensive_pact"
	s = submit(s,"river_league","propose_pact",alternate)
	s = submit(s,"iron_march","reject_pact",{"id":"defence_offer"})
	check(s.pact_offers.defence_offer.status == "rejected" and s.diplomacy[key].treaties.size() == 1, "decline grants no treaty")
	alternate.id = "withdraw_offer"
	s = submit(s,"river_league","propose_pact",alternate)
	reject(s,"iron_march","withdraw_pact",{"id":"withdraw_offer"},"not_proposer")
	s = submit(s,"river_league","withdraw_pact",{"id":"withdraw_offer"})
	check(s.pact_offers.withdraw_offer.status == "withdrawn", "proposer can withdraw pending terms")
	alternate.id = "expire_offer"
	s = submit(s,"river_league","propose_pact",alternate)
	var expired := s.duplicate(true); expired.tick = 96
	reject(expired,"iron_march","accept_pact",{"id":"expire_offer"},"offer_expired")
	reject(s,"river_league","declare_war",{},"unsupported_action")
	reject(s,"river_league","reserve_budget",{"id":"extra","resource":"coin","amount":1,"purpose":"bad","extra":1},"invalid_payload")
	var bad_command := World.command(s,"river_league","release_budget",{"id":"ore_plan"})
	bad_command.sequence += 1
	check(not World.apply(s,bad_command).ok, "out-of-order command rejected")
	var reordered := s.duplicate(true)
	for registry: String in ["factions","settlements","parties","routes","diplomacy","company_reputation","pact_offers","reservations"]:
		var entries: Dictionary = reordered[registry].duplicate(true)
		var ids: Array = entries.keys(); ids.reverse(); reordered[registry].clear()
		for id: String in ids: reordered[registry][id] = entries[id]
	check(World.valid(reordered), "reordered registries remain valid")
	var cmd := World.command(s,"thornwood_accord","reserve_budget",{"id":"forest_plan","resource":"timber","amount":15,"purpose":"repair corridor"})
	check(Company.same_data(World.apply(s,cmd).state,World.apply(reordered,cmd).state), "registry iteration order does not change results")
	for mutate: Callable in [
		func(v): v.version=2,
		func(v): v.version=true,
		func(v): v.seed=NAN,
		func(v): v.planner_mode="ai_strategy",
		func(v): v.unrecognized=1,
		func(v): v.factions.river_league.stocks.coin=-1,
		func(v): v.parties.league_patrol.headcount=46,
		func(v): v.parties.league_patrol.faction_id="missing",
		func(v): v.settlements.saltwatch.owner_id="missing",
		func(v): v.routes.river_road.b="missing",
		func(v): v.routes.eastern_road.a=v.routes.eastern_road.b,
		func(v): v.diplomacy.erase(key),
		func(v): v.diplomacy[key].stance="war",
		func(v): v.pact_offers.trade_peace.signed_by=["river_league"],
		func(v): v.pact_offers.trade_peace.duration_ticks=96,
		func(v): v.reservations.ore_plan.status="reserved";v.reservations.ore_plan.amount=121;v.reservations.ore_plan.closed_seq=null,
		func(v): v.receipts[0].sequence=999,
	]:
		var broken := s.duplicate(true); mutate.call(broken)
		check(not World.valid(broken), "corrupt version/reference/obligation rejected")
	var disconnected := World.initial()
	disconnected.routes.erase("river_road"); disconnected.routes.erase("market_road")
	check(not World.valid(disconnected), "disconnected settlement rejected")
	var duplicate_pending := s.duplicate(true)
	duplicate_pending.pact_offers["forged"] = duplicate_pending.pact_offers.expire_offer.duplicate(true)
	duplicate_pending.pact_offers.forged.id = "forged"
	check(not World.valid(duplicate_pending), "duplicate pending terms fail on load too")
	# Extra registry entries need no new actor slots, hardcoded counts or switches.
	var expanded := World.initial()
	expanded.factions["frost_court"] = expanded.factions.cinder_compact.duplicate(true)
	expanded.company_reputation["frost_court"] = 0
	expanded.settlements["frostgate"] = {"name":"Frostgate","owner_id":"frost_court","x":0.9,"y":0.1}
	expanded.routes["frost_road"] = {"a":"frostgate","b":"ironhold","travel_ticks":12}
	for faction: String in expanded.factions:
		if faction == "frost_court": continue
		var endpoints: Array = [faction,"frost_court"]; endpoints.sort()
		expanded.diplomacy[World.pair_key(faction,"frost_court")] = {"a":endpoints[0],"b":endpoints[1],"stance":"peace","treaties":[]}
	check(World.valid(expanded) and expanded.diplomacy.size() == 10,"registry supports a fifth faction and seventh settlement")
	expanded = submit(expanded,"frost_court","reserve_budget",{"id":"frost_plan","resource":"food","amount":20,"purpose":"winter planning"})
	var frost_offer := offer_payload("frost_peace")
	expanded = submit(expanded,"frost_court","propose_pact",frost_offer)
	expanded = submit(expanded,"iron_march","accept_pact",{"id":"frost_peace"})
	check(expanded.pact_offers.get("frost_peace",{}).get("signed_by",[]) == ["frost_court","iron_march"],"new faction uses the same bilateral authority")
	# More than the receipt-tail limit: an old successfully applied command stays spent.
	var long_state := World.initial()
	var first := World.command(long_state,"river_league","reserve_budget",{"id":"hold_0","resource":"coin","amount":1,"purpose":"receipt retention"})
	for i in range(40):
		long_state = submit(long_state,"river_league","reserve_budget",{"id":"hold_%d" % i,"resource":"coin","amount":1,"purpose":"receipt retention"})
		long_state = submit(long_state,"river_league","release_budget",{"id":"hold_%d" % i})
	check(long_state.receipts.size() == 64 and long_state.command_seq == 80, "bounded receipt tail keeps durable watermark")
	check(not World.apply(long_state,first).ok and Company.same_data(World.apply(long_state,first).state,long_state), "old command remains rejected after receipt pruning")
	for failure in failures: push_error(failure)
	print("world_strategy_tests: %s checks, %s failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
