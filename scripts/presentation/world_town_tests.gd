extends SceneTree

const Selection := preload("res://scripts/domain/dungeon_entry_selection.gd")
const Model := preload("res://scripts/domain/dungeon_state_model.gd")
var errors: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var campaign := root.get_node("CampaignSession")
	campaign.load_profile("", true)
	var session := root.get_node("DungeonRunSession")
	var app: Control = load("res://scenes/app/App.tscn").instantiate()
	root.add_child(app)
	await process_frame
	_check(app.action_buttons.has("town") and app.action_buttons.has("prepare"), "hub destinations")
	app.queue_free()
	await process_frame
	var town: Control = load("res://scenes/town/town_shell.tscn").instantiate()
	root.add_child(town)
	await process_frame
	_check(town.action_buttons.size() == 11, "six supplies, inn, return, stash, trade and training")
	town.action_buttons.buy_bandage.pressed.emit()
	await process_frame
	_check(int(campaign.state.gold) == 38 and int(campaign.state.supplies.bandage) == 4, "market control transaction")
	var data := Selection.dungeon_for_payload(Selection.default_payload())
	campaign.state.effects.target_effects = {"party_slot_front": {"hp_loss": 3, "debuffs": {}}}
	_check(campaign.travel("dungeon_old_mine"), "travel before managed preparation")
	campaign.begin_run(data, Model.initial_state(data))
	town._render()
	var cards := town.find_children("*", "PanelContainer", true, false).filter(func(node: Node) -> bool: return node.has_method("set_hp"))
	_check(cards.size() == 2 and cards[0].hp_label.text == "HP 11/14", "active party uses checkpoint injuries")
	_check(session.restore_campaign(), "session restore")
	_check(session.managed_run and session.has_dungeon_run(), "managed snapshot handoff")
	var hud: Control = load("res://scenes/dungeon/DungeonDebug.tscn").instantiate()
	root.add_child(hud)
	await process_frame
	_check(not hud.reset_button.visible and hud.retreat_button.visible, "managed reset blocked and retreat visible")
	hud._reset_expedition()
	_check(session.managed_run and session.has_dungeon_run(), "reset cannot erase active run")
	var entry_state: Dictionary = session.dungeon_state.duplicate(true)
	entry_state.pending_combat_request = {"dungeon_id": data.id, "room_id": "qa", "combat_encounter_path": "res://resources/data/combat_encounters/debug_dungeon_combat_showcase.json"}
	session.start_combat(data, entry_state, 1234)
	_check(session.restore_campaign() and session.next_combat_seed == 1234 and session.has_pending_combat_launch(), "pending combat restore")
	session.start_combat(data, entry_state)
	_check(session.next_combat_seed == 1234, "pending combat keeps seed")
	_check(session.finish_run(data, Model.initial_state(data), "retreated"), "normal retreat accepted")
	_check(session.pending_world_return_payload.has("run_id"), "return receipt attached")
	_check(campaign.settle(session.pending_world_return_payload), "session result settlement")
	session.clear()
	_check(not session.managed_run and not session.town_preparation, "flags cleared")
	hud.queue_free()
	town.queue_free()
	await process_frame
	for error in errors:
		push_error(error)
	if errors.is_empty():
		print("World town tests passed")
	quit(0 if errors.is_empty() else 1)


func _check(condition: bool, label: String) -> void:
	if not condition:
		errors.append(label)
