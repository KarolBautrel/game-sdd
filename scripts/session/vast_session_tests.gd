extends SceneTree
const Session := preload("res://scripts/session/strategy_campaign_session.gd")
const Bridge := preload("res://scripts/session/strategic_session.gd")
const Campaign := preload("res://scripts/session/campaign_session.gd")
const Pilot := preload("res://scripts/qa/living_world_pilot.gd")
var checks := 0
var failures: Array[String]=[]
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label);print("FAIL: ",label)
func _initialize() -> void:
	check(Bridge.campaign_path(2087,"marches",true,2)=="user://qa_strategy_world_model_v4_marches_2087.json","old player slot name unchanged")
	check(Bridge.campaign_path(2087,"marches",true,3)!=Bridge.campaign_path(2087,"marches",true,2),"Vast model slot cannot overwrite Large")
	check(Bridge.campaign_path(2087,"marches",false,3)!=Bridge.campaign_path(2087,"marches",true,3),"both formats own distinct Vast slots")
	check(Pilot.generated_path(2087,"marches",3)!=Pilot.generated_path(2087,"marches",2),"legacy generated sizes are independently resumable")
	var stamp := str(Time.get_ticks_usec());var old_path := "user://qa_strategy_world_vast_old_"+stamp+".json";var path := "user://qa_strategy_world_vast_new_"+stamp+".json"
	check(not FileAccess.file_exists(old_path) and not FileAccess.file_exists(path),"both owned file fixtures are fresh")
	if FileAccess.file_exists(old_path) or FileAccess.file_exists(path): finish();return
	var old := Session.new();check(old.create_model(2087,old_path,false),"persist existing-size fixture")
	var old_bytes := FileAccess.get_file_as_string(old_path)
	var s := Session.new();check(s.create_model(2087,path,false,"marches",3),"explicit separate Vast campaign creation")
	check(FileAccess.get_file_as_string(old_path)==old_bytes and s.state.region.base.version==3,"new world leaves old company bytes intact")
	check(s.regional("course",{"position":s.state.region.sites.dungeon_old_mine.position,"site":"dungeon_old_mine"}) and s.regional("advance",{"ticks":1}),"actual Vast journey starts")
	check(absf(s.last_motion.budget-.01125)<.0000001,"Vast company has unchanged physical pace")
	var before := s.state.duplicate(true);var bytes := FileAccess.get_file_as_string(path)
	check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(path+".tmp"))==OK,"owned directory blocks candidate write")
	check(not s.regional("advance",{"ticks":24}) and Session.Company.same_data(before,s.state) and FileAccess.get_file_as_string(path)==bytes,"Vast day/route/world rolls back on failed save")
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(path+".tmp"))==OK,"remove only own empty blocker")
	check(s.regional("advance",{"ticks":24}),"Vast advance retries normally")
	var restored := Session.new();check(restored.load_profile(path) and Session.Company.same_data(restored.state,s.state),"exact moving Vast disk reload")
	check(restored.regional("model_mode",{"mode":"recorded"}) and restored.regional("advance",{"ticks":192}) and restored.regional("advance",{"ticks":72}),"adapter and travel share new geography authority")
	check(Session.Model.valid(restored.state),"company/strategy/adapter remains valid after wider-map travel")
	for days in range(15):
		check(restored.regional("advance",{"ticks":192}) and Session.Classic.S.reconciles(restored.state.strategy_world),"longer-route 30day accounting/validity batch")
	check(FileAccess.get_file_as_string(old_path)==old_bytes,"whole Vast simulation never writes old size slot")
	var living := Campaign.new();living.load_profile("",true)
	check(living.enable_generated_region(2087,"marches",3) and Campaign.Living.travel_scale(living.state.living_world)==4,"legacy living mode accepts explicit Vast size")
	check(living.living_course(Vector2.ZERO,"dungeon_old_mine") and living.advance_living(),"legacy party/NPC motion uses real Vast navigation")
	check(Session.Company._valid_profile(living.state),"legacy Vast composition remains valid")
	living.free()
	for owned: String in [path,old_path]: check(DirAccess.remove_absolute(ProjectSettings.globalize_path(owned))==OK,"remove only own fresh size fixture")
	finish()
func finish() -> void:
	for failure: String in failures: push_error(failure)
	print("vast_session_tests: %d checks, %d failures" % [checks,failures.size()]);quit(0 if failures.is_empty() else 1)
