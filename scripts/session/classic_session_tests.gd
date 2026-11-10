extends SceneTree
const Session := preload("res://scripts/session/strategy_campaign_session.gd")
const C := Session.Classic
const Company := Session.Company
var checks := 0
var failures: Array[String]=[]

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label);print("FAIL: ",label)

func _initialize() -> void:
	var path := Session.Kind.STRATEGY_PREFIX+str(Time.get_ticks_usec())+"_classic.json"
	check(not FileAccess.file_exists(path),"fresh dedicated classic QA path")
	if FileAccess.file_exists(path): finish();return
	var session := Session.new()
	check(session.create_classic(2089,path,false) and session.state.version==2,"explicit classic v2 creation")
	if not session.loaded: finish();return
	var original_company: Dictionary=session.state.company.duplicate(true)
	var initial := session.state.duplicate(true)
	var bytes := FileAccess.get_file_as_string(path)
	var advance := C.command(session.state.strategy_world,"world_clock","advance",{"ticks":672})
	var temp := path+".tmp"
	check(not FileAccess.file_exists(temp) and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(temp)),"blocking fixture is fresh")
	check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(temp))==OK,"owned sibling blocks temporary write")
	check(not session.apply_command(advance),"failed multi-day save rejects")
	check(Company.same_data(session.state,initial) and FileAccess.get_file_as_string(path)==bytes,"entire week rolls back including decisions, time, stock, armies and treaties")
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))==OK,"remove own empty fixture directory")
	check(session.apply_command(advance),"same week retries exactly once")
	check(session.state.strategy_world.core.tick==672 and session.state.company.world.elapsed_hours==168,"company clock projects strategic ticks")
	var projected: Dictionary=session.state.company.duplicate(true);projected.world.elapsed_hours=0
	check(Company.same_data(projected,original_company),"isolated simulation preserves company gold/food/gear/XP")
	bytes=FileAccess.get_file_as_string(path)
	check(not session.apply_command(advance) and FileAccess.get_file_as_string(path)==bytes,"duplicate advance cannot replay production or movement")
	var restored := Session.new()
	check(restored.load_profile(path) and Company.same_data(restored.state,session.state),"exact classic disk round-trip")
	check(FileAccess.get_file_as_string(path)==bytes,"load performs no rewrite or catchup")
	var next := C.command(session.state.strategy_world,"world_clock","advance",{"ticks":672})
	check(session.apply_command(next) and restored.apply_command(next) and Company.same_data(session.state,restored.state),"restart produces identical following week")
	var legacy := Company.new()
	check(not legacy.load_profile(path,false),"legacy loader refuses classic campaign")
	legacy.free()
	var foundation := Session.new()
	check(foundation.create(2089) and foundation.state.version==1,"old foundation format remains explicit")
	check(not foundation.apply_command(C.command(session.state.strategy_world,"world_clock","advance",{"ticks":1})),"classic command cannot run against v1 campaign")
	check(not session.apply_command(Session.World.command(foundation.state.strategy_world,"river_league","reserve_budget",{"id":"legacy_hold","resource":"coin","amount":1,"purpose":"cross-mode"})),"v1 command cannot run against classic campaign")
	var original_version: int=session.state.version
	var bad := session.state.duplicate(true);bad.version=3
	check(not Session.valid(bad) and session.state.version==original_version,"unsupported version cannot replace profile")
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(path))==OK and not FileAccess.file_exists(temp),"remove only fresh QA profile; no leftover temporary file")
	finish()

func finish() -> void:
	for failure: String in failures: push_error(failure)
	print("classic_session_tests: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
