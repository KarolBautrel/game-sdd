extends SceneTree
const F := preload("res://scripts/domain/life_campaign.gd")
const D := preload("res://scripts/domain/dungeon_state_model.gd")
const Session := preload("res://scripts/session/strategy_campaign_session.gd")
var checks := 0
var failures: Array[String]=[]
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok: failures.append(text)
func act(s: Dictionary, action: String, p: Dictionary={}) -> Dictionary:
	var r := F.apply(s,F.R.command(s,action,p));check(r.ok,action+" / "+r.reason);return r.state
func _initialize() -> void:
	var s := F.initial(2087,"marches",2)
	s=act(s,"advance",{"ticks":48})
	var id: String=s.life.sites.road_camp.episode
	s=act(s,"accept_life",{"id":id})
	var command := F.R.command(s,"accept_life",{"id":id})
	check(not F.apply(s,command).ok,"duplicate claim denied")
	var bad := F.apply(s,F.R.command(s,"course",{"site":"missing","position":{"x":.5,"y":.5}}))
	check(not bad.ok and F.R.Legacy.same_data(bad.state,s),"failed regional request returns the whole original v5 state")
	var expired := s.duplicate(true)
	for i in range(3): expired=act(expired,"advance",{"ticks":160})
	check(expired.life.episodes[id].contract.status=="offered","unfinished exclusivity expires with warning")
	s=act(s,"course",{"site":"road_camp","position":s.life.sites.road_camp.position})
	for i in range(60):
		if s.travel.path.is_empty(): break
		s=act(s,"advance",{"ticks":1})
	check(F.current(s)=="road_camp","terrain-safe arrival at actual camp")
	var data := F.dungeon(s,"road_camp")
	var run := D.initial_state(data)
	s=act(s,"begin_run",{"data":data,"state":run})
	check(s.run_context.site=="road_camp" and s.company.active_run.data.generated_profile.theme=="forest","owned actual forest expedition")
	var before: int=s.strategy_world.core.tick
	var moved := D.enter_room(data,s.company.active_run.state,"watchfire")
	check(moved.status=="accepted","ordinary room transition")
	s=act(s,"checkpoint",{"data":data,"state":moved.state,"seed":1})
	check(s.strategy_world.core.tick==before+1,"managed expedition advances world once")
	check(F.valid(JSON.parse_string(JSON.stringify(s,"",true,true))),"active camp reload")
	var mutated := data.duplicate(true);mutated.hazard_seed+=1
	check(not F.apply(s,F.R.command(s,"checkpoint",{"data":mutated,"state":moved.state,"seed":1})).ok,"layout reroll rejected")
	# Protection at the deadline is tested against the real per-tick hook; no fake clock.
	var regional := F.base(s);var life: Dictionary=s.life.duplicate(true)
	for i in range(3):
		var r := F.R._advance(regional,192,true,{},Callable(),func(value): F.L.tick(value,life))
		check(r=="","inside time authority")
	check(life.episodes[id].contract.status=="company","active owned run protects deadline")
	var session := Session.new()
	check(session.create_life(42,"",true,"marches",2),"session version5 create")
	check(session.regional("advance",{"ticks":48}),"session dispatches life hook")
	var path := "user://qa_strategy_world_life_atomic_%d.json" % Time.get_ticks_usec()
	var disk := Session.new();check(disk.create_life(42,path,false,"marches",2),"separate disk profile")
	var saved := disk.state.duplicate(true)
	var blocker := ProjectSettings.globalize_path(path+".tmp")
	DirAccess.make_dir_absolute(blocker)
	check(not disk.regional("advance",{"ticks":48}) and disk.state==saved,"failed save rolls back whole episode and ledger")
	DirAccess.remove_absolute(blocker)
	check(disk.regional("advance",{"ticks":48}),"retry applies once")
	var reload := Session.new();check(reload.load_profile(path) and F.R.Legacy.same_data(reload.state,disk.state),"disk exact reload")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for f: String in failures: push_error(f)
	print("world_life_contract_tests: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
