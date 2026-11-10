extends SceneTree
const F := preload("res://scripts/domain/life_campaign.gd")
var checks := 0
var failures: Array[String]=[]
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok: failures.append(text)
func step(s: Dictionary, ticks: int) -> Dictionary:
	var r := F.apply(s,F.R.command(s,"advance",{"ticks":ticks}));check(r.ok,"politics advance / "+r.reason);return r.state
func _initialize() -> void:
	var s := F.initial(2087,"marches",2)
	var peaceful := step(s,96)
	check(peaceful.life.politics.campaigns.is_empty(),"no scheduled compulsory war/capture")
	# Legal classic aid-war operator creates the fixture's existing war; no winner edit.
	check(F.R.C._war(s.strategy_world,"iron_march","river_league","pass_road",true)=="","classic war fixture has a legal ready force and costs")
	check(F.valid(s),"existing war fixture is a valid canonical state")
	for i in range(8): s=step(s,96)
	check(not s.life.politics.campaigns.is_empty(),"existing war funds actual outpost campaign")
	var ended := 0
	for c: Dictionary in s.life.politics.campaigns.values():
		if c.status in ["occupied","repelled","cancelled"]: ended+=1
	check(ended>0,"bounded campaign reaches a supported outcome")
	check(s.life.stats.fees>=20 and F.valid(s),"fees and finite guard/actor accounting remain valid")
	check(F.valid(JSON.parse_string(JSON.stringify(s,"",true,true))),"occupation/recovery roundtrip")
	var broken := s.duplicate(true);broken.life.politics.outposts.river_watch.garrison+=1
	check(not F.valid(broken),"no free garrison")
	# Freeze the fixture planner only while proving a complete war-time assault.
	s=F.initial(42,"marches",2)
	check(F.R.C._war(s.strategy_world,"iron_march","river_league","pass_road",true)=="","second legal war opening")
	var l: Dictionary=s.life;var regional := F.base(s)
	for i in range(8):
		var error := F.R._advance(regional,96,false,{},func(kind,_observations): return {"iron_march":[],"river_league":[],"cinder_compact":[],"thornwood_accord":[]} if kind=="intents" else {},func(value): F.L.tick(value,l))
		check(error=="","fixture campaign physical progression")
	regional.version=5;regional.life=l;s=regional
	check(F.valid(s),"actual assault and transfers preserve invariants")
	check(s.life.politics.captures>0,"finite hired company takes defended outpost after travel and clash")
	var locked := false
	for post: Dictionary in s.life.politics.outposts.values():
		if not post.history.is_empty(): locked=locked or int(post.cooldown)>int(post.history.back().tick)
	check(locked,"occupation has a durable recovery/cooldown")
	for f: String in failures: push_error(f)
	print("world_life_politics_tests: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
