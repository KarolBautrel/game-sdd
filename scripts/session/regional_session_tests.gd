extends SceneTree
const Session := preload("res://scripts/session/strategy_campaign_session.gd")
const R := Session.Region
var checks := 0
var failures: Array[String]=[]
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label);print("FAIL: ",label)
func do_order(c: RefCounted, action: String, p: Dictionary={}) -> bool:
	var result: bool=c.regional(action,p)
	check(result,action+": "+c.last_feedback)
	return result
func go(c: RefCounted, id: String) -> void:
	if not do_order(c,"course",{"position":c.state.region.sites[id].position,"site":id}): return
	for i in range(1000):
		if c.state.travel.path.is_empty(): break
		if not do_order(c,"advance",{"ticks":1}): return
	check(R.current(c.state)==id,"actual terrain route arrives at "+id)
func _initialize() -> void:
	var c := Session.new()
	check(c.create_region(2087),"explicit memory region")
	if not c.loaded: finish();return
	var restore_id := ""
	for j: Dictionary in c.state.jobs.values():
		if j.kind=="restoration": restore_id=j.id
	check(restore_id!="" and R.job_reason(c.state,restore_id)=="","actual occupied-mine cause funded at Ravenford")
	do_order(c,"accept_job",{"id":restore_id})
	go(c,"dungeon_old_mine")
	var data: Dictionary=preload("res://scripts/domain/dungeon_entry_selection.gd").dungeon_for_payload(preload("res://scripts/domain/dungeon_entry_selection.gd").authored_payload())
	var state: Dictionary=Session.Company.Model.initial_state(data)
	do_order(c,"begin_run",{"data":data,"state":state})
	check(not c.state.company.active_run.is_empty() and R.valid(c.state),"owned active run saved in v3")
	# Retreat is a genuine domain result and cannot complete the restoration job.
	var retreated: Dictionary=Session.Company.Model.retreat_run(data,c.state.company.active_run.state)
	check(retreated.status=="accepted","normal dungeon retreat")
	if retreated.status=="accepted":
		do_order(c,"checkpoint",{"data":data,"state":retreated.state,"seed":4321})
		var payload: Dictionary=retreated.event.run_result_payload.duplicate(true);payload.run_id=c.state.company.active_run.id
		do_order(c,"settle",{"payload":payload})
		check(c.state.mine.status=="occupied" and c.state.jobs[restore_id].status=="accepted","retreat never restores or pays")
		check(not c.regional("settle",{"payload":payload}),"duplicate run settlement rejects")
	go(c,"town_ravenford")
	var gold: int=c.state.company.gold
	do_order(c,"buy_supply",{"id":"food"})
	check(c.state.company.gold<gold and R.C.S.reconciles(c.state.strategy_world),"local company/world exchange reconciles")
	var recon := ""
	for j: Dictionary in c.state.jobs.values():
		if j.kind=="recon" and j.issuer=="iron_march" and j.status=="offered": recon=j.id
	go(c,"black_keep")
	if recon!="" and c.state.jobs.has(recon) and c.state.jobs[recon].status=="offered":
		do_order(c,"accept_job",{"id":recon});go(c,"high_pass")
		check(c.state.jobs[recon].status=="objective","real post-acceptance visit creates recon readiness")
		go(c,"black_keep");do_order(c,"report_job",{"id":recon})
		check(not c.regional("report_job",{"id":recon}),"recon cannot pay twice")
	else: check(false,"initial recon offer survives ordinary route to issuer")
	delivery()
	disk()
	finish()
func delivery() -> void:
	var c := Session.new();check(c.create_region(2087),"fresh causal delivery company")
	var id := ""
	for j: Dictionary in c.state.jobs.values():
		if j.kind=="delivery" and j.issuer=="cinder_compact": id=j.id
	check(id!="" and R.job_reason(c.state,id).contains("Stop at"),"delivery can only be accepted at its actual issuer")
	go(c,"ashmere")
	do_order(c,"accept_job",{"id":id})
	var actual_food: int=c.state.company.supplies.food
	c.state.company.supplies.food=2
	var before: Dictionary=c.state.duplicate(true)
	check(not c.regional("report_job",{"id":id}) and c.last_feedback.contains("2/3") and Session.Company.same_data(c.state,before),"short owned-food boundary rejects atomically")
	c.state.company.supplies.food=actual_food
	var gold: int=c.state.company.gold;var food: int=c.state.strategy_world.core.factions.cinder_compact.stocks.food
	var coin: int=c.state.strategy_world.core.factions.cinder_compact.stocks.coin
	do_order(c,"report_job",{"id":id})
	check(c.state.company.gold==gold+12 and c.state.company.supplies.food==actual_food-3 and c.state.strategy_world.core.factions.cinder_compact.stocks.coin==coin-12 and c.state.strategy_world.core.factions.cinder_compact.stocks.food==food+12,"delivery transfers real reserved coin and converted owned provisions")
	check(R.C.S.reconciles(c.state.strategy_world) and not c.regional("report_job",{"id":id}),"delivery ledger reconciles and payment cannot repeat")
	var expired := Session.new();expired.create_region(2087)
	var old_restore := ""
	for j: Dictionary in expired.state.jobs.values():
		if j.kind=="restoration": old_restore=j.id
	do_order(expired,"advance",{"ticks":192});do_order(expired,"advance",{"ticks":97})
	check(expired.state.jobs[old_restore].status=="closed" and R.C.S.reconciles(expired.state.strategy_world),"unaccepted expired offer closes and releases real funds")

func disk() -> void:
	var path := "user://qa_strategy_world_region_test_%d.json" % Time.get_ticks_usec()
	check(not FileAccess.file_exists(path),"disk fixture is fresh")
	if FileAccess.file_exists(path): return
	var c := Session.new()
	check(c.create_region(2087,path,false),"persist fresh v3")
	var before := c.state.duplicate(true);var bytes := FileAccess.get_file_as_string(path)
	check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(path+".tmp"))==OK,"owned empty directory blocks write")
	check(not c.regional("advance",{"ticks":96}) and Session.Company.same_data(before,c.state) and FileAccess.get_file_as_string(path)==bytes,"full regional day rolls back on failed save")
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(path+".tmp"))==OK,"remove own failure fixture")
	do_order(c,"advance",{"ticks":96})
	var restored := Session.new()
	check(restored.load_profile(path) and Session.Company.same_data(restored.state,c.state),"exact v3 disk reload")
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(path))==OK,"remove only own QA file")
func finish() -> void:
	for failure: String in failures: push_error(failure)
	print("regional_session_tests: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
