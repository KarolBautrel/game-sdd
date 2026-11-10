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
	# Own the fixture rather than inherit a manual review's launcher override.
	scene.selected_scenario_id = "full_combat_showcase"
	scene._load_selected_scenario()
	await process_frame
	scene._show_action_hover("basic_attack", 1)
	_check(scene.action_detail_label.text.contains("COST 1 AP"), "S10-01 profile AP cost missing")
	scene._show_action_hover("move", 2)
	_check(scene.action_detail_label.text.contains("MP"), "S10-01 destination movement cost missing")
	var active: Dictionary = scene._unit_by_id(scene.state.turn_state.active_unit_id)
	scene._set_resource_override(active.id, "ap", 0)
	scene._render_status()
	scene._show_action_hover("defend", 3)
	_check(scene.action_detail_label.text.contains("AP 0/"), "S10-01 hover uses stale AP")
	_check(scene.status_label.text.contains("AP 0/"), "S10-01 status uses stale AP")
	scene.temporary_resource_overrides.clear()
	active.resources.ap = 0
	var before: Array = scene.state.units.duplicate(true)
	scene._run_command(scene._build_command("defend", {}))
	_check(scene.current_action_title == "Action rejected", "S10-02 rejection title missing")
	_check(scene.action_feed[0].contains("not enough AP"), "S10-02 feed loses reason")
	_check(scene.state.units == before, "S10-02 rejected command spent resources")
	_check(scene.floating_text_layer.get_child_count() == 0, "S10-02 rejection spawned damage text")
	active = scene._unit_by_id(scene.state.turn_state.active_unit_id)
	active.position = {"x":0,"y":0}
	scene.selected_action = "basic_attack"
	scene.target_preview_cache = {"0,0":{"rejection":"","guaranteed_hit":true,"damage":3,"ap_cost":1}}
	var profiles: Array=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/presentation/original_roster.json")).characters
	for profile: Dictionary in profiles:
		active.visual={"faction":"original","character":profile.id}
		scene.selected_action="basic_attack"
		scene.target_preview_cache={"0,0":{"rejection":"","guaranteed_hit":true,"damage":3,"ap_cost":1}}
		scene._render_units()
		scene._resize_board()
		for frame in range(3):
			await process_frame
		var node: Control = scene.unit_layer.get_node(NodePath(active.id))
		var resource := node.get_node("ResourcePanel") as Control
		var preview := node.get_node("TargetPreviewPanel") as Control
		_check(preview.visible, "S10-03 target preview hidden: %s action=%s pos=%s cache=%s" % [profile.id,scene.selected_action,active.position,scene.target_preview_cache])
		_check(preview.position.y+preview.size.y <= resource.position.y, "S10-03 preview clears resources above actor: "+str(profile.id))
		var board_bounds: Rect2=scene.board_viewport.get_global_rect().grow(1)
		_check(board_bounds.encloses(resource.get_global_rect()), "S10-03 resource readout outside visible board/headroom")
		_check(board_bounds.encloses(preview.get_global_rect()), "S10-03 target preview outside visible board/headroom: %s in %s" % [preview.get_global_rect(),board_bounds])
		_check(resource.position.y+resource.size.y<scene.unit_art.idle_top(active,scene.UNIT_ICON_SIZE),"S10-03 labels clear actor silhouette")
		var label := preview.get_node("TargetPreview") as Label
		_check(preview.get_global_rect().grow(1).encloses(label.get_global_rect()), "S10-03 preview text outside padded frame")
	for winning_team in ["player", "enemy"]:
		scene._reset_debug_encounter()
		var hero: Dictionary = scene._unit_by_id("unit_player_001").duplicate(true)
		var enemy: Dictionary = {}
		for unit: Dictionary in scene.state.units:
			if unit.team == "enemy":
				enemy = unit.duplicate(true)
				break
		hero.position = {"x":0,"y":0}
		enemy.position = {"x":1,"y":0}
		var attacker: Dictionary = hero if winning_team == "player" else enemy
		var target: Dictionary = enemy if winning_team == "player" else hero
		attacker.stats.strength = 100
		attacker.resources.ap = 2
		attacker.loadout = {"main_hand":"hero_sword"}
		attacker.available_actions = ["move","basic_attack","end_turn"]
		target.resources.hp = 1
		target.statuses = []
		scene.state.units = [hero, enemy]
		scene.state.turn_state.active_unit_id = attacker.id
		scene.state.turn_state.turn_order = [attacker.id, target.id]
		scene._prepare_presentation_cache()
		scene._render()
		scene._run_command(scene._build_command("basic_attack", {"type":"unit","unit_id":target.id}))
		if scene.animation_locked:
			_check(scene.action_title_label.text not in ["Victory","Defeat"], "S10-04 result shown before animated commit")
		var animation_deadline := Time.get_ticks_msec() + 6000
		while scene.animation_locked and Time.get_ticks_msec() < animation_deadline:
			await process_frame
		var expected := "Victory" if winning_team == "player" else "Defeat"
		_check(scene.action_title_label.text == expected, "S10-04 normal resolver outcome not shown: " + expected)
		scene._show_action_hover("move", 1)
		_check(scene.action_title_label.text == expected, "S10-04 terminal banner overwritten by hover")
		_check(not scene.animation_locked, "S10-04 input stuck after final attack")
	scene.authoring_draft = {"id":"isolated_feedback_fixture"}
	scene._render_action_panel()
	_check(scene.action_detail_label.text.contains("F6"), "S10-04 authoring result gives wrong return instructions")
	scene.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("combat_feedback_polish_tests: %s checks, %s failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
