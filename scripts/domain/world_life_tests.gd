extends SceneTree
const F := preload("res://scripts/domain/life_campaign.gd")
var checks := 0
var failures: Array[String]=[]
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok: failures.append(text)
func _initialize() -> void:
	var s := F.initial(2087,"marches",2)
	check(not s.is_empty(),"new independent v5 world")
	if not s.is_empty():
		var old := F.R.initial(2087,"marches",2)
		check(old.region==s.region and old.company==s.company,"legacy terrain/company unchanged")
		var signature: String=s.region.checksum
		for i in range(15):
			var r := F.apply(s,F.R.command(s,"advance",{"ticks":192}))
			check(r.ok,"hands-off two-day step / "+r.reason)
			if not r.ok: break
			s=r.state
		check(s.life.stats.resolved>0,"actual rival clears without company orders")
		check(s.life.stats.hired>0 and s.life.stats.fees>0 and s.life.stats.casualties>0,"actual paid strength commitment/losses")
		var phases := {}
		for e: Dictionary in s.life.events: phases[e.text]=true
		check(phases.size()>=6,"persistent causal warning/commission/journey/action/aftermath")
		check(s.life.sites.road_camp.history.size()>=1 and s.life.sites.road_camp.history.size()<=3,"finite occupations retain once-only clearing history")
		check(s.mine.status=="occupied" and s.region.checksum==signature,"mine and immutable terrain untouched")
		check(F.valid(JSON.parse_string(JSON.stringify(s,"",true,true))),"exact reload without advancing")
		var broken := s.duplicate(true);broken.life.actors.grey_lances.strength+=1
		check(not F.valid(broken),"no free NPC strength")
		broken=s.duplicate(true);broken.life.sites.road_camp.status="occupied"
		check(not F.valid(broken),"contradictory site rejects")
	for f: String in failures: push_error(f)
	print("world_life_tests: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
