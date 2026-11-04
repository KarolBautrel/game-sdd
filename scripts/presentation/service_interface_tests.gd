extends SceneTree
var errors: Array[String] = []
var checks := 0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: errors.append(message)
func frames() -> void:
	for frame in range(5): await process_frame
func _run() -> void:
	var campaign := root.get_node("CampaignSession")
	campaign.load_profile("",true)
	campaign.state.xp = 10
	var before: Dictionary = campaign.state.duplicate(true)
	var app: Control = load("res://scenes/town/town_shell.tscn").instantiate()
	root.add_child(app)
	await frames()
	app.action_buttons.trade.pressed.emit()
	await frames()
	var trade := app.find_child("TradingView",true,false)
	var offers: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/town_trade/ravenford.json"))
	check(trade.buy_grid.item_buttons.size() == offers.offers.size() and trade.buy_grid.item_buttons.has("closed_helm") and trade.buy_grid.item_buttons.has("steel_boots") and trade.buy_grid.item_buttons.has("hero_greatsword") and trade.sell_grid.item_buttons.is_empty(),"visual merchant includes canonical appearance/identity gear and protects starters")
	trade.buy_grid.item_buttons.salvaged_blade.pressed.emit()
	check(campaign.state == before,"merchant tile selection no save")
	trade.buy_button.pressed.emit()
	await frames()
	trade = app.find_child("TradingView",true,false)
	check(campaign.state.gold == 24 and trade.selected_buy_id() == "salvaged_blade" and trade.sell_grid.item_buttons.has("salvaged_blade"),"actual grid buy/retention/free copy")
	trade.sell_grid.item_buttons.salvaged_blade.pressed.emit()
	trade.sell_button.pressed.emit()
	await frames()
	trade = app.find_child("TradingView",true,false)
	check(campaign.state.gold == 31 and trade.sell_button.disabled and trade.sell_grid.item_buttons.is_empty(),"actual grid sell/empty state")
	app.shell.nav_buttons.training.pressed.emit()
	await frames()
	var training := app.find_child("TrainingView",true,false)
	check(training.xp_bars.unit_player_001.value == 10 and training.next_stats.unit_player_001.strength == 6,"training budget bar and trusted next stats")
	training.train_buttons.unit_player_001.mouse_entered.emit()
	training.train_buttons.unit_player_001.pressed.emit()
	await frames()
	training = app.find_child("TrainingView",true,false)
	check(campaign.available_xp() == 0 and training.train_buttons.unit_player_002.disabled and training.xp_bars.unit_player_002.value == 0,"advance refresh updates shared budget")
	training.train_buttons.unit_player_001.mouse_exited.emit()
	app.queue_free()
	await frames()
	for error in errors: push_error(error)
	print("service_interface_tests: ",checks," checks, ",errors.size()," failures")
	quit(0 if errors.is_empty() else 1)
