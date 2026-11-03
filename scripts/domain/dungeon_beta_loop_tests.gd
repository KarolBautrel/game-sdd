extends SceneTree

const Model := preload("res://scripts/domain/dungeon_state_model.gd")
const Session := preload("res://scripts/session/dungeon_run_session.gd")
const Entry := preload("res://scripts/domain/dungeon_entry_selection.gd")
const Combat := preload("res://scripts/domain/combat_resolver.gd")
var failures: Array[String] = []
var checkpoints: Array = []

func _init() -> void:
	var first := _expedition()
	var second := _expedition()
	_check(first == second, "same seeds reproduce all checkpoints and payload")
	print("BETA_CHECKPOINTS ", JSON.stringify(first))
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("dungeon_beta_loop_tests: OK")
	quit(0 if failures.is_empty() else 1)

func _expedition() -> Dictionary:
	checkpoints = []
	var dungeon := Entry.dungeon_for_payload(Entry.default_payload())
	var state := Model.initial_state(dungeon)
	_check(Model.loadout_packing_summary(dungeon, state.supplies).used == 7, "prepared capacity 7")
	for room_id in ["generated_switchback", "generated_cache"]:
		state = _travel(dungeon, state, room_id)
	state = _accepted(Model.claim_current_reward(dungeon, state), "first reward")
	_check(Model.claim_current_reward(dungeon, state).status == "rejected", "reward cannot duplicate")
	state = _accepted(Model.use_lamp_oil(state), "refuel")
	state = _travel(dungeon, state, "generated_switchback")
	state = _travel(dungeon, state, "generated_guard")
	var session := Session.new()
	_check(session.start_combat(dungeon, state, 1234), "session launch")
	var encounter: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(session.combat_encounter_path()))
	var combat := Combat.simulate(session.apply_launch_metadata(encounter), [])
	var commands: Array = []
	for step in range(250):
		if combat.result != "in_progress":
			break
		var command := _choose_command(combat.state, "beta_%03d" % step)
		commands.append(command)
		combat = Combat.simulate(combat.state, [command])
		_check(not _rejected(combat), "chosen legal combat command %s" % step)
	_check(combat.result == "victory", "normal commands win within budget")
	_check(commands.any(func(c: Dictionary) -> bool: return c.get("action_id", "") == "move"), "battle includes movement")
	_check(commands.any(func(c: Dictionary) -> bool: return c.get("action_id", "") in ["ranged_attack", "basic_attack", "aimed_shot"]), "battle includes attacks")
	_check(session.finish_combat(combat.result_payload), "session return")
	state = session.dungeon_state.duplicate(true)
	_check(not session.has_pending_combat_launch(), "launch cleared after accepted return")
	for survivor: Dictionary in combat.result_payload.surviving_players:
		_check(Model.party_member_hp(state, survivor.id) == survivor.hp, "returned HP matches %s" % survivor.id)
	checkpoints.append({"phase": "combat_return", "commands": commands, "result": combat.result_payload})
	state = _travel(dungeon, state, "generated_deep_cache")
	state = _accepted(Model.claim_current_reward(dungeon, state), "second reward")
	state = _travel(dungeon, state, "generated_guard")
	state = _accepted(Model.use_lamp_oil(state), "second refuel")
	state = _travel(dungeon, state, "generated_exit")
	_check(session.finish_run(dungeon, state), "finish at exit")
	state = session.dungeon_state
	_check(Model.enter_room(dungeon, state, "generated_guard").rejection == "run_completed", "completed run rejects movement")
	_check(session.pending_world_return_payload.outcome == "completed", "completed return payload")
	_check(session.pending_world_return_payload.kept_rewards.gold == 20, "20 gold retained")
	_check(state.cleared_room_ids.size() == 6, "all six rooms secured")
	_check(state.resolved_hazard_ids.size() >= 2 and state.resolved_room_event_ids.size() >= 2, "hazards and events covered")
	var result := {"checkpoints": checkpoints.duplicate(true), "payload": session.pending_world_return_payload.duplicate(true)}
	session.free()
	return result

func _travel(dungeon: Dictionary, state: Dictionary, room_id: String) -> Dictionary:
	var result := Model.enter_room(dungeon, state, room_id)
	if result.status == "choice_required":
		result = Model.resolve_corridor_hazard_choice(dungeon, result.state, "use_supply")
	state = _accepted(result, "travel %s" % room_id)
	if not state.pending_room_event.is_empty():
		for choice: Dictionary in state.pending_room_event.choices:
			if choice.available:
				state = _accepted(Model.resolve_room_event_choice(dungeon, state, choice.id), "room event")
				break
	checkpoints.append({"room": room_id, "supplies": state.supplies.duplicate(true), "light": state.light_level})
	return state

func _choose_command(state: Dictionary, command_id: String) -> Dictionary:
	var actor := Combat._unit_by_id(state, state.turn_state.active_unit_id)
	if actor.team == "enemy":
		return Combat.choose_enemy_command(state, command_id)
	var targets: Array = state.units.filter(func(u: Dictionary) -> bool: return u.team == "enemy" and u.resources.hp > 0)
	targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.resources.hp < b.resources.hp if a.resources.hp != b.resources.hp else a.id < b.id)
	for action in ["aimed_shot", "basic_attack", "ranged_attack"]:
		for target: Dictionary in targets:
			var command := _action(actor.id, action, {"type": "unit", "unit_id": target.id}, command_id)
			if not _rejected(Combat.simulate(state, [command])):
				return command
	if not targets.is_empty():
		var destination := Combat._best_move_toward(state, actor, targets[0])
		if not destination.is_empty():
			var command := _action(actor.id, "move", {"type": "tile", "position": destination}, command_id)
			if not _rejected(Combat.simulate(state, [command])):
				return command
	return _action(actor.id, "end_turn", {}, command_id)

func _action(actor: String, action: String, target: Dictionary, command_id: String) -> Dictionary:
	return {"id": command_id, "type": "perform_action", "actor_id": actor, "action_id": action, "target": target}

func _rejected(result: Dictionary) -> bool:
	return result.state.event_log.any(func(e: Dictionary) -> bool: return e.type == "command_rejected")

func _accepted(result: Dictionary, phase: String) -> Dictionary:
	_check(result.status == "accepted", "%s: %s" % [phase, result.get("rejection", "")])
	return result.state

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
