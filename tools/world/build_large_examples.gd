extends SceneTree
const Gen:=preload("res://scripts/domain/region_generator.gd")
const Campaign:=preload("res://scripts/session/campaign_session.gd")
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://resources/data/large_regions")
	for preset: String in Gen.PRESETS:
		var started:=Time.get_ticks_msec()
		var snapshot:=Gen.generate(2087,preset,2)
		if snapshot.is_empty(): push_error(Gen.last_error);quit(1);return
		var file:=FileAccess.open("res://resources/data/large_regions/%s_2087.json" % preset,FileAccess.WRITE)
		file.store_string(JSON.stringify(snapshot,"\t",true,true)+"\n");file.close()
		print(preset," generated384x216, attempt=",snapshot.attempt," in_ms=",Time.get_ticks_msec()-started)
		if preset=="marches":
			var campaign:=Campaign.new();campaign.load_profile("",true)
			if not campaign.enable_generated_region(2087,preset,2): push_error(campaign.last_feedback);quit(1);return
			var profile:=FileAccess.open("res://tests/data/generated_profiles/large_marches_2087.json",FileAccess.WRITE)
			profile.store_string(JSON.stringify(campaign.state,"\t",true,true)+"\n");profile.close();campaign.free()
	quit(0)
