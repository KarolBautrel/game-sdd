extends SceneTree
## Automated fixtures, not physical input or continuous visual acceptance.
const Resolver := preload("res://scripts/domain/combat_resolver.gd")
const Art := preload("res://scripts/presentation/combat/combat_unit_art.gd")
const Actions := preload("res://scripts/presentation/combat/combat_action_model.gd")
const Text := preload("res://scripts/presentation/combat/combat_text.gd")
const Scenarios := preload("res://scripts/presentation/combat/combat_scenario_catalog.gd")
const PATH := "res://resources/data/combat_encounters/drawn_roster_skirmish.json"
const SETTING := "debug/qa/combat_scenario"
const ROLES := ["knight", "warrior", "archer_1", "rogue_1", "axe_bandit", "bandit_spearman"]
var failures: Array[String] = []
var checks := 0
var report := {"physical_gameplay": "NOT_RUN", "continuous_visual_review": "NOT_RUN",
	"desktop_input_used": false, "role_fixtures": [], "full_battle_simulations": []}


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)


func fixture() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(PATH))


func _run() -> void:
	var source := fixture()
	check(Scenarios.path_for_id("drawn_roster_skirmish") == PATH, "catalogue resolves direct review")
	check(source.units.size() == 8, "four allies and four opponents")
	var roles: Dictionary = {}
	var names: Dictionary = {}
	var art := Art.new()
	for unit: Dictionary in source.units:
		roles[unit.visual.character] = true
		names[Text.unit_display_name(source, unit.id)] = true
		check(art.is_drawn_unit(unit), unit.id + " routes to painted profile")
		var item: Dictionary = source.item_profiles[unit.loadout.main_hand]
		check(not item.get("two_handed", false) or unit.loadout.off_hand == null, unit.id + " valid hands")
		var action := "ranged_attack" if unit.visual.character == "archer_1" else "basic_attack"
		check(Actions.action_granted_to_unit(source, unit, action), unit.id + " equipment grants matching action")
		if unit.visual.character == "warrior":
			check(unit.loadout.off_hand == "hero_shield", "painted shield agrees with loadout")
		if unit.visual.character == "knight":
			check(unit.loadout.main_hand == "greatsword" and item.two_handed, "knight uses existing two-handed profile")
	check(roles.size() == 6 and names.size() == 8, "all six roles and eight distinct names")
	check(not source.has("rewards") and not source.has("source_dungeon_id"), "isolated encounter without settlement")
	_simulate_battle(false)
	_simulate_battle(true)
	var previous_setting: Variant = ProjectSettings.get_setting(SETTING, "")
	ProjectSettings.set_setting(SETTING, "drawn_roster_skirmish")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	root.add_child(viewport)
	var hud: Control = load("res://scenes/combat/CombatDebug.tscn").instantiate()
	viewport.add_child(hud)
	await process_frame
	check(hud.current_encounter_path == PATH and hud.state.id == source.id, "direct scenario launch loads real battle")
	check(hud.get_node("%TitleLabel").text == "Painted Six - Old Mine", "review has recognizable title")
	for unit: Dictionary in source.units:
		var sprite: TextureRect = hud.unit_layer.get_node(NodePath(unit.id + "/Sprite"))
		check(sprite.texture != null, unit.id + " loaded board sprite")
	for role: String in ROLES:
		await _role_test(hud, role)
	await _reset_test(hud)
	hud.authoring_draft = {}
	ProjectSettings.set_setting(SETTING, "")
	var normal: Control = load("res://scenes/combat/CombatDebug.tscn").instantiate()
	viewport.add_child(normal)
	await process_frame
	check(normal.current_encounter_path == Scenarios.DEFAULT_ENCOUNTER_PATH, "empty opt-in preserves default battle")
	normal.queue_free()
	ProjectSettings.set_setting(SETTING, previous_setting)
	viewport.queue_free()
	await create_timer(0.6).timeout
	report["checks"] = checks
	report["failures"] = failures
	report["status"] = "PASS" if failures.is_empty() else "FAIL"
	DirAccess.make_dir_recursive_absolute("res://artifacts/drawn-animation")
	var output := FileAccess.open("res://artifacts/drawn-animation/battle-review.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  ") + "\n")
	for failure: String in failures:
		push_error(failure)
	print("Drawn battle review: %s checks, %s failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _pair(hud: Control, role: String, wounded: bool = false) -> String:
	var state := fixture()
	var actor: Dictionary = {}
	for unit: Dictionary in state.units:
		if unit.visual.character == role:
			actor = unit.duplicate(true)
			break
	actor.team = "player"
	actor.position = {"x": 2, "y": 8}
	var target := actor.duplicate(true)
	target.id = "review_target"
	target.team = "enemy"
	target.position = {"x": 3, "y": 8}
	if wounded:
		target.resources.hp = 1
	state.units = [actor, target]
	state.turn_state = {"active_unit_id": actor.id, "round": 1, "turn_order": [actor.id, target.id]}
	hud.authoring_draft = state
	hud._reset_debug_encounter()
	return actor.id


func _wait_playback(hud: Control, actor_id: String) -> Dictionary:
	var seen: Dictionary = {}
	var until := Time.get_ticks_msec() + 5000
	while hud.animation_locked and Time.get_ticks_msec() < until:
		for id: String in [actor_id, "review_target"]:
			var action := str(hud.unit_visual_action.get(id, ""))
			seen[id + "/" + action] = true
		await process_frame
	check(not hud.animation_locked, actor_id + " animation unlocks within bound")
	return seen


func _role_test(hud: Control, role: String) -> void:
	var id := _pair(hud, role)
	var actor: Dictionary = hud._unit_by_id(id)
	check(hud.unit_art.default_visual_action(actor, hud.state) == "combat_idle", role + " nearby guard")
	var neutral := actor.duplicate(true)
	neutral.position = {"x": 0, "y": 0}
	check(hud.unit_art.default_visual_action(neutral, hud.state) == "pose", role + " distant neutral stance")
	var destination := {"x": 2, "y": 9}
	# Let fixture construction/layout finish before measuring the next frame's tween.
	# Otherwise the first headless delta includes synchronous asset/cache preparation.
	await process_frame
	await process_frame
	var travel_pixels: float = hud._position_to_unit_top_left(actor.position).distance_to(hud._position_to_unit_top_left(destination))
	var expected_move_seconds: float = hud.unit_art.movement_seconds(actor, travel_pixels, 0.0)
	var move_started := Time.get_ticks_msec()
	hud._run_command(hud._build_command("move", {"type": "tile", "position": destination}))
	check(hud.animation_locked, role + " resolver movement starts playback")
	var seen := await _wait_playback(hud, id)
	var move_seconds := float(Time.get_ticks_msec() - move_started) / 1000.0
	check(absf(move_seconds - expected_move_seconds) < 0.15, role + " actual movement follows authored brisk duration")
	check(seen.has(id + "/walk:4"), role + " calm walking phase progresses")
	check(not seen.has(id + "/walk:7"), role + " 104px step does not churn through a complete cycle")
	check(hud._unit_by_id(id).position == destination and hud._unit_by_id(id).resources.mp == 3,
		role + " movement commits position and ordinary MP cost")
	id = _pair(hud, role)
	var action := "ranged_attack" if role == "archer_1" else "basic_attack"
	var target := {"type": "unit", "unit_id": "review_target"}
	var before: int = hud._unit_by_id("review_target").resources.hp
	hud._run_command(hud._build_command(action, target))
	check(hud.animation_locked, role + " ordinary attack starts playback")
	await create_timer(0.20).timeout
	check(int(hud._display_resources(hud._unit_by_id("review_target")).hp) == before,
		role + " no premature damage during anticipation")
	seen = await _wait_playback(hud, id)
	check(seen.has(id + "/combat:7") and seen.has("review_target/hit:3"), role + " full attack and hit")
	check(hud._unit_by_id("review_target").resources.hp < before, role + " resolver damage committed")
	var hit_hp: int = hud._unit_by_id("review_target").resources.hp
	id = _pair(hud, role, true)
	hud._run_command(hud._build_command(action, target))
	seen = await _wait_playback(hud, id)
	check(seen.has("review_target/death:7"), role + " full final death frame")
	check(hud._unit_by_id("review_target").resources.hp == 0 and hud._combat_result() == "victory",
		role + " lethal resolver action reaches terminal result")
	check(hud._death_final_visual_action(hud._unit_by_id("review_target")) == "death:7", role + " corpse holds last drawing")
	if role == "archer_1":
		check(is_equal_approx(hud.unit_art.impact_seconds(hud._unit_by_id(id), 0.0), 1.26), "bow release at 1260ms")
		check(is_equal_approx(hud.unit_art.clip_seconds(hud._unit_by_id(id), "combat", 0.0), 1.8), "bow retains 1800ms clip")
	report.role_fixtures.append({"role": role, "hit_hp_after": hit_hp,
		"move_seconds": move_seconds, "expected_move_seconds": expected_move_seconds,
		"movement": true, "attack_hit_death": true, "visual_acceptance": "NOT_RUN"})


func _reset_test(hud: Control) -> void:
	_pair(hud, "archer_1")
	hud.authoring_draft = {}
	hud._run_command(hud._build_command("ranged_attack", {"type": "unit", "unit_id": "review_target"}))
	await create_timer(0.1).timeout
	hud._reset_debug_encounter()
	var reset_state: Dictionary = hud.state.duplicate(true)
	await create_timer(1.9).timeout
	check(hud.state == reset_state and not hud.animation_locked and hud.state.units.size() == 8,
		"reset restores full encounter and cancels pending bow commit")


func _simulate_battle(passive_players: bool) -> void:
	var state: Dictionary = Resolver.simulate(fixture(), []).state
	var result := "in_progress"
	var commands: Array = []
	var role_actions: Dictionary = {}
	for index in range(800):
		var actor: Dictionary = Actions.unit_by_id(state, state.turn_state.active_unit_id)
		var policy_state := state.duplicate(true)
		if actor.team == "player":
			for unit: Dictionary in policy_state.units:
				unit.team = "enemy" if unit.team == "player" else "player"
		var command: Dictionary = Resolver.choose_enemy_command(policy_state, "review_%03d" % index)
		if passive_players and actor.team == "player":
			command.action_id = "end_turn"
			command.target = {"type": "none"}
		var outcome: Dictionary = Resolver.simulate(state, [command])
		state = outcome.state
		result = outcome.result
		var rejected := false
		for event: Dictionary in state.event_log:
			if event.type == "command_rejected":
				rejected = true
		check(not rejected, "full battle legal command " + str(index))
		if rejected:
			break
		var key := str(actor.visual.character) + "/" + str(command.action_id)
		role_actions[key] = int(role_actions.get(key, 0)) + 1
		commands.append(command)
		if result != "in_progress":
			break
	var expected := "defeat" if passive_players else "victory"
	check(result == expected, "full legal battle reaches " + expected)
	report.full_battle_simulations.append({"policy": "passive_players" if passive_players else "both_teams_existing_ai",
		"result": result, "round": state.turn_state.round, "commands": commands,
		"role_actions": role_actions, "uses_debug_win": false, "physical_acceptance": "NOT_RUN"})
