extends SceneTree
const Gen:=preload("res://scripts/domain/region_generator.gd")
const World:=preload("res://scripts/domain/living_world.gd")
const Campaign:=preload("res://scripts/session/campaign_session.gd")
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://resources/data/generated_regions")
	for preset: String in Gen.PRESETS:
		var snapshot:=Gen.generate(2087,preset)
		if snapshot.is_empty(): push_error(Gen.last_error);quit(1);return
		var file:=FileAccess.open("res://resources/data/generated_regions/%s_2087.json" % preset,FileAccess.WRITE)
		file.store_string(JSON.stringify(snapshot,"\t",true,true)+"\n");file.close()
		if preset=="marches":
			DirAccess.make_dir_recursive_absolute("res://tests/data/generated_profiles")
			var profile:=Campaign.initial_profile();profile.living_world=World.initial(2087,0,snapshot)
			var profile_file:=FileAccess.open("res://tests/data/generated_profiles/marches_2087.json",FileAccess.WRITE)
			profile_file.store_string(JSON.stringify(profile,"\t",true,true)+"\n");profile_file.close()
	print("Exported three deterministic geography schema examples; authored terrain untouched.")
	quit(0)
