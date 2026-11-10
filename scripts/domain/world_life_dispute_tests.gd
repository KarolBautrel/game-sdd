extends SceneTree
const F := preload("res://scripts/domain/life_campaign.gd")
var checks := 0
var failures: Array[String]=[]
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok: failures.append(text)
func _initialize() -> void:
	var s := F.initial(2087,"marches",2)
	for i in range(12):
		var result := F.apply(s,F.R.command(s,"advance",{"ticks":96}));check(result.ok,"dispute / "+result.reason)
		if not result.ok: break
		s=result.state
	check(not s.life.politics.dispute.is_empty(),"actual supply shortage creates diplomatic proposal")
	check(s.strategy_world.metrics.wars>0,"refusal and affordable actual mobilization can lead to legal war")
	check(not s.life.politics.campaigns.is_empty(),"war creates an actual warned outpost response")
	check(F.valid(s),"ordinary diplomacy/force/garrison ledgers remain valid")
	# A funded accepted agreement protects the same opening, using ordinary operators.
	var protected := F.initial(2087,"marches",2)
	var world: Dictionary=protected.strategy_world;var id := F.R.C.S.next_id(world,"pact")
	check(F.R.C._operate(world,"iron_march","propose_pact",{"id":id,"target":"river_league","kind":"nonaggression","duration_ticks":1344,"valid_for_ticks":96})=="","real offer")
	check(F.R.C._operate(world,"river_league","accept_pact",{"id":id})=="","real accepted settlement")
	for i in range(8):
		var result := F.apply(protected,F.R.command(protected,"advance",{"ticks":96}));check(result.ok,"protected clock");protected=result.state
	check(protected.life.politics.dispute.is_empty() and protected.strategy_world.metrics.wars==0,"active agreement prevents compulsory crisis/war")
	for f: String in failures: push_error(f)
	print("world_life_dispute_tests: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
