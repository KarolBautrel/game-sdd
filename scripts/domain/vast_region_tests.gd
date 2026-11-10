extends SceneTree
const M := preload("res://scripts/domain/strategist_campaign.gd")
const G := M.R.G
const Gen := G.Gen
const Living := preload("res://scripts/domain/living_world.gd")
const Camera := preload("res://scripts/presentation/world/map_camera.gd")
var checks := 0
var failures: Array[String]=[]
var timings: Array=[]
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label);print("FAIL: ",label)
func _initialize() -> void:
	var signatures := {}
	for item: Array in [[2087,"marches"],[42,"woodland"],[20261107,"highlands"]]:
		var start := Time.get_ticks_msec();var world := M.R.C.initial(item[0]);var binding := G.build(world.core,item[1],3)
		check(not binding.is_empty(),"Vast seed/preset generation "+str(item))
		if binding.is_empty(): continue
		var geo: Dictionary=binding.base
		check(binding.sites.size()==9 and binding.routes.size()==7 and G.valid(binding),"all strategic anchors and actual routes fit each Vast biome")
		timings.append({"seed":item[0],"preset":item[1],"generation_ms":Time.get_ticks_msec()-start})
		check(Gen.errors(geo).is_empty() and geo.terrain.width==768 and geo.terrain.height==432,"four times Large area with validated topology")
		check(geo.climates.size()==3 and geo.bridges.size()>=2 and geo.sites.size()==6,"real biome/crossing/anchor data")
		check(M.R.Legacy.same_data(geo,JSON.parse_string(JSON.stringify(geo,"",true,true))),"exact immutable Vast JSON snapshot")
		signatures[geo.checksum]=true
	check(signatures.size()==3,"Vast seeds/presets materially change geography")
	for folder: String in ["res://resources/data/generated_regions","res://resources/data/large_regions"]:
		for file: String in DirAccess.get_files_at(folder):
			if not file.ends_with(".json"): continue
			var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"/"+file))
			check(Gen.generate(int(prior.seed),prior.preset,int(prior.version)).checksum==prior.checksum,"old v1/v2 reference checksum stays unchanged / "+file)
	var s := M.initial(2087,"marches",3);check(M.valid(s),"terrain-bound Vast campaign")
	for edge: Dictionary in s.region.routes.values():
		check(edge.ticks==ceili(edge.cost/.0035),"Vast actual caravan weights use doubled physical distance")
		for progress: float in [0.0,.25,.5,.75,1.0]:
			check(Gen.navigation(s.region.base).passable(G.on_edge(s.region,edge.a,edge.b,progress)) and Gen.navigation(s.region.base).passable(G.on_edge(s.region,edge.b,edge.a,progress)),"both directions follow passable actual terrain")
	check(G.world_scale(s.region)==4 and Living.travel_scale({"geography":s.region.base})==4,"company/NPC integrations agree on physical scale")
	var ordered := M.apply(s,M.command(s,"course",{"position":s.region.sites.dungeon_old_mine.position,"site":"dungeon_old_mine"}))
	check(ordered.ok,"actual company route on Vast terrain")
	var step := M.apply(ordered.state,M.command(ordered.state,"advance",{"ticks":1}))
	check(step.ok and absf(step.motion.budget-.01125)<.0000001,"same local physical pace uses half the normalized budget")
	check(M.valid(JSON.parse_string(JSON.stringify(step.state,"",true,true))),"moving Vast state roundtrips exactly")
	var old := Camera.new();var vast := Camera.new();old.configure_world(2);vast.configure_world(4)
	old.focus(Vector2(.5,.5),Vector2(1000,600));vast.focus(Vector2(.5,.5),Vector2(1000,600))
	check(old.zoom==2.6 and vast.zoom==5.2 and vast.max_zoom==9,"scale-aware camera preserves old zoom and native detail size")
	var a := old.visible_world(Vector2(1000,600));var b := vast.visible_world(Vector2(1000,600))
	check(absf(b.get_area()*4-a.get_area())<.000001,"Vast local view covers a quarter as much world")
	vast.overview(Vector2(1000,600));check(vast.zoom==1,"overview remains an explicit whole-world choice")
	var dir := "res://artifacts/qa-runs/vast-regions";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var output := FileAccess.open(dir+"/generation.json",FileAccess.WRITE)
	if output!=null: output.store_string(JSON.stringify(timings,"\t",true,true)+"\n");output.close()
	for failure: String in failures: push_error(failure)
	print("vast_region_tests: %d checks, %d failures" % [checks,failures.size()]);quit(0 if failures.is_empty() else 1)
