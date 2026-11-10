extends SceneTree
const R := preload("res://scripts/domain/strategic_region.gd")
var checks := 0
var failures: Array[String]=[]
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label);print("FAIL: ",label)
func _initialize() -> void:
	var s := R.initial(2087)
	check(not s.is_empty(),"fresh terrain-bound campaign")
	if not s.is_empty():
		check(R.valid(s) and s.region.sites.size()==9 and s.jobs.size()>=3,"terrain binding and funded causes validate")
		for e: Dictionary in s.region.routes.values():
			for fraction in range(11):
				var p := R.G.on_edge(s.region,e.a,e.b,fraction/10.0)
				check(R.G.Gen.navigation(s.region.base).passable(p),"edge interpolation remains on passable terrain")
				var reverse := R.G.on_edge(s.region,e.b,e.a,fraction/10.0)
				check(R.G.Gen.navigation(s.region.base).passable(reverse),"reverse interpolation remains passable")
			for progress: float in [.25,.5,.75]:
				for backwards: bool in [false,true]:
					var points: Array=e.points.duplicate(true)
					if backwards: points.reverse()
					var unit := {"position":points.pop_front()}
					R.G.Gen.navigation(s.region.base).walk(unit,points,progress*float(e.cost))
					var actual := R.G.on_edge(s.region,e.b if backwards else e.a,e.a if backwards else e.b,progress)
					check(actual.distance_to(R.G.point(unit.position))<.000002,"cached cost sampling matches full terrain integration")
		var broken := s.duplicate(true);broken.region.base.checksum="0".repeat(64)
		check(not R.valid(broken),"cached outer checksum cannot hide a corrupt inner checksum")
		broken=s.duplicate(true);broken.strategy_world.core.routes.river_road.travel_ticks+=1
		check(not R.valid(broken),"clock weight must match physical route")
		broken=s.duplicate(true);broken.current_settlement_id="ashmere"
		check(not R.valid(broken),"stored location cannot overrule actual stopped position")
		broken=s.duplicate(true);broken.company.version=true
		check(not R.valid(broken),"boolean company version rejects without a script error")
		var edge: Dictionary=s.region.routes.values()[0]
		var start := Time.get_ticks_usec()
		for i in range(1000): R.G.on_edge(s.region,edge.a,edge.b,(i%100)/100.0)
		print("STRATEGIC_PATH_QUERY_1000_MS ",(Time.get_ticks_usec()-start)/1000.0)
		var signatures := {}
		for seed_value: int in [42,2087,170717]:
			for preset: String in R.G.Gen.PRESETS:
				var world := R.C.initial(seed_value)
				var geography := R.G.build(world.core,preset)
				check(not geography.is_empty() and R.G.valid(geography),"nine-anchor terrain binding / "+str(seed_value)+" / "+preset)
				if geography.is_empty(): continue
				check(R.Legacy.same_data(geography,JSON.parse_string(JSON.stringify(geography,"",true,true))),"exact geography roundtrip across presets")
				signatures[geography.checksum]=true
		check(signatures.size()==9,"seed/preset materially change the physical region")
	for failure: String in failures: push_error(failure)
	print("strategic_region_tests: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
