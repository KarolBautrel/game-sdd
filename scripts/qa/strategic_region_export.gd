extends SceneTree
## Explicit reproducible reference export; no player save/UI access.
const R := preload("res://scripts/domain/strategic_region.gd")
func _initialize() -> void:
	var state := R.initial(2087)
	if not R.valid(state): quit(1);return
	var directory := "res://resources/data/strategic_regions"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file := FileAccess.open(directory+"/reference_2087.json",FileAccess.WRITE)
	if file==null: quit(1);return
	file.store_string(JSON.stringify(state,"  ",true,true)+"\n");file.close()
	print("Exported validated strategic region2087 reference.");quit(0)
