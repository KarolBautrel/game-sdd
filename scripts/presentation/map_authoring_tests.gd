extends SceneTree

const Draft := preload("res://scripts/presentation/combat/authoring_draft.gd")
const Resolver := preload("res://scripts/domain/combat_resolver.gd")


func _init() -> void:
	var failures: Array[String] = []
	var source := "res://resources/data/combat_encounters/debug_map_scale_showcase.json"
	var original := FileAccess.get_file_as_string(source)
	var input: Dictionary = JSON.parse_string(original)
	var draft := Draft.materialize(input)
	_check(failures, not draft.has("map_path") and draft.grid.width == 12, "materialized map")
	_check(failures, not input.has("grid"), "source object untouched")
	_check(failures, draft.terrain_decorations.size() == 1, "map decoration imported")
	var resolved: Dictionary = Resolver.simulate(input, []).state
	_check(failures, resolved.grid == draft.grid and resolved.terrain_decorations == draft.terrain_decorations, "runtime materialization parity")
	input["terrain_theme"] = "dungeon"
	_check(failures, Draft.materialize(input).terrain_theme == "dungeon", "encounter visual override")
	var scene := load("res://scenes/combat/CombatMapEditor.tscn") as PackedScene
	var editor := scene.instantiate()
	root.add_child(editor)
	await process_frame
	editor._load_encounter(source)
	_check(failures, editor.grid_container.get_child_count() == 120, "all cells visible")
	_check(failures, editor.unit_option.item_count == 3, "start choices populated")
	var preview: Control = editor.grid_container.get_child(25).get_child(0)
	_check(failures, preview.size.x <= 44 and preview.size.y <= 34, "decoration preview fits cell")
	editor.selected_brush_mode = "Tile"
	editor.selected_tile_type = "cover_low"
	editor._apply_brush({"x": 0, "y": 0})
	editor._set_decoration({"x": 0, "y": 0}, draft.terrain_decorations[0].path)
	editor.selected_brush_mode = "Unit start"
	editor.unit_option.select(0)
	editor._apply_brush({"x": 0, "y": 1})
	var copy_path := "user://stage4_authoring_test.json"
	editor._save_encounter(copy_path)
	var saved := FileAccess.get_file_as_string(copy_path)
	editor._load_encounter(copy_path)
	_check(failures, not editor.encounter.has("map_path"), "saved fork has one source of truth")
	_check(failures, editor._tile_type({"x": 0, "y": 0}) == "cover_low", "paint round trip")
	_check(failures, int(editor.encounter.units[0].position.x) == 0 and int(editor.encounter.units[0].position.y) == 1, "start round trip")
	_check(failures, editor.decoration_by_key.has("0,0"), "decoration round trip")
	editor.encounter.units[0].position = editor.encounter.units[1].position.duplicate()
	editor._save_encounter(copy_path)
	_check(failures, FileAccess.get_file_as_string(copy_path) == saved, "invalid save does not overwrite")
	_check(failures, not Draft.errors(editor.encounter).is_empty(), "overlap blocked")
	editor._play_draft()
	_check(failures, not has_meta(Draft.DRAFT_META), "invalid draft does not launch")
	editor.encounter.units[0].position = {"x": 1, "y": 2}
	_check(failures, not Draft.errors(editor.encounter).is_empty(), "blocked start rejected")
	_check(failures, FileAccess.get_file_as_string(source) == original, "load/edit never changes source")
	editor.queue_free()
	await process_frame
	var session := root.get_node("DungeonRunSession")
	var prior_request: Dictionary = session.pending_combat_request.duplicate(true)
	session.pending_combat_request = {"room_id": "draft_must_ignore", "combat_encounter_path": "missing"}
	set_meta(Draft.DRAFT_META, draft)
	var combat: Node = load("res://scenes/combat/CombatDebug.tscn").instantiate()
	root.add_child(combat)
	await process_frame
	_check(failures, not combat.authoring_draft.is_empty() and combat.state.grid.width == 12, "draft ignores pending dungeon launch")
	combat._return_to_dungeon()
	_check(failures, session.pending_combat_request.room_id == "draft_must_ignore", "draft cannot finish dungeon combat")
	session.pending_combat_request = prior_request
	combat.queue_free()
	await process_frame
	set_meta(Draft.DRAFT_META, draft)
	set_meta(Draft.PATH_META, copy_path)
	var returned := scene.instantiate()
	root.add_child(returned)
	await process_frame
	_check(failures, returned.path_edit.text == copy_path, "draft return preserves save destination")
	returned.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(copy_path))
	for failure in failures: push_error(failure)
	if failures.is_empty(): print("Map authoring v2 acceptance passed.")
	quit(0 if failures.is_empty() else 1)


func _check(failures: Array[String], condition: bool, label: String) -> void:
	if not condition: failures.append(label)
