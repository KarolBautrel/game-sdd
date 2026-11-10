extends SceneTree
const M := preload("res://scripts/domain/strategist_campaign.gd")
func save(path: String, value: Variant) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(value,"\t",true,true)+"\n");file.close();return true
func _initialize() -> void:
	var start := Time.get_ticks_msec()
	var s := M.initial(2087,"marches",3)
	if s.is_empty(): push_error("Vast generation failed: "+M.R.G.Gen.last_error);quit(1);return
	print("VAST_INITIAL_MS ",Time.get_ticks_msec()-start)
	var ok := save("res://resources/data/vast_regions/marches_2087.json",s.region.base) and save("res://resources/data/strategic_regions/vast_2087.json",M.regional(s)) and save("res://resources/data/strategist_campaigns/vast_2087.json",s)
	print("vast_fixture_export: ",ok," / ",s.region.base.terrain.width,"x",s.region.base.terrain.height)
	quit(0 if ok else 1)
