extends SceneTree
## Repeatable explicit reference export, never a player save or automatic import.
const C := preload("res://scripts/domain/classic_world.gd")
func _initialize() -> void:
	var state := C.initial(2088)
	if not C.S.valid(state): quit(1);return
	var directory := "res://resources/data/strategy_snapshots"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file := FileAccess.open(directory+"/classic_opening_2088.json",FileAccess.WRITE)
	if file==null: quit(1);return
	file.store_string(JSON.stringify(state,"  ",true,true)+"\n");file.close()
	print("Exported validated classic opening2088 reference.");quit(0)
