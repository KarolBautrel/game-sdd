extends SceneTree

const Items := preload("res://scripts/domain/item_catalog.gd")
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, text: String) -> void:
	if not ok:
		failures.append(text)


func _run() -> void:
	var input := ["generated_old_mine_trinket", "legacy/token", "generated_old_mine_trinket", "salvaged_shield"]
	var before := input.duplicate(true)
	var groups := Items.stacks(input)
	check(groups.size() == 3 and input == before, "groups exact/no mutation")
	for row: Dictionary in groups:
		if row.id == "generated_old_mine_trinket":
			check(row.quantity == 2 and row.name == "Mine trinket", "known stack name/quantity")
		if row.id == "legacy/token":
			check(row.category == "legacy" and row.quantity == 1, "unknown item preserved")
	var definition := Items.item("salvaged_shield")
	definition.name = "local mutation"
	check(Items.item("salvaged_shield").name != definition.name, "metadata isolated")
	var row := Items.item("hero_sword")
	check(not Items.validation_errors({"schema":"sdd.campaign-items-v1","items":[row,row]}).is_empty(), "duplicate catalogue id rejected")
	row.name = ""
	check(not Items.validation_errors({"schema":"sdd.campaign-items-v1","items":[row]}).is_empty(), "empty catalogue name rejected")
	check(Items.stacks([]).is_empty(), "empty stash")
	var campaign := root.get_node("CampaignSession")
	campaign.load_profile("", true)
	campaign.state.items = input.duplicate(true)
	var profile: Dictionary = campaign.state.duplicate(true)
	var app: Control = load("res://scenes/app/App.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.action_buttons.inventory.pressed.emit()
	for frame in range(5):
		await process_frame
	var view := app.find_child("InventoryView", true, false)
	check(view != null and view.shown_ids.size() == 3, "actual open stash control")
	view.filter_buttons.equipment.pressed.emit()
	await process_frame
	check(view.shown_ids == ["salvaged_shield"], "actual category filter")
	check(campaign.state == profile, "view/filter does not mutate campaign")
	app.action_buttons.close_stash.pressed.emit()
	await process_frame
	check(not app.inventory_view and app.action_buttons.has("inventory"), "back to original hub")
	app.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("inventory_stash_tests: ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
