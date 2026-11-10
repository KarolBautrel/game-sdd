extends SceneTree
## Boundary fixtures and real automated service chains; no desktop/player saves.
const Campaign := preload("res://scripts/session/campaign_session.gd")
const World := preload("res://scripts/domain/living_world.gd")
const Travel := preload("res://scripts/domain/world_travel.gd")
const Selection := preload("res://scripts/domain/dungeon_entry_selection.gd")
const Model := preload("res://scripts/domain/dungeon_state_model.gd")
var failures: Array[String] = []
var checks := 0
var metrics: Array[Dictionary] = []
var toll_gold := 0

func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func memory() -> Node:
	var c := Campaign.new()
	check(c.load_profile("",true) and c.enable_living_world(), "isolated in-memory company")
	return c

func place(c: Node, id: String) -> void:
	# Explicit boundary fixture, never used by the normal service-chain proof.
	c.state.living_world.party.position = World.site(id,c.state.living_world).position.duplicate()
	c.state.living_world.party.path = []
	c.state.living_world.party.goal = ""
	c.state.world.location_id = id

func reject(c: Node, method: String, id: String, label: String) -> void:
	var before: Dictionary = c.state.duplicate(true)
	var availability: Dictionary = c.living_contract_availability(id)
	var reason: String = availability.accept_reason if method == "accept_living_contract" else availability.report_reason
	check(Campaign.same_data(c.state,before), label+" availability query is read-only")
	check(not c.call(method,id), label+" rejects")
	check(Campaign.same_data(c.state,before), label+" preserves full snapshot")
	if not reason.is_empty(): check(c.last_feedback == reason, label+" command uses the shared reason")

func go(c: Node, id: String) -> bool:
	if not c.living_course(Vector2.ZERO,id): return false
	for tick in range(2400):
		if not c.state.world.pending_event.is_empty():
			var before_gold: int = c.state.gold
			if not c.choose_road_event("pay"): return false
			toll_gold += before_gold-int(c.state.gold)
		if c.state.living_world.party.path.is_empty(): return World.at_site(c.state.living_world,id)
		if not c.advance_living(): return false
	return false

func boundaries() -> void:
	var c := memory()
	reject(c,"report_living_contract","unknown_contract","unknown report")
	reject(c,"accept_living_contract","unknown_contract","unknown acceptance")
	place(c,"saltwatch")
	reject(c,"report_living_contract","supply_saltwatch","unaccepted delivery")
	check(c.accept_living_contract("supply_saltwatch"), "accept actual delivery offer at issuer")
	reject(c,"accept_living_contract","supply_saltwatch","duplicate acceptance")
	c.state.supplies.food = 2
	reject(c,"report_living_contract","supply_saltwatch","insufficient owned food")
	c.state.supplies.food = 3
	place(c,"town_ravenford")
	c.state.world.location_id = "saltwatch"
	reject(c,"report_living_contract","supply_saltwatch","stale issuer location cannot bypass actual position")
	place(c,"saltwatch")
	check(c.living_course(Vector2.ZERO,"black_keep"), "normal outgoing route starts")
	reject(c,"report_living_contract","supply_saltwatch","moving company cannot hand in delivery")
	check(c.living_camp(false), "ordinary stop clears pending movement")
	c.state.living_world.settlements.saltwatch.supply = 90
	c.state.living_world.factions.river_league.relation = 98
	var before: Dictionary = c.state.duplicate(true)
	check(c.report_living_contract("supply_saltwatch"), "exact threshold of three food is sufficient")
	check(c.state.supplies.food == 0 and c.state.gold == before.gold+14 and c.state.xp == before.xp+3, "delivery exact stock/gold/XP transaction")
	check(c.state.living_world.settlements.saltwatch.supply == 100 and c.state.living_world.factions.river_league.relation == 100, "delivery caps supply and relation")
	check(c.state.living_world.tick == before.living_world.tick, "report does not advance strategic time")
	reject(c,"report_living_contract","supply_saltwatch","paid delivery cannot pay twice")
	place(c,"black_keep")
	reject(c,"report_living_contract","scout_pass","unvisited recon cannot report")
	check(c.accept_living_contract("scout_pass"), "accept actual reconnaissance")
	reject(c,"report_living_contract","scout_pass","accepted recon needs a subsequent visit")
	check(go(c,"high_pass"), "real route reaches accepted High Pass objective")
	check(c.state.living_world.contracts.scout_pass.stage == "objective" and c.state.living_world.intelligence, "actual arrival records intelligence")
	reject(c,"report_living_contract","scout_pass","objective cannot report away from issuer")
	check(go(c,"black_keep"), "normal reconnaissance return route")
	c.state.living_world.factions.iron_march.relation = 97
	c.state.living_world.factions.river_league.relation = -99
	c.state.living_world.politics.tension = 96
	before = c.state.duplicate(true)
	check(c.report_living_contract("scout_pass") and c.state.gold == before.gold+18 and c.state.xp == before.xp+5, "recon exact one-time payment")
	check(c.state.living_world.factions.iron_march.relation == 100 and c.state.living_world.factions.river_league.relation == -100 and c.state.living_world.politics.tension == 100, "recon consequences retain existing bounds")
	reject(c,"report_living_contract","scout_pass","paid reconnaissance cannot pay twice")
	c.free()
	# Visit before acceptance must not satisfy a later contract.
	c = memory()
	check(go(c,"high_pass") and c.state.living_world.contracts.scout_pass.stage == "offered", "pre-acceptance visit grants no objective")
	check(go(c,"black_keep") and c.accept_living_contract("scout_pass"), "accept after an earlier visit")
	reject(c,"report_living_contract","scout_pass","old visit cannot retroactively complete reconnaissance")
	c.state.world.journey_count = int(c.state.world.journey_count)+1
	c.state.world.pending_event = Travel.pending_for(c.state.world,{"to":"black_keep","danger":1.0})
	check(not c.state.world.pending_event.is_empty(), "genuine persisted road-event fixture")
	reject(c,"accept_living_contract","restore_mine","pending event blocks acceptance")
	reject(c,"report_living_contract","scout_pass","pending event blocks reporting")
	c.free()
	c = memory()
	place(c,"dungeon_old_mine")
	var data := Selection.dungeon_for_payload(Selection.authored_payload())
	check(c.begin_run(data,Model.initial_state(data)), "genuine managed expedition gates strategic commands")
	reject(c,"accept_living_contract","restore_mine","active expedition blocks acceptance")
	check(c.last_feedback == "Resolve the expedition or road encounter first.", "expedition gate precedes issuer check")
	reject(c,"report_living_contract","supply_saltwatch","active expedition blocks reporting")
	c.free()

func disk() -> void:
	var unique := str(Time.get_ticks_usec())
	var path := "user://qa_living_world_contract_audit_"+unique+".json"
	check(not FileAccess.file_exists(path), "disk audit creates only a new QA file")
	if FileAccess.file_exists(path): return
	var c := Campaign.new()
	check(c.load_profile(path,false) and c.enable_living_world(), "fresh persisted QA company")
	place(c,"saltwatch")
	c.state.supplies.food = 3
	check(c.accept_living_contract("supply_saltwatch"), "persist accepted delivery with owned food")
	var before: Dictionary = c.state.duplicate(true)
	var bytes := FileAccess.get_file_as_string(path)
	var missing := "user://missing_contract_audit_"+unique
	check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(missing)), "failure fixture directory is absent")
	c.save_path = missing+"/profile.json"
	reject(c,"report_living_contract","supply_saltwatch","failed delivery write")
	check(c.last_feedback.contains("Cannot write") and FileAccess.get_file_as_string(path) == bytes, "failed write preserves original file bytes")
	c.save_path = path
	check(c.report_living_contract("supply_saltwatch"), "normal retry pays delivery after write recovery")
	check(c.state.gold == before.gold+14 and c.state.supplies.food == 0, "retry publishes one payment and one stock deduction")
	bytes = FileAccess.get_file_as_string(path)
	var restored := Campaign.new()
	check(restored.load_profile(path,false) and Campaign.same_data(restored.state,c.state), "paid delivery round-trips exactly from disk")
	reject(restored,"report_living_contract","supply_saltwatch","reloaded paid delivery cannot pay twice")
	check(FileAccess.get_file_as_string(path) == bytes, "duplicate rejection leaves disk bytes identical")
	c.free(); restored.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(not FileAccess.file_exists(path+".tmp"), "atomic commits leave no QA temporary file")

func upkeep() -> void:
	var c := memory()
	var a: Dictionary = c.state.duplicate(true)
	var b: Dictionary = a.duplicate(true)
	World.advance(a,31)
	check(a.supplies.food == 16 and a.gold == 80, "no early eight-hour food or daily wages")
	World.advance(a,1)
	World.advance(b,32)
	check(a.supplies.food == 15 and Campaign.same_data(a,b), "food boundary charges once and tick batching is deterministic")
	a.living_world.tick = 95; a.gold = 1; a.supplies.food = 0
	World.advance(a,1)
	check(a.gold == 0 and a.supplies.food == 0, "depleted wages/food clamp without negative resources")
	c.state.living_world.party.fatigue = 19
	var point: Dictionary = c.state.living_world.party.position.duplicate()
	check(c.living_camp(true) and c.advance_living(4), "ordinary camp advances time")
	check(c.state.living_world.party.fatigue == 3 and c.state.living_world.party.position == point, "camp recovers four fatigue per tick without moving")
	var tick: int = c.state.living_world.tick
	check(c.living_camp(false) and c.state.living_world.tick == tick, "packing camp does not add a tick")
	c.state.living_world.tick = 95; c.state.world.elapsed_hours = 23
	c.state.gold = 10; c.state.supplies.food = 1
	check(c.living_camp(true) and c.advance_living(), "camp crosses an actual food/payroll boundary")
	check(c.state.gold == 7 and c.state.supplies.food == 0 and c.state.living_world.party.position == point, "camp still pays food and wages once without movement")
	check(c.living_camp(false), "camp can be packed after upkeep")
	c.state.gold = 0; c.state.supplies.food = 0
	check(c.living_course(Vector2.ZERO,"black_keep") and c.advance_living(), "starvation and depleted wages do not forbid legal travel")
	check(c.state.living_world.party.position != point and c.state.gold == 0, "hungry penniless company still moves")
	c.free()

func chain(seed_value: int) -> void:
	toll_gold = 0
	var c := Campaign.new()
	c.load_profile("",true)
	var enabled: bool = c.enable_living_world() if seed_value == 0 else c.enable_generated_region(seed_value,"marches",2)
	check(enabled, "service chain initialises actual geography "+str(seed_value))
	if not enabled: c.free(); return
	var start_gold: int = c.state.gold
	check(go(c,"saltwatch") and c.accept_living_contract("supply_saltwatch"), "normal travel and delivery acceptance "+str(seed_value))
	var provision_price: int = c.supply_price("food")
	var stock_before: int = c.state.supplies.food
	var gold_before: int = c.state.gold
	check(c.purchase("food") and c.state.supplies.food == stock_before+1 and c.state.gold == gold_before-provision_price, "service chain buys a real provision at the current quoted price")
	var provision_cost := provision_price
	while int(c.state.supplies.food) < 3:
		var price: int = c.supply_price("food")
		if not c.purchase("food"): break
		provision_cost += price
	var before: Dictionary = c.state.duplicate(true)
	check(c.report_living_contract("supply_saltwatch"), "normal owned delivery hand-in "+str(seed_value))
	check(c.state.gold == before.gold+14 and c.state.supplies.food == before.supplies.food-3, "service-chain delivery uses actual owned stock")
	check(go(c,"black_keep") and c.accept_living_contract("scout_pass"), "normal second-faction acceptance "+str(seed_value))
	check(go(c,"high_pass") and c.state.living_world.contracts.scout_pass.stage == "objective", "normal scouting objective "+str(seed_value))
	check(go(c,"black_keep"), "normal return to recon issuer "+str(seed_value))
	before = c.state.duplicate(true)
	check(c.report_living_contract("scout_pass") and c.state.gold == before.gold+18 and c.state.xp == before.xp+5, "normal scouting hand-in "+str(seed_value))
	check(World.valid(c.state.living_world) and c.state.living_world.contracts.supply_saltwatch.stage == "completed", "valid company after both actual service chains")
	var wages: int = (int(c.state.living_world.tick)/96)*3
	var total_cost: int = start_gold+32-int(c.state.gold)
	check(total_cost == wages+provision_cost+toll_gold, "whole chain reconciles wages, actual provision invoices and recorded road tolls")
	metrics.append({"seed":seed_value,"size":"authored" if seed_value == 0 else "Large","start_gold":start_gold,"gold":c.state.gold,"xp":c.state.xp,"food":c.state.supplies.food,"ticks":c.state.living_world.tick,"fatigue":c.state.living_world.party.fatigue,"wages":wages,"provision_cost":provision_cost,"road_tolls":toll_gold,"river_relation":c.state.living_world.factions.river_league.relation,"iron_relation":c.state.living_world.factions.iron_march.relation})
	c.free()

func _run() -> void:
	boundaries()
	disk()
	upkeep()
	for seed_value: int in [0,2087,20261107]: chain(seed_value)
	print("CONTRACT_CHAIN_METRICS ",JSON.stringify(metrics))
	for failure in failures: push_error(failure)
	print("living_contract_regression_tests: %s checks, %s failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
