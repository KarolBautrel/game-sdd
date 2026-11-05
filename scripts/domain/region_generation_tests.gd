extends SceneTree
const Gen:=preload("res://scripts/domain/region_generator.gd")
const Terrain:=preload("res://scripts/domain/terrain_navigation.gd")
var checks:=0
var failures: Array[String]=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func run() -> void:
	var authored_bytes:=FileAccess.get_file_as_string(Terrain.PATH)
	var authored: RefCounted=Terrain.current()
	var fingerprints: Dictionary={}
	var replay_hashes: Dictionary={}
	var max_msec:=0
	var attempts: Dictionary={}
	for preset: String in Gen.PRESETS:
		for index in range(24):
			var seed_value: int=42 if index==0 else (2087 if index==1 else 170717+index*997)
			var start:=Time.get_ticks_msec()
			var geo:=Gen.generate(seed_value,preset)
			max_msec=maxi(max_msec,Time.get_ticks_msec()-start)
			check(not geo.is_empty(),"generated %s/%d: %s" % [preset,seed_value,Gen.last_error])
			if geo.is_empty(): continue
			check(Gen.errors(geo).is_empty(),"snapshot passes topology/road/bridge validation")
			var replay:=Gen.generate(seed_value,preset)
			check(geo==replay,"same seed/preset replays exact immutable snapshot")
			var loaded: Variant=JSON.parse_string(JSON.stringify(geo,"\t",true,true))
			check(Gen.errors(loaded).is_empty() and Gen.checksum(loaded)==geo.checksum,"JSON roundtrip preserves canonical checksum")
			fingerprints[geo.checksum]=true
			if seed_value==2087: replay_hashes[preset]=geo.checksum
			attempts[str(geo.attempt)]=int(attempts.get(str(geo.attempt),0))+1
			var nav: RefCounted=Gen.navigation(geo)
			var contexts:=true
			for site_index in range(geo.sites.size()):
				var point:=Vector2(float(geo.sites[site_index].position.x),float(geo.sites[site_index].position.y))
				contexts=contexts and nav.passable(point)
				for previous in range(site_index):
					var other:=Vector2(float(geo.sites[previous].position.x),float(geo.sites[previous].position.y))
					contexts=contexts and ((point-other)*Terrain.ASPECT).length()>.234
			check(contexts,"site separation and accessible placement")
			check(float(geo.diagnostics.connected_cells)/float(geo.diagnostics.land_cells)>=.75 and geo.bridges.size()>=2,"connected mainland/crossing coverage gate")
	check(fingerprints.size()==72,"all sampled seed/preset combinations materially differ")
	check(max_msec<5000,"bounded region generation time; max_ms=%d" % max_msec)
	Gen.snapshots.clear()
	for preset: String in Gen.PRESETS:
		check(Gen.generate(2087,preset).checksum==replay_hashes[preset],"cold deterministic regeneration independent of preview/cache history")
	var reference:=Gen.generate(2087,"marches")
	var before: String=reference.checksum
	reference.sites[0].name="Edited preview"
	check(Gen.generate(2087,"marches").checksum==before and not Gen.errors(reference).is_empty(),"cache is immutable and changed snapshot is rejected")
	var bad:=Gen.generate(2087,"marches");bad.version=999;bad.checksum=Gen.checksum(bad)
	check(not Gen.errors(bad).is_empty(),"unsupported generator snapshot rejected")
	bad=Gen.generate(2087,"marches");bad.road_paths[0][1]={"x":.001,"y":.001};bad.checksum=Gen.checksum(bad)
	check(not Gen.errors(bad).is_empty(),"rechecksummed road through blocked border rejected")
	bad=Gen.generate(2087,"marches");bad.bridges[0].position={"x":.001,"y":.001};bad.checksum=Gen.checksum(bad)
	check(not Gen.errors(bad).is_empty(),"rechecksummed false bridge rejected")
	check(Gen.generate(0).is_empty() and Gen.generate(1,"missing").is_empty() and Gen.generate(1,"marches",3).is_empty(),"invalid generator inputs refused")
	check(Terrain.current()==authored and FileAccess.get_file_as_string(Terrain.PATH)==authored_bytes,"preview batch never replaces authored navigation or designer bytes")
	print("Generator batch:72inputs, max_ms=",max_msec," attempts=",attempts)
	for failure in failures: push_error(failure)
	print("region_generation_tests: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
