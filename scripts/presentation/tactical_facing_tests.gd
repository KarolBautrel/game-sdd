extends SceneTree
## Check actual battle sprites, retaining raw art and geographic event facings.
const Art := preload("res://scripts/presentation/combat/combat_unit_art.gd")
const Assets := preload("res://scripts/presentation/shared/asset_catalog.gd")
const VisualState := preload("res://scripts/presentation/combat/combat_unit_visual_state.gd")
const DIRECTIONS := ["south", "south_west", "west", "north_west", "north", "north_east", "east", "south_east"]
var failures: Array[String] = []
var checks := 0
var samples: Array[Dictionary] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)


func _run() -> void:
	var art := Art.new()
	var expected := {"south_east":"south_east", "east":"south_east", "north_east":"south_east", "south_west":"south_west", "west":"south_west", "north_west":"south_west"}
	for character: String in Art.PROCESSED_SHEET_VISUALS:
		for team: String in ["player", "enemy"]:
			var unit := {"id":"actor", "team":team, "position":{"x":2,"y":2}, "resources":{"hp":10}, "visual":{"faction":"heroes", "character":character}}
			var fallback := "south_east" if team == "player" else "south_west"
			var visible_character: String = art.unit_visual_config(unit).character
			check(art.unit_direction(unit, {"units":[unit]}, {}) == fallback, character + team + " no-opponent default")
			for raw: String in DIRECTIONS:
				var side: String = expected.get(raw, fallback)
				check(art.unit_direction(unit, {}, {"actor":raw}) == side, character + team + raw + " tactical override")
				for action: String in ["pose", "combat_idle", "walk", "combat_walk", "combat", "hit", "death"]:
					var last := art.processed_sheet_frame_count(visible_character, action)-1
					var clip := "%s:%s" % [action, last]
					var texture := art.icon(unit, {"units":[unit]}, {"actor":raw}, {"actor":clip}, Vector2i(384,240))
					check(texture != null and texture == Assets.texture(art.processed_sheet_texture_path(visible_character, side, clip)), character + team + raw + clip + " displayed two-view texture")
				# Raw lookup is retained for archives/galleries, including every old view.
				if raw in Art.PROCESSED_SHEET_VISUALS[character].get("available_facings", DIRECTIONS):
					var path := art.processed_sheet_texture_path(character, raw, "pose:0")
					check(ResourceLoader.exists(path, "Texture2D") and path.contains("_"+raw+"_"), character + raw + " archived view retained")
	# Inferred nearest target selection: above/below left/right and pure vertical.
	for team: String in ["player", "enemy"]:
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				var unit := {"id":"actor", "team":team, "position":{"x":2,"y":2}}
				var target := {"id":"target", "team":"enemy" if team == "player" else "player", "position":{"x":2+dx,"y":2+dy}, "resources":{"hp":10}}
				var fallback := "south_east" if team == "player" else "south_west"
				var side := ("south_west" if dx < 0 else "south_east") if dx != 0 else fallback
				check(art.unit_direction(unit, {"units":[unit,target]}, {}) == side, "nearest target %s %s,%s" % [team,dx,dy])
	var steps := VisualState.movement_step_facings({"type":"unit_moved", "from":{"x":2,"y":2}, "path":[{"x":2,"y":1},{"x":3,"y":1}]})
	check(steps[0].direction == "north" and steps[1].direction == "east", "geographic movement information retained")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920,1080)
	root.add_child(viewport)
	var hud: Control = load("res://scenes/combat/CombatDebug.tscn").instantiate()
	viewport.add_child(hud)
	await process_frame
	check(hud.PRELOAD_UNIT_DIRECTIONS == Art.TACTICAL_DIRECTIONS, "battle preloads two facings only")
	for unit: Dictionary in hud.state.units:
		_check_sprite(hud, unit.id, "ordinary startup")
	var actor_id := _pair(hud, "knight", 3, 7)
	hud._run_command(hud._build_command("move", {"type":"tile", "position":{"x":2,"y":7}}))
	var seen: Dictionary = await _watch(hud, actor_id, "north movement")
	check(hud._unit_by_id(actor_id).position == {"x":2,"y":7}, "north move reaches resolver destination")
	check(seen.has(actor_id+"/walk:7"), "north move plays complete walk")
	for target_x in [1, 3]:
		actor_id = _pair(hud, "archer_1", target_x, 7)
		var expected_side := "south_west" if target_x < 2 else "south_east"
		check(hud._unit_direction(hud._unit_by_id(actor_id)) == expected_side, "above-diagonal startup " + expected_side)
		hud._run_command(hud._build_command("ranged_attack", {"type":"unit", "unit_id":"facing_target"}))
		seen = await _watch(hud, actor_id, "above target " + expected_side)
		check(seen.has(actor_id+"/combat:7") and seen.has("facing_target/death:7"), "above target complete bow and death " + expected_side)
		check(hud._unit_by_id("facing_target").resources.hp == 0 and hud._combat_result() == "victory", "above target resolver victory " + expected_side)
		_check_sprite(hud, "facing_target", "final corpse")
	hud.queue_free()
	viewport.queue_free()
	await process_frame
	DirAccess.make_dir_recursive_absolute("res://artifacts/tactical-facing")
	var report := FileAccess.open("res://artifacts/tactical-facing/runtime.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL", "checks":checks, "failures":failures, "samples":samples, "physical_acceptance":"NOT_RUN", "desktop_input":false}, "\t"));report.close()
	for failure in failures:
		push_error(failure)
	print("Tactical facing: %s checks, %s failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _pair(hud: Control, role: String, target_x: int, target_y: int) -> String:
	var state: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/combat_encounters/drawn_roster_skirmish.json"))
	var actor: Dictionary = {}
	for unit: Dictionary in state.units:
		if unit.visual.character == role:
			actor = unit.duplicate(true)
			break
	actor.team = "player"
	actor.position = {"x":2,"y":9}
	var target := actor.duplicate(true)
	target.id = "facing_target"
	target.team = "enemy"
	target.position = {"x":target_x,"y":target_y}
	target.resources.hp = 1
	state.units = [actor,target]
	state.turn_state = {"active_unit_id":actor.id, "round":1, "turn_order":[actor.id,target.id]}
	for tile: Dictionary in state.grid.tiles:
		if int(tile.x) in [1,2,3] and int(tile.y) in [7,8,9]:
			tile.type = "floor"
	hud.authoring_draft = state
	hud._reset_debug_encounter()
	return actor.id


func _check_sprite(hud: Control, id: String, label: String) -> void:
	var unit: Dictionary = hud._unit_by_id(id)
	var sprite: TextureRect = hud.unit_layer.get_node(NodePath(id+"/Sprite"))
	var side: String = hud._unit_direction(unit)
	check(side in Art.TACTICAL_DIRECTIONS and sprite.texture != null and sprite.texture.resource_path.contains("_"+side+"_"), label + " actual sprite " + id)


func _watch(hud: Control, actor_id: String, label: String) -> Dictionary:
	var seen: Dictionary = {}
	var until := Time.get_ticks_msec()+6000
	while hud.animation_locked and Time.get_ticks_msec() < until:
		for id: String in [actor_id,"facing_target"]:
			var action := str(hud.unit_visual_action.get(id, ""))
			var key := id+"/"+action
			if not seen.has(key):
				_check_sprite(hud, id, label+action)
				seen[key] = true
		await process_frame
	check(not hud.animation_locked, label + " animation unlocks")
	samples.append({"scenario":label, "observed_actions":seen.keys()})
	return seen
