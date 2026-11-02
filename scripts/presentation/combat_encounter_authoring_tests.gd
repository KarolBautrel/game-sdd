extends SceneTree

const Catalog := preload("res://scripts/presentation/combat/combat_scenario_catalog.gd")
const Draft := preload("res://scripts/presentation/combat/authoring_draft.gd")
var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)


func _run() -> void:
	var options := Catalog.options()
	_check(options.size() == 11, "S11-01 scenario count differs")
	options[0].label = "local change"
	_check(Catalog.options()[0].label != "local change", "S11-01 catalogue cache leaked mutation")
	_check(not Catalog.validation_errors(null).is_empty(), "S11-02 bad shape accepted")
	var first := Catalog.options()[0]
	_check(not Catalog.validation_errors({"schema":"sdd.combat-scenarios-v1","scenarios":[first,first]}).is_empty(), "S11-02 duplicate id accepted")
	var source := Catalog.path_for_id("clearing_crossfire")
	_check(not source.is_empty(), "S11-01 new scenario absent")
	var original := FileAccess.get_file_as_string(source)
	var scene: Control = load("res://scenes/combat/CombatDebug.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.selected_scenario_id = "clearing_crossfire"
	scene._load_selected_scenario()
	for frame in range(6):
		await process_frame
	_check(scene.state.id == "clearing_crossfire", "S11-03 controller did not load data-only scenario")
	_check(scene.state.grid.width == 12 and scene.state.grid.height == 10, "S11-03 referenced map not resolved")
	_check(scene.state.background_path.ends_with("old_mine_meadow_01_deep_green.png"), "S11-03 map visual default missing")
	_check(scene._unit_by_id("unit_enemy_001").loadout.main_hand == "raider_axe", "S11-03 archetype loadout missing")
	_check(scene._unit_by_id("unit_enemy_002").visual.character == "bandit_archer", "S11-03 ranged role visual missing")
	var mp: int = scene._unit_by_id("unit_player_001").resources.mp
	scene._on_tile_pressed({"x":1,"y":9})
	_check(scene.pending_move_position == {"x":1,"y":9}, "S11-03 first click did not preview")
	scene._on_tile_pressed({"x":1,"y":9})
	await create_timer(1.0).timeout
	_check(scene._unit_by_id("unit_player_001").position == {"x":1,"y":9}, "S11-03 ordinary move failed")
	_check(scene._unit_by_id("unit_player_001").resources.mp == mp - 1, "S11-03 wrong move resource result")
	scene.queue_free()
	await process_frame
	var editor: Control = load("res://scenes/combat/CombatMapEditor.tscn").instantiate()
	root.add_child(editor)
	await process_frame
	editor._load_encounter(source)
	_check(editor.grid_container.get_child_count() == 120 and editor.unit_option.item_count == 4, "S11-04 editor did not materialize map/roster")
	editor.selected_brush_mode = "Tile"
	editor.selected_tile_type = "cover_low"
	editor._apply_brush({"x":0,"y":0})
	var copy_path := "user://qa-stage11-%s.json" % Time.get_ticks_usec()
	editor._save_encounter(copy_path)
	editor._load_encounter(copy_path)
	_check(not editor.encounter.has("map_path") and Draft.errors(editor.encounter).is_empty(), "S11-04 saved draft invalid")
	_check(editor.encounter.grid.tiles[0].type == "cover_low", "S11-04 edit lost on reload")
	_check(FileAccess.get_file_as_string(source) == original, "S11-04 canonical source changed")
	editor.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(copy_path))
	for failure in failures:
		push_error(failure)
	print("combat_encounter_authoring_tests: %s checks, %s failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
