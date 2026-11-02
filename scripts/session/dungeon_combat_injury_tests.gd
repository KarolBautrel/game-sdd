extends SceneTree

const Model := preload("res://scripts/domain/dungeon_state_model.gd")
const Session := preload("res://scripts/session/dungeon_run_session.gd")
const Entry := preload("res://scripts/domain/dungeon_entry_selection.gd")
var failures: Array[String] = []

func _init() -> void:
	var dungeon := Entry.dungeon_for_payload(Entry.default_payload())
	var state := Model.initial_state(dungeon)
	state = Model.enter_room(dungeon, state, "generated_switchback").state
	# Select an available event choice rather than assuming a presentation label.
	if not state.pending_room_event.is_empty():
		for choice: Dictionary in state.pending_room_event.choices:
			if choice.available:
				state = Model.resolve_room_event_choice(dungeon, state, choice.id).state
				break
	state = Model.enter_room(dungeon, state, "generated_guard").state
	if not state.pending_corridor_hazard.is_empty():
		state = Model.resolve_corridor_hazard_choice(dungeon, state, "use_supply").state
	_check(not state.pending_combat_request.is_empty(), "combat request exists")
	state.target_effects = {"party_slot_front": {"hp_loss": 3, "debuffs": {}}}
	state.party_effects.hp_loss = 3
	var payload := {"result": "victory", "source_dungeon_id": dungeon.id, "source_room_id": "generated_guard", "surviving_players": [{"id": "unit_player_001", "hp": 8, "max_hp": 14}, {"id": "unit_player_002", "hp": 10, "max_hp": 10}], "defeated_player_ids": []}
	var invalid := payload.duplicate(true)
	invalid.result = "unknown"
	_check(Model.apply_combat_result(dungeon, state, invalid).state == state, "unsupported result preserves pending state")
	invalid = payload.duplicate(true)
	invalid.source_room_id = "wrong"
	_check(Model.apply_combat_result(dungeon, state, invalid).state == state, "wrong source preserves pending state")
	_check(Model.enter_room(dungeon, state, "generated_exit").rejection == "pending_combat", "cannot evade pending combat")
	var accepted := Model.apply_combat_result(dungeon, state, payload)
	_check(accepted.status == "accepted", "injured return accepted")
	_check(Model.party_member_hp(accepted.state, "unit_player_001") == 8, "8 combat HP persists")
	_check(accepted.state.party_effects.hp_loss == 6, "absolute injury replaces old loss")
	_check(Model.apply_combat_result(dungeon, accepted.state, payload).status == "rejected", "duplicate rejected")
	var healed := Model.use_bandage(accepted.state)
	_check(Model.party_member_hp(healed.state, "unit_player_001") == 9, "bandage restores one HP")
	var session := Session.new()
	session.pending_combat_request = state.pending_combat_request.duplicate(true)
	session.pending_combat_request.dungeon_modifiers = Model._combat_modifiers_for_state(healed.state)
	var encounter: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(session.combat_encounter_path()))
	var next := session.apply_launch_metadata(encounter)
	_check(next.units[0].resources.hp == 9, "next combat does not double subtract injuries")
	payload.surviving_players = [{"id": "unit_player_002", "hp": 7}]
	payload.defeated_player_ids = ["unit_player_001"]
	var fallen: Dictionary = Model.apply_combat_result(dungeon, state, payload).state
	_check(Model.party_member_hp(fallen, "unit_player_001") == 0, "incapacitated member stays at zero")
	session.pending_combat_request.dungeon_modifiers = Model._combat_modifiers_for_state(fallen)
	var next_fallen := session.apply_launch_metadata(encounter)
	_check(next_fallen.units[0].resources.hp == 0, "incapacitated member cannot silently respawn")
	var recovered: Dictionary
	# Recovery targets sorted formation IDs; back precedes front, so isolate front.
	fallen.target_effects.party_slot_back.hp_loss = 0
	fallen.party_effects.hp_loss = 14
	recovered = Model.use_bandage(fallen).state
	_check(Model.party_member_hp(recovered, "unit_player_001") == 1, "recovery restores incapacitated member")
	session.free()
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("dungeon_combat_injury_tests: OK")
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
