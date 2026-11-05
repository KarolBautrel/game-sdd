extends SceneTree
const Gen:=preload("res://scripts/domain/region_generator.gd")
const World:=preload("res://scripts/domain/living_world.gd")
const Terrain:=preload("res://scripts/domain/terrain_navigation.gd")
const Campaign:=preload("res://scripts/session/campaign_session.gd")
var checks:=0
var failures: Array[String]=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func run() -> void:
	var authored:=FileAccess.get_file_as_string(Terrain.PATH)
	var fingerprints: Dictionary={}
	var max_ms:=0
	for preset: String in Gen.PRESETS:
		var frozen: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/generated_regions/%s_2087.json" % preset))
		check(Gen.generate(2087,preset,1).checksum==frozen.checksum,"v1 algorithm matches frozen stage80 checksum: "+preset)
		for seed_value: int in [42,2087,170717,172711,175702,190657,999999999,1]:
			var started:=Time.get_ticks_msec()
			var geo:=Gen.generate(seed_value,preset,2);max_ms=maxi(max_ms,Time.get_ticks_msec()-started)
			check(not geo.is_empty(),"large %s/%s generated: %s" % [preset,seed_value,Gen.last_error])
			if geo.is_empty(): continue
			check(Gen.errors(geo).is_empty() and int(geo.terrain.width)==384 and int(geo.terrain.height)==216,"large topology/area/crossings/roads validation")
			check(Gen.errors(JSON.parse_string(JSON.stringify(geo,"",true,true))).is_empty(),"large snapshot exact JSON checksum reload")
			check(geo.climates.size()==3 and geo.climates[0].position!=geo.climates[1].position,"distinct coherent climate centers")
			var totals: Dictionary={}
			for row: String in geo.terrain.rows:
				for code in row: totals[code]=int(totals.get(code,0))+1
			check(int(totals.get("F",0))>1000 and int(totals.get("P",0))>1000 and int(totals.get("H",0))+int(totals.get("M",0))>1000,"forest/open-country/upland coexist in large region")
			fingerprints[geo.checksum]=true
	check(fingerprints.size()==24 and max_ms<10000,"24 materially distinct bounded large layouts; max_ms=%d" % max_ms)
	var geo:=Gen.generate(2087,"marches",2)
	var saved_hash: String=geo.checksum;Gen.snapshots.clear()
	check(Gen.generate(2087,"marches",2).checksum==saved_hash,"large cold replay independent of cache/history")
	var bad:=geo.duplicate(true);bad.climates[0].radius=-1;bad.checksum=Gen.checksum(bad)
	check(not Gen.errors(bad).is_empty(),"invalid climate zone rejected even after rechecksum")
	bad=geo.duplicate(true);bad.version=1;bad.checksum=Gen.checksum(bad)
	check(not Gen.errors(bad).is_empty(),"large terrain cannot masquerade as classic")
	var campaign:=Campaign.new();campaign.load_profile("",true)
	check(campaign.enable_generated_region(2087,"marches",2),"large generated profile initialized by campaign owner")
	check(World.travel_scale(campaign.state.living_world)==2 and campaign.living_course(Vector2.ZERO,"saltwatch"),"large world physical travel scale and genuine course")
	var motion: Dictionary={}
	var unit: Dictionary=campaign.state.living_world.party.duplicate(true)
	var path: Array=unit.path.duplicate(true)
	World._walk(unit,path,.045,motion,campaign.state.living_world)
	check(float(motion.samples.back().cost)<=.0450001 and float(motion.remaining)>=0,"scaled walk trace uses physical budget units")
	check(campaign.advance_living() and not campaign.living_motion.is_empty(),"large campaign publishes committed movement trace")
	var samples: Array=campaign.living_motion.units.company
	check(float(samples[0].time)==0 and float(samples.back().time)==1,"scaled trace spans one normalized simulation tick")
	check(campaign.state.living_world.geography.checksum==saved_hash,"travel preserves immutable large snapshot")
	check(FileAccess.get_file_as_string(Terrain.PATH)==authored,"large generation/travel leaves authored r9 byte-identical")
	campaign.free()
	print("Large batch24inputs max_ms=",max_ms)
	for failure in failures: push_error(failure)
	print("large_region_tests: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
