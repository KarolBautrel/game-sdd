extends SceneTree
## Headless native owner/packing/return, normal resolver commands; no Debug Win.
const Session := preload("res://scripts/session/strategy_campaign_session.gd")
const R := Session.Region
const Dungeon := preload("res://scenes/dungeon/DungeonDebug.tscn")
const Battle := preload("res://scenes/combat/CombatDebug.tscn")
var checks := 0
var failures: Array[String]=[]
var commands: Array=[]
var owner: Node
var run_session: Node
var viewport: SubViewport
var path := ""

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label);print("FAIL: ",label)
func _initialize() -> void: run.call_deferred()
func _create_session(session: RefCounted, file: String) -> bool: return session.create_region(2087,file,false)
func _world_scene() -> String: return "res://scenes/world/StrategicWorld.tscn"
func _output() -> String: return "res://artifacts/qa-runs/regional-expedition"
func _suite() -> String: return "regional_expedition_tests"
func frames(count: int=3) -> void:
	for i in range(count): await process_frame
func go(id: String) -> void:
	check(owner.order("course",{"position":owner.session.state.region.sites[id].position,"site":id}),"real course "+id)
	for tick in range(1000):
		if owner.session.state.travel.path.is_empty(): break
		if not owner.order("advance",{"ticks":1}): check(false,"world route advance: "+owner.last_feedback);return
	check(R.current(owner.session.state)==id,"real arrival "+id)
func room(hud: Control, id: String) -> void:
	hud._try_enter_room(id)
	for i in range(5):
		var hazard: Dictionary=hud.run_state.get("pending_corridor_hazard",{})
		var event: Dictionary=hud.run_state.get("pending_room_event",{})
		if hazard.is_empty() and event.is_empty(): break
		var choices: Array=(hazard if not hazard.is_empty() else event).get("choices",[])
		var selected := ""
		for choice: Dictionary in choices:
			if choice.get("available",false):
				selected=choice.id
				if choice.id in ["move_on","use_supply","use_pickaxe"]: break
		if selected=="": check(false,"available ordinary event choice");return
		if not hazard.is_empty(): hud._resolve_pending_corridor_hazard(selected)
		else: hud._resolve_pending_room_event(selected)
	check(hud.run_state.current_room_id==id,"normal domain room "+id)

func run() -> void:
	owner=root.get_node("StrategicSession");run_session=root.get_node("DungeonRunSession")
	path="user://qa_strategy_world_region_mine_%d.json" % Time.get_ticks_usec()
	check(not FileAccess.file_exists(path),"fresh managed QA file")
	if FileAccess.file_exists(path): finish();return
	var session := Session.new()
	check(_create_session(session,path),"persist new terrain-bound campaign")
	if not session.loaded: finish();return
	owner.session=session;owner.active=true;run_session.clear()
	var job_id := ""
	for j: Dictionary in session.state.jobs.values():
		if j.kind=="restoration": job_id=j.id
	check(owner.order("accept_job",{"id":job_id}),"accept real funded restoration at issuer")
	go("dungeon_old_mine")
	viewport=SubViewport.new();viewport.size=Vector2i(1920,1080);root.add_child(viewport)
	run_session.town_preparation=true
	var hud := Dungeon.instantiate();viewport.add_child(hud);await frames()
	if hud.dungeon_source!=hud.DUNGEON_SOURCE_AUTHORED: hud.source_toggle_button.pressed.emit();await frames()
	check(run_session.town_preparation and hud.dungeon.id=="dungeon_old_mine","native preparation retains strategic owner")
	var food: int=owner.state.supplies.food
	hud.expedition_chrome.pinned_start.pressed.emit();await frames()
	check(run_session.managed_run and not owner.state.active_run.is_empty() and owner.state.supplies.food<food,"actual native Start packs owned supplies once")
	check(hud.world_button.text=="Return to the region","native return label identifies current region")
	room(hud,"dusty_crossing");room(hud,"guarded_cache")
	check(not hud.run_state.pending_combat_request.is_empty(),"ordinary guarded room requests combat")
	check(run_session.start_combat(hud.dungeon,hud.run_state,20261107),"ordinary owned combat launch")
	var restored := Session.new()
	check(restored.load_profile(path) and R.Legacy.same_data(restored.state,owner.session.state),"pending encounter survives exact disk reload")
	owner.session=restored
	check(run_session.restore_campaign() and run_session.has_pending_combat_launch(),"restart restores encounter entry and owner")
	var battle := Battle.instantiate();viewport.add_child(battle);await frames(5)
	check(battle.state.source_dungeon_id==hud.dungeon.id and battle.state.source_room_id=="guarded_cache","native battle metadata comes from the actual expedition")
	for i in range(400):
		if battle._combat_result()!="in_progress": break
		var policy: Dictionary=battle.state.duplicate(true)
		if battle._unit_by_id(policy.turn_state.active_unit_id).team=="player":
			for unit: Dictionary in policy.units: unit.team="enemy" if unit.team=="player" else "player"
		var cmd: Dictionary=battle.CombatResolver.choose_enemy_command(policy,"cmd_%03d" % battle.command_index)
		commands.append(cmd.duplicate(true));battle._run_command_without_render(cmd)
	check(battle._combat_result()=="victory","ordinary shared-resolver policy reaches victory")
	for event: Dictionary in battle.state.event_log: check(event.type!="command_rejected" and event.get("source","")!="debug_win","no forced victory or illegal command")
	var payload: Dictionary=battle._combat_result_payload()
	check(run_session.finish_combat(payload),"real battle result clears owned guarded room")
	check(owner.state.active_run.state.cleared_room_ids.has("guarded_cache"),"clearance is durable in the strategic profile")
	battle.queue_free();hud.queue_free();await frames()
	hud=Dungeon.instantiate();viewport.add_child(hud);await frames()
	hud.reward_button.pressed.emit()
	check(hud.run_state.claimed_reward_room_ids.has("guarded_cache") and hud.run_state.run_inventory.gold==7,"ordinary claim records exact owned loot")
	room(hud,"lower_exit")
	var before: Dictionary=owner.session.state.duplicate(true);var bytes := FileAccess.get_file_as_string(path)
	check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(path+".tmp"))==OK,"owned directory forces completion-save failure")
	hud.finish_button.pressed.emit()
	check(hud.run_state.completed and owner.session.state.mine.status=="occupied" and R.Legacy.same_data(before,owner.session.state) and FileAccess.get_file_as_string(path)==bytes,"failed completion write grants no restoration/loot")
	var routes: Array=[];hud.scene_requested.connect(func(destination): routes.append(destination))
	hud.world_button.pressed.emit()
	check(routes.is_empty() and owner.session.state.mine.status=="occupied","failed checkpoint blocks return settlement")
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(path+".tmp"))==OK,"remove own blocking directory")
	hud.world_button.pressed.emit();await frames()
	check(routes==[_world_scene()],"ordinary F7/return routes back to strategic map")
	check(owner.state.active_run.is_empty() and owner.session.state.mine.status=="restored" and owner.session.state.jobs[job_id].status=="objective","normal completion restores mine and only readies contract")
	check(owner.session.state.strategy_world.rules.policies.river_league.production.ore==owner.session.state.mine.ore_rate,"real ore production resumes")
	check(not owner.settle(payload),"combat payload cannot masquerade as another expedition settlement")
	hud.queue_free();await frames()
	go("town_ravenford")
	var gold: int=owner.state.gold;var xp: int=owner.state.xp
	var treasury: int=owner.session.state.strategy_world.core.factions.river_league.stocks.coin
	var reward: int=owner.session.state.jobs[job_id].gold
	check(owner.order("report_job",{"id":job_id}),"issuer pays actual reserved restoration reward")
	check(owner.state.gold==gold+reward and owner.state.xp==xp+12 and owner.session.state.strategy_world.core.factions.river_league.stocks.coin==treasury-reward,"one exact transfer plus frozen XP")
	before=owner.session.state.duplicate(true)
	check(not owner.order("report_job",{"id":job_id}) and R.Legacy.same_data(before,owner.session.state),"paid restoration cannot pay twice")
	restored=Session.new();check(restored.load_profile(path) and R.Legacy.same_data(restored.state,owner.session.state),"restoration/payment/production survive exact reload")
	owner.session=restored
	var produced: int=restored.state.strategy_world.ledger.produced.ore
	var ticks: int=96-int(restored.state.strategy_world.core.tick)%96
	check(owner.order("advance",{"ticks":ticks}),"reach next real production boundary")
	check(owner.session.state.strategy_world.ledger.produced.ore==produced+9,"restored mine materially contributes to next ore production")
	check(not owner.order("begin_run",{"data":{},"state":{}}),"restored mine cannot be farmed")
	var output := _output()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var file := FileAccess.open(output+"/ordinary-commands.json",FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify({"headless":true,"physical":"NOT_RUN","debug_win":false,"commands":commands,"mine":owner.session.state.mine,"paid_job":owner.session.state.jobs[job_id]},"\t",true,true));file.close()
	owner.deactivate();viewport.queue_free();await frames()
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(path))==OK,"remove only fresh QA campaign")
	finish()

func finish() -> void:
	for failure: String in failures: push_error(failure)
	print("%s: %d checks, %d failures, %d ordinary battle commands" % [_suite(),checks,failures.size(),commands.size()])
	quit(0 if failures.is_empty() else 1)
