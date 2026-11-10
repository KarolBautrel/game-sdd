extends SceneTree
## Isolated memory/fresh QA files only. Never opens a window or a player profile.
const Session := preload("res://scripts/session/strategy_campaign_session.gd")
const World := preload("res://scripts/domain/world_strategy.gd")
const Company := preload("res://scripts/session/campaign_session.gd")
const Kind := preload("res://scripts/session/campaign_profile_kind.gd")
var failures: Array[String] = []
var checks := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func write_text(path: String, contents: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	check(file != null,"write owned QA fixture")
	if file == null: return
	file.store_string(contents); file.close()

func hold(s: RefCounted) -> Dictionary:
	return World.command(s.state.strategy_world,"river_league","reserve_budget",{"id":"trade_budget","resource":"coin","amount":80,"purpose":"future trade"})

func _initialize() -> void:
	var s := Session.new()
	check(s.create(2087),"explicit in-memory strategy company")
	check(s.loaded and s.memory_only and Session.valid(s.state),"initial envelope is valid")
	check(s.state.company.gold == 80 and s.state.company.supplies.food == 16,"company stock is separate from factions")
	var original_company: Dictionary = s.state.company.duplicate(true)
	check(s.apply_command(hold(s)),"memory hold uses pure executor")
	var proposal := {"id":"trade_peace","target":"iron_march","kind":"nonaggression","duration_ticks":672,"valid_for_ticks":96}
	check(s.apply_command(World.command(s.state.strategy_world,"river_league","propose_pact",proposal)),"memory proposal")
	check(s.apply_command(World.command(s.state.strategy_world,"iron_march","accept_pact",{"id":"trade_peace"})),"memory recipient acceptance")
	check(Company.same_data(s.state.company,original_company),"world orders preserve company gear/XP/supplies/reputation")
	check(not s.create(42),"loaded session cannot silently restart")
	for mutate: Callable in [
		func(v): v.version=2,
		func(v): v.version=true,
		func(v): v.schema="other",
		func(v): v.company=null,
		func(v): v.company.version=3,
		func(v): v.company.version=true,
		func(v): v.company.world.seed=42,
		func(v): v.company.world.elapsed_hours=1,
		func(v): v.current_settlement_id="missing",
		func(v): v.company.living_world={},
		func(v): v.strategy_world.planner_mode="ai_strategy",
		func(v): v.extra=1,
	]:
		var invalid := s.state.duplicate(true); mutate.call(invalid)
		check(not Session.valid(invalid),"invalid/unsupported strategy envelope rejected")
	check(not Session.valid([]) and not Session.valid(null),"non-object envelope rejected")
	check(Kind.classify(s.state) == "strategy" and Kind.classify(Company.initial_profile()) == "legacy" and Kind.classify({}) == "unknown","explicit format discrimination")
	var old := Company.initial_profile(); old.version=1; old.erase("world"); old.erase("equipment"); old.erase("advancement")
	check(Kind.classify(old) == "legacy" and Company._valid_profile(old),"legacy v1 without world remains recognized")
	for forbidden: String in ["user://campaign_v1.json",Kind.STRATEGY_PREFIX+"a/../campaign_v1.json",Kind.STRATEGY_PREFIX+"a/file.json",Kind.STRATEGY_PREFIX+"a.txt"]:
		check(not Kind.is_strategy_path(forbidden),"dedicated path cannot escape its QA filename")
	disk(old)
	for failure in failures: push_error(failure)
	print("strategy_campaign_session_tests: %s checks, %s failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func disk(old: Dictionary) -> void:
	var unique := str(Time.get_ticks_usec())
	var path := Kind.STRATEGY_PREFIX+unique+".json"
	var corrupt := Kind.STRATEGY_PREFIX+unique+"_invalid.json"
	var missing := Kind.STRATEGY_PREFIX+unique+"_missing.json"
	var legacy_path := "user://qa_strategy_dispatch_"+unique+".json"
	for own_path: String in [path,corrupt,missing,legacy_path]:
		check(not FileAccess.file_exists(own_path),"owned QA file must be fresh")
		if FileAccess.file_exists(own_path): return
	var s := Session.new()
	check(s.create(2087,path,false),"fresh persisted strategy company")
	var before := s.state.duplicate(true)
	var bytes := FileAccess.get_file_as_string(path)
	var duplicate := Session.new()
	check(not duplicate.create(42,path,false) and FileAccess.get_file_as_string(path) == bytes,"creation refuses overwrite")
	check(not duplicate.create(2087,legacy_path,false) and not FileAccess.file_exists(legacy_path),"creation rejects non-strategy path")
	var absent := Session.new()
	check(not absent.load_profile(missing) and not absent.loaded and not FileAccess.file_exists(missing),"missing load never creates/reset a campaign")
	var cmd := hold(s)
	var blocked_temp := path+".tmp"
	check(not FileAccess.file_exists(blocked_temp) and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(blocked_temp)),"write-failure fixture is fresh")
	check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(blocked_temp)) == OK,"owned sibling directory blocks temporary file creation")
	check(not s.apply_command(cmd) and s.last_feedback.contains("Cannot write"),"failed atomic write rejects transaction")
	check(Company.same_data(s.state,before) and FileAccess.get_file_as_string(path) == bytes,"write failure preserves state/file/sequence/stock")
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked_temp)) == OK,"remove only owned empty blocking directory")
	s.save_path=legacy_path
	check(not s.apply_command(cmd) and not FileAccess.file_exists(legacy_path),"commit rechecks dedicated path")
	# Force rename failure after a successful temporary-file write.
	var blocked_target := Kind.STRATEGY_PREFIX+unique+"_blocked.json"
	check(not FileAccess.file_exists(blocked_target) and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(blocked_target)),"rename fixture target is fresh")
	check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(blocked_target)) == OK,"owned directory blocks file replacement")
	var collision := Session.new()
	check(not collision.create(2087,blocked_target,false),"create refuses an existing directory too")
	s.save_path=blocked_target
	check(not s.apply_command(cmd) and s.last_feedback.contains("Cannot replace"),"rename failure rejects saved candidate")
	check(Company.same_data(s.state,before) and FileAccess.get_file_as_string(path) == bytes,"rename failure preserves original memory and disk")
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked_target+".tmp")) == OK,"remove only own failed-rename temporary file")
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked_target)) == OK,"remove own empty rename fixture directory")
	s.save_path=path
	check(s.apply_command(cmd),"same command succeeds once after write recovery")
	var proposal := {"id":"persistent_peace","target":"iron_march","kind":"nonaggression","duration_ticks":672,"valid_for_ticks":96}
	check(s.apply_command(World.command(s.state.strategy_world,"river_league","propose_pact",proposal)),"persist offer")
	var accept := World.command(s.state.strategy_world,"iron_march","accept_pact",{"id":"persistent_peace"})
	before=s.state.duplicate(true); bytes=FileAccess.get_file_as_string(path)
	check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(blocked_temp)) == OK,"block acceptance save in owned fixture")
	check(not s.apply_command(accept) and Company.same_data(s.state,before) and FileAccess.get_file_as_string(path) == bytes,"failed pact write grants no second signature or treaty")
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked_temp)) == OK,"clear own acceptance write failure")
	check(s.apply_command(accept),"retry persists bilateral acceptance exactly once")
	bytes=FileAccess.get_file_as_string(path)
	var restored := Session.new()
	check(restored.load_profile(path) and restored.loaded and Company.same_data(restored.state,s.state),"complete envelope round-trips exactly")
	check(FileAccess.get_file_as_string(path) == bytes and restored.state.strategy_world.tick == 0,"load does not rewrite/catch up time")
	check(not restored.apply_command(cmd) and FileAccess.get_file_as_string(path) == bytes,"replayed saved command cannot charge/hold twice")
	var legacy := Company.new()
	check(not legacy.load_profile(missing,false) and not legacy.loaded and not FileAccess.file_exists(missing),"legacy loader rejects missing reserved path")
	write_text(legacy_path,bytes)
	check(not legacy.load_profile(legacy_path,false) and not legacy.loaded,"legacy loader rejects strategy envelope outside prefix")
	check(FileAccess.get_file_as_string(legacy_path) == bytes,"legacy rejection preserves strategy bytes")
	check(not restored.load_profile(legacy_path) and not restored.loaded,"strategy loader rejects non-strategy/player path")
	check(not restored.apply_command(World.command(s.state.strategy_world,"river_league","release_budget",{"id":"trade_budget"})),"failed load leaves mutations disabled")
	for contents: String in ["{broken",JSON.stringify(old),JSON.stringify({"schema":Kind.STRATEGY_SCHEMA,"version":99}),"null","[]"]:
		write_text(corrupt,contents)
		check(not restored.load_profile(corrupt) and not restored.loaded,"bad/legacy/unsupported file fails closed")
		check(FileAccess.get_file_as_string(corrupt) == contents,"rejected file is never reset/replaced")
	# Legacy migrations remain in memory, with no implicit strategy conversion.
	for version in range(1,5):
		var value := Company.initial_profile(); value.version=version
		if version < 4: value.erase("advancement")
		if version < 3: value.erase("equipment")
		if version < 2: value.erase("world")
		var legacy_bytes := JSON.stringify(value)
		write_text(legacy_path,legacy_bytes)
		check(legacy.load_profile(legacy_path,false) and legacy.state.version == 4,"legacy v%d still loads normally" % version)
		check(not legacy.state.has("strategy_world") and FileAccess.get_file_as_string(legacy_path) == legacy_bytes,"legacy migration is memory-only")
	legacy.free()
	check(not FileAccess.file_exists(path+".tmp"),"successful saves leave no temporary file")
	for own_path: String in [path,corrupt,legacy_path]:
		check(DirAccess.remove_absolute(ProjectSettings.globalize_path(own_path)) == OK,"remove only newly created QA fixture")
