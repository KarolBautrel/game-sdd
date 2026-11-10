extends SceneTree
const F := preload("res://scripts/domain/life_campaign.gd")
var checks := 0
var failures: Array[String]=[]
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok: failures.append(text)
func _initialize() -> void:
	var s := F.initial(2087,"marches",2)
	check(s.life.sites.size()==2 and s.life.politics.outposts.size()==3,"real camp/ruin/fort families")
	var forest := F.dungeon(s,"road_camp");var ruins := F.dungeon(s,"blackroot_ruins")
	check(forest.generated_profile.theme=="forest" and ruins.generated_profile.theme=="dungeon" and forest.rooms[2].content[0].combat_encounter_path!=ruins.rooms[2].content[0].combat_encounter_path,"distinct supported exploration and tactical content")
	var early: Dictionary={}
	for i in range(45):
		var r := F.apply(s,F.R.command(s,"advance",{"ticks":192}));check(r.ok,"hands-off regions / "+r.reason)
		if not r.ok: break
		s=r.state
		if i==2: early=s.duplicate(true)
	check(s.life.regions.reports.size()==3 and s.life.regions.bulletins.size()==3,"daily distant district projections and received reports")
	check(s.life.regions.bulletins.riverlands.tick==s.strategy_world.core.tick-96,"messenger reports are dated, not live omniscience")
	check(s.life.regions.migrations.size()>0,"new occupations require actual finite travelling survivors")
	check(s.life.sites.road_camp.history.size()>1,"earlier clearing survives a new episode identity")
	check(s.life.regions.reserve.bandits>=0 and s.life.regions.reserve.ruins>=0,"no infinite raider source")
	check(s.mine.status=="occupied","global progress never silently resets or completes Old Mine")
	check(F.valid(JSON.parse_string(JSON.stringify(s,"",true,true))),"remote progress exact reload")
	var snapshot := s.duplicate(true)
	for i in range(10): F.dungeon(s,"road_camp");F.current(s);F.extras(s)
	check(F.R.Legacy.same_data(snapshot,s),"inspection/region lookup creates no actors or rewards")
	if not early.is_empty():
		check(early.life.regions.migrations.is_empty(),"no daily cleared-site reset")
	var broken := s.duplicate(true);broken.life.regions.reserve.bandits+=12
	check(not F.valid(broken),"no created migration strength")
	for f: String in failures: push_error(f)
	print("world_life_regions_tests: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
