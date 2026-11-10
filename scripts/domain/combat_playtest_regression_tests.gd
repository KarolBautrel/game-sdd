extends SceneTree
## Combat104/105: independent runtime proof of observed desktop regressions.
const Resolver := preload("res://scripts/domain/combat_resolver.gd")
const CombatHUD := preload("res://scripts/presentation/combat_debug.gd")
var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func fixture(name: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/combat_encounters/%s.json" % name))

func command(actor: String, action: String, target: Dictionary) -> Dictionary:
	return {"id":"cmd_regression", "type":"perform_action", "actor_id":actor, "action_id":action, "target":target}

func bow(fallback: bool = false) -> Dictionary:
	var state := fixture("slice_63_aimed_shot_from_bow")
	if fallback:
		state.erase("item_profiles")
		state.units[0].erase("loadout")
		state.units[0].available_actions.append_array(["ranged_attack", "aimed_shot"])
	return state

func tile(state: Dictionary, x: int, kind: String) -> void:
	for entry: Dictionary in state.grid.tiles:
		if entry.x == x and entry.y == 1: entry.type = kind

func event_types(state: Dictionary) -> Array:
	return state.event_log.map(func(event: Dictionary) -> String: return event.type)

func _initialize() -> void:
	for action: String in ["ranged_attack", "aimed_shot"]:
		var state := fixture("qa_bow_los_detour")
		var shot := command("unit_player_001", action, {"type":"unit", "unit_id":"unit_enemy_001"})
		var rejected: Dictionary = Resolver.simulate(state, [shot]).state
		check(rejected.event_log[-1].get("reason") == "target_not_visible", "detour replay initially blocked " + action)
		check(rejected.units == state.units and rejected.seed == state.seed, "detour rejection preserves resources/roll " + action)
		var moved: Dictionary = Resolver.simulate(state, [command("unit_player_001", "move", {"type":"tile", "position":{"x":3, "y":2}})]).state
		check(not event_types(moved).has("command_rejected"), "detour replay normal move legal")
		check(moved.units[0].resources.ap == 2 and moved.units[0].resources.mp == 0, "detour costs3MP and retains AP")
		var resolved: Dictionary = Resolver.simulate(moved, [shot]).state
		check(not event_types(resolved).has("command_rejected"), "same target opens after detour " + action)
		check(resolved.units[0].resources.ap == (0 if action == "aimed_shot" else 1), "post-detour shot spends normal AP")
	for row: Array in [[1,"highground"], [2,"highground"], [1,"floor"], [null,"highground"]]:
		var fixture_id := "slice_62_enemy_ai_move_then_attack" if row[0] == null else "qa_ai_budget_%s_%s" % [row[1], row[0]]
		var state := fixture(fixture_id)
		var enemy: Dictionary = state.units[1]
		if row[0] == null:
			enemy.resources.erase("mp")
			for entry: Dictionary in state.grid.tiles:
				if entry.x == 2: entry.type = row[1]
		else:
			check(enemy.resources.ap == 1 and enemy.resources.mp == row[0] and enemy.stats.move_points == row[0], "replay fixture budget")
			for entry: Dictionary in state.grid.tiles:
				if entry.x == 2: check(entry.type == row[1], "replay fixture terrain strip")
		var before := state.duplicate(true)
		var chosen := Resolver.choose_enemy_command(state)
		var expected := "end_turn" if row[0] == 1 and row[1] == "highground" else "move"
		check(chosen.action_id == expected, "weighted fallback chooses affordable action")
		check(state == before and Resolver.choose_enemy_command(state) == chosen, "weighted fallback deterministic/read-only")
		var resolved: Dictionary = Resolver.simulate(state, [chosen]).state
		check(not event_types(resolved).has("command_rejected"), "weighted fallback command legal")
		var after: Dictionary = resolved.units[1]
		if expected == "end_turn":
			check(after == enemy and resolved.turn_state.active_unit_id != enemy.id, "unaffordable step passes without cost")
		else:
			check(after.position.x == 2, "affordable approach retained")
			check(after.resources.ap == (0 if row[0] == null else 1), "legacy/AP movement cost retained")
			if row[0] != null: check(after.resources.mp == 0, "weighted terrain pays exact MP")
	var hud := CombatHUD.new()
	for fallback: bool in [false, true]:
		for x: int in [2, 3]:
			for action: String in ["ranged_attack", "aimed_shot"]:
				var state := bow(fallback)
				tile(state, x, "blocked")
				var before := state.duplicate(true)
				var shot := command("unit_player_001", action, {"type":"unit", "unit_id":"unit_enemy_001"})
				hud.state = state
				var preview: Dictionary = hud._preview_for_command(shot)
				check(preview.get("rejection") == "target_not_visible", "preview blocks " + action)
				var resolved: Dictionary = Resolver.simulate(state, [shot]).state
				check(state == before, "shot/preview preserve input")
				check(resolved.units == before.units and resolved.turn_state == before.turn_state and resolved.seed == before.seed, "blocked shot is atomic")
				check(event_types(resolved) == ["combat_started", "turn_started", "command_rejected"], "no cost/cooldown/roll before rejection")
				check(resolved.event_log[-1].get("reason") == "target_not_visible", "resolver blocks " + action)
	for row: Array in [[2,"floor"], [2,"highground"], [2,"cover_low"], [1,"blocked"], [4,"blocked"]]:
		for action: String in ["ranged_attack", "aimed_shot"]:
			var state := bow()
			tile(state, row[0], row[1])
			var shot := command("unit_player_001", action, {"type":"unit", "unit_id":"unit_enemy_001"})
			hud.state = state
			check(hud._preview_for_command(shot).get("rejection") == "", "clear preview " + action)
			var resolved: Dictionary = Resolver.simulate(state, [shot]).state
			check(not event_types(resolved).has("command_rejected"), "clear line/endpoints legal " + action)
			check(resolved.units[0].resources.ap == (0 if action == "aimed_shot" else 1), "clear shot pays normal AP")
	var short_bow := bow()
	short_bow.item_profiles.hunting_bow.action_profiles.aimed_shot.range = 2
	tile(short_bow, 2, "blocked")
	var range_result: Dictionary = Resolver.simulate(short_bow, [command("unit_player_001", "aimed_shot", {"type":"unit", "unit_id":"unit_enemy_001"})]).state
	check(range_result.event_log[-1].get("reason") == "target_out_of_range", "range rejection precedes LOS")
	hud.free()
	for ranged: bool in [false, true]:
		for adjacent: bool in [false, true]:
			for mixed: bool in [false, true]:
				var state := fixture("slice_62_enemy_ai_move_then_attack")
				var enemy: Dictionary = state.units[1]
				enemy.resources.ap = 0
				if ranged: enemy.available_actions.append("ranged_attack")
				if adjacent: state.units[0].position = {"x":2, "y":1}
				if mixed:
					var extra: Dictionary = state.units[0].duplicate(true)
					extra.id = "unit_player_002"
					extra.position = {"x":0, "y":2}
					state.units.append(extra)
					state.turn_state.turn_order.append(extra.id)
				var before := state.duplicate(true)
				var chosen := Resolver.choose_enemy_command(state)
				check(chosen.action_id == "end_turn", "zero AP passes with MP")
				check(Resolver.choose_enemy_command(state) == chosen and state == before, "AI deterministic/read-only")
				var resolved: Dictionary = Resolver.simulate(state, [chosen]).state
				check(resolved.units[1] == enemy, "spent enemy position/MP unchanged")
				check(resolved.turn_state.active_unit_id != enemy.id, "turn advances")
				check(event_types(resolved) == ["combat_started", "turn_started", "action_performed", "turn_ended", "turn_started"], "no wasted movement/attack")
	var pursuit := fixture("slice_62_enemy_ai_move_then_attack")
	var approach := Resolver.choose_enemy_command(pursuit)
	check(approach.action_id == "move" and approach.target.position.x == 3 and approach.target.position.y == 1, "positive AP approach retained")
	pursuit = Resolver.simulate(pursuit, [approach]).state
	var attack := Resolver.choose_enemy_command(pursuit)
	check(attack.action_id == "basic_attack", "move then attack retained")
	pursuit = Resolver.simulate(pursuit, [attack]).state
	check(pursuit.units[0].resources.hp == 8 and pursuit.units[1].resources.ap == 0 and pursuit.units[1].resources.mp == 1, "normal attack outcome")
	check(Resolver.choose_enemy_command(pursuit).action_id == "end_turn", "after attack pass")
	var player := fixture("slice_62_enemy_ai_move_then_attack")
	player.turn_state.active_unit_id = "unit_player_001"
	player.units[0].resources.ap = 0
	var manual: Dictionary = Resolver.simulate(player, [command("unit_player_001", "move", {"type":"tile", "position":{"x":3, "y":1}})]).state
	check(manual.units[0].position.x == 3 and manual.units[0].position.y == 1 and manual.units[0].resources.ap == 0 and manual.units[0].resources.mp == 2, "manual zero AP movement preserved")
	for failure: String in failures: push_error(failure)
	print("Combat playtest regressions: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
