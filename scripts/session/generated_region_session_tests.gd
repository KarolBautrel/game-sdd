extends SceneTree
const Campaign:=preload("res://scripts/session/campaign_session.gd")
const World:=preload("res://scripts/domain/living_world.gd")
const Gen:=preload("res://scripts/domain/region_generator.gd")
const Terrain:=preload("res://scripts/domain/terrain_navigation.gd")
const Pilot:=preload("res://scripts/qa/living_world_pilot.gd")
const Selection:=preload("res://scripts/domain/dungeon_entry_selection.gd")
const Model:=preload("res://scripts/domain/dungeon_state_model.gd")
var failures: Array[String]=[]
var checks:=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func go(campaign: Node,id: String) -> bool:
	if not campaign.living_course(Vector2.ZERO,id): return false
	for tick in range(600):
		if campaign.state.living_world.party.path.is_empty(): return World.at_site(campaign.state.living_world,id)
		if not campaign.state.world.pending_event.is_empty() and not campaign.choose_road_event("pay"): return false
		if not campaign.advance_living(): return false
	return false
func run() -> void:
	var bytes:=FileAccess.get_file_as_string(Terrain.PATH)
	var a:=Campaign.new();a.load_profile("",true)
	check(a.enable_generated_region(2087,"marches") and World.valid(a.state.living_world),"fresh generated campaign initialized through owner")
	var state_before: Dictionary=a.state.duplicate(true)
	check(not a.enable_generated_region(42,"woodland") and a.state==state_before,"reroll cannot replace an active company")
	check(a.accept_living_contract("restore_mine") and go(a,"dungeon_old_mine"),"actual generated mine position reached for accepted contract")
	var data:=Selection.dungeon_for_payload(Selection.authored_payload())
	check(not data.is_empty() and a.begin_run(data,Model.initial_state(data)),"existing owned packing/managed dungeon boundary works in generated geography")
	var retreat:=Model.retreat_run(data,a.state.active_run.state)
	var payload: Dictionary=retreat.state.run_result_payload.duplicate(true)
	payload.run_id=a.state.active_run.id
	check(a.checkpoint(data,retreat.state) and a.settle(payload),"normal managed retreat settles generated company")
	check(a.state.living_world.mine.status=="occupied" and a.state.living_world.contracts.restore_mine.stage=="accepted","retreat does not claim mine victory")
	check(go(a,"town_ravenford") and a.at_town() and a.purchase("food"),"generated return and actual town services")
	var b:=Campaign.new();b.load_profile("",true);b.enable_generated_region(42,"highlands")
	check(World.navigation(a.state.living_world)!=World.navigation(b.state.living_world),"two live profiles own independent navigation")
	var signature_a: String=World.navigation(a.state.living_world).signature
	Gen.generate(123456,"woodland")
	check(World.navigation(a.state.living_world).signature==signature_a,"previewing another seed cannot redirect live navigation")
	var path: String="user://qa_living_world_generated_v1_session_%s.json" % Time.get_ticks_usec()
	a.memory_only=false;a.save_path=path
	check(a.living_course(Vector2.ZERO,"saltwatch") and a.advance_living(2),"atomic generated mid-route save")
	var saved_bytes:=FileAccess.get_file_as_string(path)
	var restored:=Campaign.new()
	check(restored.load_profile(path) and Campaign.same_data(restored.state,a.state) and FileAccess.get_file_as_string(path)==saved_bytes,"reload preserves exact snapshot/clock/position without reroll/write")
	state_before=restored.state.duplicate(true)
	restored.save_path="user://missing_generated_%s/profile.json" % Time.get_ticks_usec()
	check(not restored.advance_living() and Campaign.same_data(restored.state,state_before),"failed generated tick rolls back snapshot/units/resources")
	var invalid: Dictionary=a.state.duplicate(true);invalid.living_world.geography.terrain.rows[0]="?"
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(invalid,"\t",true,true));file.close()
	var invalid_bytes:=FileAccess.get_file_as_string(path)
	check(not restored.load_profile(path) and FileAccess.get_file_as_string(path)==invalid_bytes,"corrupt snapshot remains blocked and unchanged")
	var current:=Campaign.new();current.load_profile("",true);current.enable_living_world()
	var authored: Dictionary=current.state.duplicate(true)
	check(not current.enable_generated_region(42) and current.state==authored,"authored profile cannot be replaced by generator command")
	# Unique temporary pilot slots, never the player's authored/generated slots.
	var unique_seed:=int(Time.get_ticks_usec()%900000000)+100000000
	while FileAccess.file_exists(Pilot.generated_path(unique_seed,"marches")) or FileAccess.file_exists(Pilot.generated_path(unique_seed+1,"marches")) or FileAccess.file_exists(Pilot.generated_path(unique_seed,"marches",2)): unique_seed-=2
	var disk:=Campaign.new();disk.load_profile("",true);disk.enable_living_world();disk.memory_only=false
	var generated_file:=Pilot.generated_path(unique_seed,"marches")
	var rejected_file:=Pilot.generated_path(unique_seed+1,"marches")
	check(Pilot.open_generated(disk,unique_seed,"marches") and FileAccess.file_exists(generated_file),"selector creates its own unique per-seed pilot save")
	check(disk.advance_living(3),"generated disk pilot advances real company")
	var persisted:=FileAccess.get_file_as_string(generated_file)
	var persisted_state: Dictionary=disk.state.duplicate(true)
	disk.load_profile("",true);disk.memory_only=false
	check(Pilot.open_generated(disk,unique_seed,"marches") and Campaign.same_data(disk.state,persisted_state) and FileAccess.get_file_as_string(generated_file)==persisted,"selector resumes exact existing per-seed state without rewriting it")
	var large_file:=Pilot.generated_path(unique_seed,"marches",2)
	check(Pilot.open_generated(disk,unique_seed,"marches",2) and int(disk.state.living_world.geography.version)==2 and FileAccess.file_exists(large_file),"same seed can open separate larger version2 company")
	check(FileAccess.get_file_as_string(generated_file)==persisted,"larger region cannot overwrite classic same-seed progress")
	check(Pilot.open_generated(disk,unique_seed,"marches",1) and Campaign.same_data(disk.state,persisted_state),"return from larger region resumes exact classic company")
	var rejected:=FileAccess.open(rejected_file,FileAccess.WRITE);rejected.store_string("{corrupt snapshot");rejected.close()
	var previous_path: String=disk.save_path
	check(not Pilot.open_generated(disk,unique_seed+1,"marches") and disk.loaded and disk.save_path==previous_path and Campaign.same_data(disk.state,persisted_state),"failed selector switch restores previous playable company/path")
	check(FileAccess.get_file_as_string(rejected_file)=="{corrupt snapshot","failed selector does not replace corrupt slot")
	for temporary: String in [generated_file,rejected_file,large_file]: DirAccess.remove_absolute(temporary)
	check(FileAccess.get_file_as_string(Terrain.PATH)==bytes,"all generated actions preserve designer r9")
	for node in [a,b,restored,current,disk]: node.free()
	DirAccess.remove_absolute(path)
	for failure in failures: push_error(failure)
	print("generated_region_session_tests: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
