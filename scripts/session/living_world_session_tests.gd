extends SceneTree
const Campaign := preload("res://scripts/session/campaign_session.gd")
const World := preload("res://scripts/domain/living_world.gd")
const Selection := preload("res://scripts/domain/dungeon_entry_selection.gd")
const Model := preload("res://scripts/domain/dungeon_state_model.gd")
var failures: Array[String]=[]
var checks:=0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func go(campaign: Node,id: String) -> bool:
	if not campaign.living_course(Vector2.ZERO,id): return false
	for tick in range(600):
		if campaign.state.living_world.party.path.is_empty(): return World.at_site(campaign.state.living_world,id)
		if not campaign.state.world.pending_event.is_empty():
			if not campaign.choose_road_event("pay"): return false
		if not campaign.advance_living(): return false
	return false
func finished_fixture(campaign: Node,data: Dictionary,cleared: bool,outcome: String) -> Dictionary:
	# Trusted saved-state boundary fixture, not a physical/ordinary battle victory.
	var state: Dictionary=campaign.state.active_run.state.duplicate(true)
	state.completed=true
	state.run_outcome=outcome
	state.cleared_room_ids=["spider_nest"] if cleared else []
	campaign.checkpoint(data,state)
	var payload:=Model.run_result_payload(data,state,outcome)
	payload.run_id=campaign.state.active_run.id
	return payload
func _run() -> void:
	var campaign:=Campaign.new()
	campaign.load_profile("",true)
	var before:=campaign.state.duplicate(true)
	check(not campaign.living_course(Vector2(.5,.5)) and campaign.state==before,"legacy state cannot use living commands")
	check(campaign.enable_living_world() and World.valid(campaign.state.living_world),"opt-in initialization through campaign owner")
	check(campaign.state.version==4 and campaign.state.gold==80 and campaign.state.supplies.food==16,"versioned optional block and pilot starting stock")
	before=campaign.state.duplicate(true)
	check(not campaign.travel("dungeon_old_mine") and campaign.state==before,"legacy teleport unavailable in living mode")
	check(campaign.supply_price("food")==2 and campaign.purchase("food") and campaign.state.gold==78,"shown shortage price equals transaction")
	check(campaign.accept_living_contract("restore_mine"),"accept contextual contract at issuer")
	check(go(campaign,"dungeon_old_mine"),"continuous course reaches actual mine")
	check(not campaign.at_town() and not campaign.purchase("food"),"actual remote position gates services")
	var data:=Selection.dungeon_for_payload(Selection.authored_payload())
	var state:=Model.initial_state(data)
	check(campaign.begin_run(data,state),"existing owned packing starts managed mine")
	before=campaign.state.duplicate(true)
	check(not campaign.advance_living() and not campaign.living_course(Vector2.ZERO,"town_ravenford") and campaign.state==before,"active dungeon blocks surface commands")
	state=campaign.state.active_run.state.duplicate(true)
	state.visited_room_ids.append("dusty_crossing")
	# Boundary fixture: the next room crosses the company's daily payroll.
	campaign.state.living_world.tick=95
	campaign.state.world.elapsed_hours=23
	var wage_gold: int=campaign.state.gold
	var carried_food: int=campaign.state.supplies.food
	var tick_before: int=campaign.state.living_world.tick
	check(campaign.checkpoint(data,state) and campaign.state.living_world.tick==tick_before+1,"one new visited room charges fifteen minutes")
	check(campaign.state.gold==wage_gold-3 and campaign.state.supplies.food==carried_food,"dungeon clock pays daily wages without double-charging food")
	check(campaign.checkpoint(data,state) and campaign.state.living_world.tick==tick_before+1,"duplicate checkpoint never charges world time twice")
	check(campaign.state.gold==wage_gold-3,"duplicate room checkpoint cannot pay wages twice")
	state.camp_log.append({"fixture":"camp checkpoint"})
	check(campaign.checkpoint(data,state) and campaign.state.living_world.tick==tick_before+17,"new camp checkpoint charges four hours once")
	var payload:=finished_fixture(campaign,data,false,"completed")
	check(campaign.settle(payload) and campaign.state.living_world.mine.status=="occupied","completion bypassing defenders gives no restoration")
	check(campaign.begin_run(data,Model.initial_state(data)),"second ordinary mine expedition")
	payload=finished_fixture(campaign,data,true,"completed")
	check(campaign.settle(payload) and campaign.state.living_world.mine.status=="cleared","trusted cleared-room completion applies persistent world consequence")
	before=campaign.state.duplicate(true)
	check(not campaign.settle(payload) and campaign.state==before,"same receipt cannot restore/reward twice")
	check(go(campaign,"town_ravenford") and campaign.at_town(),"continuous journey returns to actual issuer")
	var gold: int=campaign.state.gold
	check(campaign.report_living_contract("restore_mine") and campaign.state.gold==gold+45 and campaign.state.living_world.factions.river_league.relation==10,"issuer pays exact reward and faction relation once")
	before=campaign.state.duplicate(true)
	check(not campaign.report_living_contract("restore_mine") and campaign.state==before,"duplicate reporting is atomic")
	check(campaign.supply_price("food")==1,"restored supply lowers actual food price")
	check(go(campaign,"saltwatch") and campaign.at_town(),"other settlement has services at actual position")
	check(campaign.accept_living_contract("supply_saltwatch"),"accept condition-created food delivery")
	var food: int=campaign.state.supplies.food
	check(campaign.report_living_contract("supply_saltwatch") and campaign.state.supplies.food==food-3,"delivery consumes actual owned company food")
	check(go(campaign,"black_keep") and campaign.accept_living_contract("scout_pass"),"second faction issues reconnaissance")
	check(go(campaign,"high_pass") and campaign.state.living_world.contracts.scout_pass.stage=="objective","actual visit completes accepted scouting objective")
	check(go(campaign,"black_keep") and campaign.report_living_contract("scout_pass") and campaign.state.living_world.factions.iron_march.relation==6,"recon report supports second faction")
	var path: String="user://qa_living_world_test_%s.json" % Time.get_ticks_usec()
	var saved:=Campaign.new()
	saved.load_profile(path)
	check(saved.enable_living_world(),"isolated pilot save creation")
	check(saved.living_course(Vector2.ZERO,"dungeon_old_mine") and saved.advance_living(2),"save persists mid-course position and clock")
	var bytes:=FileAccess.get_file_as_string(path)
	var restored:=Campaign.new()
	var loaded:=restored.load_profile(path)
	if not loaded: print("LIVING_LOAD_DIAGNOSTIC ",restored.last_feedback)
	elif not Campaign.same_data(restored.state,saved.state): print("LIVING_ROUNDTRIP_DIAGNOSTIC ",difference(restored.state,saved.state))
	check(loaded and Campaign.same_data(restored.state,saved.state) and FileAccess.get_file_as_string(path)==bytes,"reload preserves moving world without rewriting file")
	before=restored.state.duplicate(true)
	restored.save_path="user://missing_living_%s/profile.json" % Time.get_ticks_usec()
	check(not restored.advance_living() and restored.state==before and FileAccess.get_file_as_string(path)==bytes,"failed tick save rolls back every actor/resource/clock")
	var broken: Dictionary=saved.state.duplicate(true)
	broken.living_world.party.position.x=-1
	var file:=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(broken));file.close()
	bytes=FileAccess.get_file_as_string(path)
	check(not restored.load_profile(path) and FileAccess.get_file_as_string(path)==bytes,"invalid optional world state remains blocked and unchanged")
	var contact:=Campaign.new()
	contact.load_profile("",true);contact.enable_living_world()
	# A deliberate boundary fixture places both parties at the occupied mine.
	contact.state.living_world.party.position=World.site("dungeon_old_mine").position.duplicate()
	contact.state.world.location_id="dungeon_old_mine"
	check(contact.living_course(Vector2.ZERO,"high_pass") and contact.advance_living(),"surface contact simulation commits normally")
	check(contact.state.world.pending_event.get("kind")=="ambush","actual proximity creates existing persisted roadside ambush")
	before=contact.state.duplicate(true)
	check(not contact.advance_living() and not contact.living_course(Vector2.ZERO,"town_ravenford") and contact.state==before,"pending contact freezes clock and travel")
	check(contact.choose_road_event("pay") and contact.state.gold==75,"existing toll resolves living encounter for exact price")
	check(contact.advance_living() and contact.state.world.pending_event.is_empty(),"contact grace avoids immediate repeated encounter")
	contact.state=before.duplicate(true)
	check(contact.choose_road_event("fight") and contact.state.world.pending_event.phase=="combat","existing battle handoff snapshots living company")
	check(contact.state.world.pending_event.equipment_snapshot==contact.state.equipment,"road battle retains actual living loadout")
	contact.free()
	for node in [campaign,saved,restored]: node.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for failure in failures: push_error(failure)
	print("living_world_session_tests: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

func difference(a: Variant,b: Variant,path: String = "profile") -> String:
	if a is Dictionary and b is Dictionary:
		for key in a:
			if not b.has(key): return path+" missing "+str(key)
			if not Campaign.same_data(a[key],b[key]): return difference(a[key],b[key],path+"."+str(key))
	elif a is Array and b is Array:
		for index in range(mini(a.size(),b.size())):
			if not Campaign.same_data(a[index],b[index]): return difference(a[index],b[index],path+"[%s]" % index)
	return "%s: %s vs %s" % [path,a,b]
