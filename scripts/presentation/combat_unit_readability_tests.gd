extends SceneTree

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)


func _run() -> void:
	var scene: Control = load("res://scenes/combat/CombatDebug.tscn").instantiate()
	root.add_child(scene)
	for frame in range(8):
		await process_frame
	var active: Dictionary = scene._unit_by_id(scene.state.turn_state.active_unit_id)
	_check(scene.overlay_resource_label.visible, "S9-01 active identity is hidden")
	_check(scene.overlay_resource_label.text.contains(scene._unit_display_name(active.id)), "S9-01 identity does not name active unit")
	var before: Dictionary = scene.state.duplicate(true)
	for key in ["hp", "ap", "mp"]:
		var bar: TextureProgressBar = scene.overlay_resource_bars[key]
		var label := bar.get_node_or_null("AmountLabel") as Label
		_check(label != null and label.text.contains(str(int(active.resources[key]))), "S9-01 numeric " + key + " missing")
		_check(bar.size.y>=36 and bar.get_parent().get_global_rect().grow(1).encloses(bar.get_global_rect()), "S9-01 resource meter is readable and fits its panel")
		_check(bar.mouse_filter == Control.MOUSE_FILTER_IGNORE, "S9-01 bar steals input")
	scene._set_resource_override(active.id, "hp", 1)
	scene._set_resource_override(active.id, "ap", 0)
	scene._refresh_resource_display(active.id)
	_check(scene.overlay_resource_bars.hp.value == 1 and scene.overlay_resource_bars.ap.value == 0, "S9-02 override not reflected in fill")
	var hp_label := scene.overlay_resource_bars.hp.get_node_or_null("AmountLabel") as Label
	_check(hp_label != null and hp_label.text.contains("1 /"), "S9-02 override not reflected in numeric label")
	_check(scene.state == before, "S9-02 presentation changed domain state")
	var normal: StyleBoxFlat = scene._unit_resource_style(active)
	if scene.has_method("_set_hovered_unit"):
		scene._set_hovered_unit(active.id)
		var hovered: StyleBoxFlat = scene._unit_resource_style(active)
		_check(hovered.bg_color != normal.bg_color, "S9-03 active hover is invisible")
		_check(hovered.border_color == normal.border_color, "S9-03 active gold lost on hover")
		scene._set_hovered_unit("")
		_check(scene._unit_resource_style(active).bg_color == normal.bg_color, "S9-03 hover did not clear")
	else:
		_check(false, "S9-03 hover support missing")
	scene.temporary_resource_overrides.clear()
	var healthy: StyleBoxFlat = scene._unit_resource_style(active)
	_check(healthy.bg_color != normal.bg_color, "S9-03 wounded backing not distinguished")
	var enemy: Dictionary = {}
	for unit: Dictionary in scene.state.units:
		if unit.team != "player":
			enemy = unit
			break
	_check(not enemy.is_empty(), "S9 fixture has no enemy")
	var old_active: String = scene.state.turn_state.active_unit_id
	scene.state.turn_state.active_unit_id = enemy.id
	scene._render_board_overlay()
	_check(scene.overlay_resource_label.text.contains(scene._unit_display_name(enemy.id)), "S9-01 active switch retained stale identity")
	scene.state.turn_state.active_unit_id = old_active
	enemy.resources.hp = 0
	enemy.statuses = [{"id":"bleeding","remaining_turns":2}]
	scene._render()
	for frame in range(3):
		await process_frame
	var node: Control = scene.unit_layer.get_node(NodePath(enemy.id))
	_check(not node.get_node("ResourcePanel").visible, "S9-03 corpse shows living resource panel")
	_check(not node.get_node("StatusIconRow").visible, "S9-03 corpse shows living status row")
	_check(scene._tile_tooltip(enemy.position).contains("HP 0/"), "S9-03 corpse tooltip lacks actual HP")
	var invalid := active.duplicate(true)
	invalid.visual = {"faction":"missing-test","character":"missing-test"}
	var original := invalid.duplicate(true)
	var art = load("res://scripts/presentation/combat/combat_unit_art.gd").new()
	var first: Texture2D = art.icon(invalid, scene.state, {}, {}, Vector2i(384,240))
	var second: Texture2D = art.icon(invalid, scene.state, {}, {}, Vector2i(384,240))
	_check(first != null and second == first, "S9-04 missing art has no cached emergency fallback")
	_check(invalid == original, "S9-04 fallback changed unit config")
	scene.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("combat_unit_readability_tests: %s checks, %s failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
