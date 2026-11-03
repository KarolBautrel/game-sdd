extends SceneTree

const Campaign := preload("res://scripts/session/campaign_session.gd")
const Model := preload("res://scripts/domain/dungeon_state_model.gd")
const Selection := preload("res://scripts/domain/dungeon_entry_selection.gd")
var errors: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var path := "user://qa_campaign_%s.json" % Time.get_ticks_usec()
	var campaign := Campaign.new()
	_check(campaign.load_profile(path), "new isolated profile")
	_check(campaign.purchase("bandage"), "purchase")
	_check(int(campaign.state.gold) == 38 and int(campaign.state.supplies.bandage) == 4, "exact price/stock")
	var before := campaign.state.duplicate(true)
	_check(not campaign.purchase("bogus") and campaign.state == before, "unknown supply atomic")
	campaign.state.gold = 0
	before = campaign.state.duplicate(true)
	_check(not campaign.purchase("bandage") and campaign.state == before, "insufficient gold atomic")
	campaign.state.gold = 38
	var data := Selection.dungeon_for_payload(Selection.default_payload())
	var run_state := Model.initial_state(data)
	_check(campaign.travel("dungeon_old_mine"), "arrive before managed start")
	var too_many := run_state.duplicate(true)
	too_many.selected_supply_loadout.pickaxe = 99
	before = campaign.state.duplicate(true)
	_check(not campaign.begin_run(data, too_many) and campaign.state == before, "packing rejected")
	campaign.state.supplies.pickaxe = 0
	before = campaign.state.duplicate(true)
	_check(not campaign.begin_run(data, run_state) and campaign.state == before, "owned stock rejected")
	campaign.state.supplies.pickaxe = 2
	campaign.state.effects.target_effects = {"party_slot_front": {"hp_loss": 3, "debuffs": {}}}
	_check(campaign.begin_run(data, run_state), "managed start")
	var receipt: String = campaign.state.active_run.id
	_check(receipt.length() == 32 and int(campaign.state.supplies.pickaxe) == 1, "unique receipt and one deduction")
	_check(int(campaign.state.active_run.state.target_effects.party_slot_front.hp_loss) == 3, "injuries carried")
	before = campaign.state.duplicate(true)
	_check(not campaign.begin_run(data, run_state) and not campaign.purchase("food") and not campaign.recover() and campaign.state == before, "active transaction guards")
	run_state = campaign.state.active_run.state.duplicate(true)
	run_state.supplies.lamp_oil = 1
	_check(campaign.checkpoint(data, run_state, 1234), "checkpoint")
	var restored := Campaign.new()
	_check(restored.load_profile(path), "new instance restore")
	_check(Campaign.same_data(restored.state, campaign.state) and int(restored.state.active_run.combat_seed) == 1234, "snapshot and seed durable")
	var result := Model.retreat_run(data, run_state)
	_check(result.status == "accepted", "ordinary retreat domain")
	_check(restored.checkpoint(data, result.state, 1234), "finished checkpoint")
	var payload: Dictionary = result.event.run_result_payload.duplicate(true)
	payload.run_id = receipt
	var bad := payload.duplicate(true)
	bad.run_id = "other"
	before = restored.state.duplicate(true)
	_check(not restored.settle(bad) and restored.state == before, "receipt mismatch atomic")
	bad = payload.duplicate(true)
	bad.inventory_delta.gold = 999
	_check(not restored.settle(bad) and restored.state == before, "forged delta rejected")
	_check(restored.settle(payload), "retreat settlement")
	_check(restored.state.active_run.is_empty() and int(restored.state.supplies.lamp_oil) == 3 and int(restored.state.supplies.pickaxe) == 2, "unused supplies refunded once")
	_check(int(restored.state.effects.target_effects.party_slot_front.hp_loss) == 3, "injuries durable")
	before = restored.state.duplicate(true)
	_check(not restored.settle(payload) and restored.state == before, "duplicate receipt rejected")
	_check(restored.travel("town_ravenford"), "return to town before inn")
	_check(restored.recover() and int(restored.state.gold) == 33 and restored.state.effects.target_effects.is_empty(), "paid inn recovery")
	for outcome in ["completed", "failed"]:
		var memory := Campaign.new()
		memory.load_profile("", true)
		memory.travel("dungeon_old_mine")
		memory.begin_run(data, Model.initial_state(data))
		var completed: Dictionary = memory.state.active_run.state.duplicate(true)
		completed.run_inventory = {"gold": 12, "xp": 7, "items": ["ore"], "reward_records": []}
		completed.completed = true
		completed.run_outcome = outcome
		memory.checkpoint(data, completed)
		var final := Model.run_result_payload(data, completed, outcome)
		final.run_id = memory.state.active_run.id
		_check(memory.settle(final), outcome + " settlement")
		_check(int(memory.state.gold) == (52 if outcome == "completed" else 40) and int(memory.state.xp) == (7 if outcome == "completed" else 0) and memory.state.items == (["hero_sword", "hero_bow", "ore"] if outcome == "completed" else ["hero_sword", "hero_bow"]), outcome + " exact domain delta")
		memory.free()
	var bytes := FileAccess.get_file_as_string(path)
	var writer := FileAccess.open(path, FileAccess.WRITE)
	writer.store_string("{broken")
	writer.close()
	var invalid := Campaign.new()
	_check(not invalid.load_profile(path) and not invalid.purchase("food") and FileAccess.get_file_as_string(path) == "{broken", "corrupt save preserved")
	writer = FileAccess.open(path, FileAccess.WRITE)
	var unsupported := Campaign.initial_profile()
	unsupported.version = 999
	writer.store_string(JSON.stringify(unsupported))
	writer.close()
	_check(not invalid.load_profile(path), "unsupported version blocked")
	writer = FileAccess.open(path, FileAccess.WRITE)
	var malformed := Campaign.initial_profile()
	malformed.effects.target_effects = {"party_slot_front": {"hp_loss": -3}}
	writer.store_string(JSON.stringify(malformed))
	writer.close()
	_check(not invalid.load_profile(path) and not invalid.purchase("food"), "malformed injury blocked")
	writer = FileAccess.open(path, FileAccess.WRITE)
	writer.store_string(bytes)
	writer.close()
	_check(invalid.load_profile(path), "recover valid file")
	before = invalid.state.duplicate(true)
	invalid.save_path = "user://qa_missing_directory_%s/save.json" % Time.get_ticks_usec()
	_check(not invalid.purchase("food") and invalid.state == before and FileAccess.get_file_as_string(path) == bytes, "write failure rollback")
	for node in [campaign, restored, invalid]:
		node.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for error in errors:
		push_error(error)
	if errors.is_empty():
		print("Campaign session tests passed")
	quit(0 if errors.is_empty() else 1)


func _check(condition: bool, label: String) -> void:
	if not condition:
		errors.append(label)
