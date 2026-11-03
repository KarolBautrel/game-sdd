extends SceneTree

const Art := preload("res://scripts/presentation/combat/combat_unit_art.gd")
const Catalog := preload("res://scripts/presentation/combat/combat_scenario_catalog.gd")
const Assets := preload("res://scripts/presentation/shared/asset_catalog.gd")
var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)


func _run() -> void:
	var art := Art.new()
	var unit := {"id": "raider_art_probe", "team": "enemy", "visual": {"faction": "villains", "character": "ash_raider"}}
	var directions := ["south", "south_west", "west", "north_west", "north", "north_east", "east", "south_east"]
	var counts := {"pose": 4, "walk": 8, "combat": 8, "hit": 4, "death": 8}
	var unique_directions: Dictionary = {}
	for direction: String in directions:
		for action: String in counts:
			var hashes: Dictionary = {}
			check(art.processed_sheet_frame_count("ash_raider", action) == counts[action], "authored action count")
			for frame: int in range(counts[action]):
				var path := art.processed_sheet_texture_path("ash_raider", direction, "%s:%s" % [action, frame])
				check(path.contains("ash_raider_%s_%s_" % [direction, action]), "real direction path")
				var image := Assets.image_copy(path)
				check(image != null and image.get_size() == Vector2i(512, 384), "fixed canvas exists: " + path)
				if image == null:
					continue
				var used := image.get_used_rect()
				check(not used.has_area() or (used.position.x > 0 and used.position.y > 0 and used.end.x < 512 and used.end.y < 384), "no clipped actor/weapon: " + path)
				check(used.has_area() and image.get_pixel(0, 0).a == 0, "nonempty transparent sprite")
				var digest := image.get_data().hex_encode().sha256_text()
				hashes[digest] = true
				if action == "pose" and frame == 0:
					unique_directions[digest] = true
			check(hashes.size() > 1, "action contains changing poses: " + direction + action)
	check(unique_directions.size() == 8, "eight genuinely distinct views")
	check(art.processed_sheet_corpse_visual_action("ash_raider") == "death:7", "hold terminal authored death pose")
	check(art.processed_sheet_texture_path("ash_raider", "east", "combat_idle:1") == art.processed_sheet_texture_path("ash_raider", "east", "pose:1"), "combat idle alias")
	check(art.sprite_size(unit, Vector2i(384, 240)) == Vector2i(512, 384), "overflow canvas kept at native resolution")
	check(art.sprite_offset(unit, Vector2i(384, 240)) + Vector2(256, 282) == Vector2(192, 240), "source ground pivot matches existing board anchor")
	check(7 * art.frame_seconds(unit, "combat", 0.09) < 0.56, "complete attack fits authoritative visual window")
	check(art.frame_seconds({"id":"unit_player_001","team":"player"}, "walk", 0.11) == 0.065, "shared original motion timing")
	check(art.processed_sheet_texture_path("warrior", "north_west", "pose").contains("warrior_north_west_pose_000.png"), "legacy ID resolves original directional model")
	check(Catalog.path_for_id("ash_road_raiders") != "", "new scenario selectable")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	root.add_child(viewport)
	var hud: Control = load("res://scenes/combat/CombatDebug.tscn").instantiate()
	viewport.add_child(hud)
	for index in range(4):
		await process_frame
	hud.current_encounter_path = Catalog.path_for_id("ash_road_raiders")
	hud._reset_debug_encounter()
	for index in range(3):
		await process_frame
	var snapshot: Dictionary = hud.state.duplicate(true)
	var enemy: Dictionary = hud._unit_by_id("unit_enemy_001")
	check(art.unit_visual_config(enemy).character == "ash_raider", "encounter resolves new enemy visual")
	check(hud._unit_display_name(enemy.id) == "Ash-road Raider", "enemy has readable identity")
	for direction: String in directions:
		hud.unit_facing[enemy.id] = direction
		for action: String in counts:
			hud.unit_visual_action[enemy.id] = "%s:%s" % [action, counts[action]-1]
			hud._refresh_unit_sprite(enemy.id)
			var sprite: TextureRect = hud.unit_layer.get_node(NodePath(enemy.id + "/Sprite"))
			check(sprite.texture != null and sprite.size == Vector2(512, 384), "native texture/canvas remains valid")
	check(hud.state == snapshot, "direction and animation changes are passive")
	hud.unit_visual_action.erase(enemy.id)
	hud._advance_original_idle()
	check(str(hud.unit_visual_action[enemy.id]).begins_with("pose:"), "idle loop advances original actor")
	check(hud.state == snapshot, "idle does not change simulation")
	await _exercise_resolver_actions(hud)
	hud._reset_debug_encounter()
	for index in range(3):
		await process_frame
	check(hud.unit_layer.get_node_or_null("unit_enemy_001/Sprite") != null, "new enemy survives reset")
	hud.queue_free()
	viewport.queue_free()
	await process_frame
	for message: String in failures:
		push_error(message)
	print("Original raider: %s checks, %s failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _observe_motion(hud: Control, observed: Dictionary) -> void:
	var start := Time.get_ticks_msec()
	while hud.animation_locked and Time.get_ticks_msec() - start < 3000:
		observed[str(hud.unit_visual_action.get("unit_enemy_001", ""))] = true
		await process_frame
	check(not hud.animation_locked, "animation releases input before deadline")


func _exercise_resolver_actions(hud: Control) -> void:
	# Isolated lifecycle fixture: original stats/loadouts, two actors, adjacent
	# legal floor tiles. This is not a physical or ordinary campaign playthrough.
	var hero: Dictionary = hud._unit_by_id("unit_player_001").duplicate(true)
	var enemy: Dictionary = hud._unit_by_id("unit_enemy_001").duplicate(true)
	hero.position = {"x": 0, "y": 0}
	enemy.position = {"x": 2, "y": 0}
	hud.state.units = [hero, enemy]
	hud.state.turn_state.turn_order = [hero.id, enemy.id]
	hud.state.turn_state.active_unit_id = enemy.id
	hud.unit_visual_action.clear()
	hud._prepare_presentation_cache()
	hud._render()
	var observed: Dictionary = {}
	hud._run_command(hud._build_command("move", {"type": "tile", "position": {"x": 1, "y": 0}}))
	await _observe_motion(hud, observed)
	check(hud._unit_by_id(enemy.id).position == {"x": 1, "y": 0}, "resolver moves original raider")
	check(int(hud._unit_by_id(enemy.id).resources.mp) == 3, "move retains real MP cost")
	hud._run_command(hud._build_command("basic_attack", {"type": "unit", "unit_id": hero.id}))
	await _observe_motion(hud, observed)
	check(int(hud._unit_by_id(enemy.id).resources.ap) == 0, "raider attack retains AP cost")
	hud._run_command(hud._build_command("end_turn", {}))
	await _observe_motion(hud, observed)
	for iteration in range(16):
		if hud._combat_result() != "in_progress":
			break
		var active: Dictionary = hud._unit_by_id(hud.state.turn_state.active_unit_id)
		if active.id == hero.id and int(active.resources.ap) > 0:
			hud._run_command(hud._build_command("basic_attack", {"type": "unit", "unit_id": enemy.id}))
		else:
			hud._run_command(hud._build_command("end_turn", {}))
		await _observe_motion(hud, observed)
	check(int(hud._unit_by_id(enemy.id).resources.hp) == 0, "regular weapon damage reaches death without Debug Win/stat boosts")
	for terminal in ["walk:7", "combat:7", "hit:3", "death:7"]:
		check(observed.has(terminal), "complete resolver-driven clip reached " + terminal)
