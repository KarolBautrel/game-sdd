extends Control
signal scene_requested(path: String)

const Campaign := preload("res://scripts/session/campaign_session.gd")
const Party := preload("res://scripts/domain/party_roster.gd")
const Model := preload("res://scripts/domain/dungeon_state_model.gd")
const Advancement := preload("res://scripts/domain/party_advancement.gd")
const PixelSkin := preload("res://scripts/presentation/shared/pixel_skin.gd")
const PartyCard := preload("res://scenes/ui/PartyCard.tscn")
const Travel := preload("res://scripts/domain/world_travel.gd")
const RegionMap := preload("res://scripts/presentation/world/region_map.gd")
const InventoryView := preload("res://scripts/presentation/world/inventory_view.gd")
const Items := preload("res://scripts/domain/item_catalog.gd")
const EquipmentView := preload("res://scripts/presentation/world/equipment_view.gd")
const TradingView := preload("res://scripts/presentation/world/trading_view.gd")
const TrainingView := preload("res://scripts/presentation/world/training_view.gd")
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const CampaignShell := preload("res://scripts/presentation/world/campaign_shell.gd")
const CampaignColumns := preload("res://scripts/presentation/world/campaign_columns.gd")
const FRAME := "res://assets/ui/dungeon/processed/dungeon_ui/dungeon_ui_10.png"
@export var town_view := false
var skin := PixelSkin.new()
var shell: Control
var content: VBoxContainer
var feedback: Label
var action_buttons: Dictionary = {}
var inventory_view := false
var trading_view := false
var training_view := false
var trade_buy_id := ""
var trade_sell_id := ""
var inventory_item_id := ""
var inventory_category := "all"
var inventory_hero_id := "unit_player_001"
var inventory_slot := "main_hand"
var journey_destination := ""
var viewed_province := "marches"


func _ready() -> void:
	var campaign := _campaign()
	if not campaign.loaded:
		if "--hero-equipment-pilot" in OS.get_cmdline_user_args() or bool(ProjectSettings.get_setting("debug/qa/hero_equipment_pilot", false)):
			preload("res://scripts/qa/hero_equipment_pilot.gd").open(campaign)
			inventory_view = true
		else:
			campaign.load_profile("user://campaign_v1.json", DisplayServer.get_name() == "headless")
	if campaign.living_active():
		var requested: String=campaign.requested_campaign_tab
		campaign.requested_campaign_tab=""
		if requested in ["stash","trade","training"]:
			inventory_view=requested=="stash"
			trading_view=requested=="trade"
			training_view=requested=="training"
			town_view=requested!="stash"
		else:
			_go_scene.call_deferred("res://scenes/world/LivingWorld.tscn")
			return
	if campaign.loaded: viewed_province = Travel.province_id(campaign.state.world.location_id)
	_render()


func _go_scene(path: String) -> void:
	if scene_requested.has_connections(): scene_requested.emit(path)
	else: get_tree().change_scene_to_file(path)


func _render() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	action_buttons.clear()
	shell = CampaignShell.new()
	shell.name = "CampaignShell"
	add_child(shell)
	content = shell.content
	feedback = shell.feedback
	var campaign := _campaign()
	if not campaign.loaded:
		shell.configure("Campaign unavailable", "", {}, "region", false, false)
		feedback.text = campaign.last_feedback
		return
	var profile: Dictionary = campaign.state
	var selected := "training" if training_view else ("trade" if trading_view else ("stash" if inventory_view else ("town" if town_view else "region")))
	var titles := {"region":"The Crownlands", "town":"Ravenford", "stash":"Stash & equipment", "trade":"Trading Post", "training":"Party advancement"}
	shell.configure(titles[selected], "%s  /  %s" % [Travel.node_name(profile.world.location_id),Travel.clock_text(profile.world)], {"Gold":"%sg" % int(profile.gold),"Available XP":str(campaign.available_xp()),"Food":str(int(profile.supplies.food))}, selected, campaign.at_town() and (not campaign.living_active() or profile.world.location_id=="town_ravenford"), campaign.can_trade())
	shell.navigation_requested.connect(_navigate)
	feedback.text = campaign.last_feedback
	feedback.tooltip_text = campaign.last_feedback
	_render_party(profile)
	if training_view:
		var training := TrainingView.new()
		training.name = "TrainingView"
		content.add_child(training)
		training.configure(profile.advancement,int(profile.xp),campaign.can_trade())
		training.train_requested.connect(func(id: String) -> void:
			campaign.train(id)
			_render()
		)
		_button("close_training","Back to town services",func() -> void:
			training_view = false
			_render()
		)
		return
	if trading_view:
		var trading := TradingView.new()
		trading.name = "TradingView"
		content.add_child(trading)
		trading.configure(profile.items,profile.equipment,int(profile.gold),campaign.can_trade(),trade_buy_id,trade_sell_id)
		trading.buy_requested.connect(_trade_buy)
		trading.sell_requested.connect(_trade_sell)
		_button("close_trade","Back to town services",_close_trade)
		return
	if inventory_view:
		var view := InventoryView.new()
		view.name = "InventoryView"
		view.configure(profile.items,profile.equipment,inventory_item_id,inventory_category)
		var equipment := EquipmentView.new()
		equipment.name = "EquipmentView"
		content.add_child(equipment)
		var hero_details: Dictionary = {}
		var party_state: Dictionary = profile.effects.duplicate(true) if profile.active_run.is_empty() else profile.active_run.state.duplicate(true)
		party_state.party_formation = Party.default_party_formation()
		for hero: Dictionary in Party.default_party():
			var id: String = hero.combat_unit_id
			hero_details[id] = {"level":int(profile.advancement[id]),"hp":Model.party_member_hp(party_state,id),"stats":Advancement.stats(id,int(profile.advancement[id]))}
		equipment.configure(profile.items,profile.equipment,not profile.active_run.is_empty() or not profile.world.pending_event.is_empty(),{"hero":inventory_hero_id,"item":inventory_item_id,"slot":inventory_slot},hero_details)
		equipment.attach_inventory(view)
		view.item_selected.connect(func(id: String) -> void:
			inventory_item_id = id
			equipment.select_item(id)
			inventory_slot = equipment.selected_slot
		)
		view.category_changed.connect(func(category: String) -> void: inventory_category = category)
		equipment.hero_selected.connect(func(id: String) -> void: inventory_hero_id = id)
		equipment.item_focused.connect(func(id: String) -> void:
			inventory_item_id = id
			view.select_item(id)
		)
		equipment.slot_selected.connect(func(slot: String) -> void:
			inventory_slot = slot
			view.highlight_slot(slot)
		)
		equipment.equip_requested.connect(func(hero_id: String,slot: String,item_id: Variant) -> void:
			var scroll_before: int=view.entries_scroll.scroll_vertical
			campaign.equip(hero_id,slot,item_id)
			_render()
			var restored: Control=find_child("InventoryView",true,false)
			if restored!=null: restored.restore_position(scroll_before,inventory_item_id)
		)
		_button("close_stash","Back",_close_stash)
		return
	if town_view:
		_render_town(profile)
	else:
		_render_region(profile)


func _render_party(profile: Dictionary) -> void:
	var party_state: Dictionary = profile.effects.duplicate(true) if profile.active_run.is_empty() else profile.active_run.state.duplicate(true)
	party_state.party_formation = Party.default_party_formation()
	UI.label(shell.rail,"YOUR COMPANY",20,UI.GOLD)
	var compact: Array[String] = []
	for hero: Dictionary in Party.default_party():
		var hp := Model.party_member_hp(party_state,str(hero.combat_unit_id))
		var level := int(profile.advancement[hero.combat_unit_id])
		compact.append("%s Lv%s  HP%s/%s" % [hero.display_name,level,hp,hero.stats.max_hp])
		var card := PartyCard.instantiate()
		card.configure(hero,hp,UI.GOLD,UI.box())
		card.custom_minimum_size = Vector2(220,190)
		card.get_node("Margin/Content/Name").add_theme_font_size_override("font_size",22)
		card.hp_label.add_theme_font_size_override("font_size",18)
		card.get_node("Margin/Content/Portrait").custom_minimum_size.y = 100
		shell.rail.add_child(card)
		UI.label(shell.rail,"%s  /  Level %s" % [hero.class_name,level],20,UI.MUTED)
	var supplies := UI.card(shell.rail,"Supplies")
	for key: String in Campaign.PRICES:
		UI.label(supplies,"%s   %s" % [Campaign.SUPPLY_NAMES[key],int(profile.supplies[key])],20,UI.MUTED)
	shell.compact_summary.text = "  |  ".join(compact)


func _render_town(profile: Dictionary) -> void:
	var main := content
	var columns := CampaignColumns.new()
	main.add_child(columns)
	var banner := UI.card(main,"Ravenford","Provisioner  /  Trading Post  /  Inn  /  Training grounds")
	banner.get_parent().add_theme_stylebox_override("panel",UI.hero_frame())
	var town_art := TextureRect.new()
	town_art.texture = load("res://assets/ui/campaign/ravenford.png")
	town_art.custom_minimum_size.y = 230
	town_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	town_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	town_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(town_art)
	main.move_child(banner.get_parent(),0)
	content = UI.card(columns,"Provisioner","Supplies go to your company stash.")
	var supplies := GridContainer.new()
	supplies.columns = 3
	supplies.add_theme_constant_override("h_separation",10)
	supplies.add_theme_constant_override("v_separation",10)
	content.add_child(supplies)
	for key: String in Campaign.PRICES:
		var tile := _button("buy_"+key,"",func() -> void: _buy(key),supplies)
		tile.custom_minimum_size = Vector2(120,148)
		tile.disabled = not _campaign().can_trade() or int(profile.gold) < _campaign().supply_price(key)
		tile.tooltip_text = "Buy %s for %sg / Owned %s" % [Campaign.SUPPLY_NAMES[key],_campaign().supply_price(key),int(profile.supplies[key])]
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,10)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(margin)
		var body := VBoxContainer.new()
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(body)
		var supply_icons := {"food":"food","bandage":"bandage","camping_kit":"tent","pickaxe":"pickaxe","trap_tools":"trap","lamp_oil":"oil"}
		var supply_icon := TextureRect.new()
		supply_icon.texture = UI.icon(str(supply_icons.get(key,"food")))
		supply_icon.custom_minimum_size.y = 40
		supply_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		supply_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		supply_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(supply_icon)
		UI.label(body,Campaign.SUPPLY_NAMES[key],18)
		UI.label(body,"%sg  /  Owned %s" % [_campaign().supply_price(key),int(profile.supplies[key])],18,UI.GOLD)
	content = UI.card(columns,"Town services","Trade, recover and develop your company before the next journey.")
	_button("trade","Trading Post  /  Equipment & loot",_open_trade).disabled = not _campaign().can_trade()
	_button("training","Training grounds  /  Allocate XP",_open_training).disabled = not _campaign().can_trade()
	_button("recover","Rest at the inn  /  5g",_recover).disabled = not _campaign().can_trade() or int(profile.gold) < 5
	if not _campaign().can_trade(): _label("Services unlock after the current expedition or road event is resolved.",20,UI.MUTED)
	content = main
	_button("inventory","Open stash",_open_stash)
	_button("world","Return to region",func() -> void: _navigate("region"))


func _render_region(profile: Dictionary) -> void:
	var main := content
	var region := Travel.region()
	var navigation := HFlowContainer.new()
	navigation.add_theme_constant_override("h_separation",10)
	navigation.add_theme_constant_override("v_separation",8)
	main.add_child(navigation)
	_button("world_overview","World atlas",func() -> void: _view_province(""),navigation)
	for province: Dictionary in region.provinces:
		var id: String = province.id
		var tab := _button("province_"+id,str(province.name),func() -> void: _view_province(id),navigation)
		if viewed_province == id: UI.select_button(tab)
	_button("company_location","Find company",func() -> void: _view_province(Travel.province_id(profile.world.location_id)),navigation)
	var compact := get_viewport_rect().size.x < 1500
	for button: Button in navigation.get_children():
		button.add_theme_font_size_override("font_size",20 if compact else 26)
		button.custom_minimum_size = Vector2(button.get_theme_font("font").get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,20 if compact else 26).x+36,44 if compact else 68)
		if compact:
			for state in ["normal","hover","pressed","disabled"]: button.add_theme_stylebox_override(state,UI.frame("frame_metal",8))
	var layout := preload("res://scripts/presentation/world/region_layout.gd").new()
	main.add_child(layout)
	var province := Travel.province(region,viewed_province)
	var map_title := str(region.name) + " / World" if viewed_province.is_empty() else str(province.name)
	var subtitle := "4 provinces  /  20 destinations  /  Select a province" if viewed_province.is_empty() else str(province.description)
	var map_panel := UI.card(layout,"" if compact else map_title,"" if compact else subtitle)
	if compact:
		map_panel.get_parent().add_theme_stylebox_override("panel",UI.frame("frame_dark",16))
		UI.label(map_panel,map_title,24,UI.GOLD).tooltip_text=subtitle
	map_panel.get_parent().size_flags_stretch_ratio = 2.8
	var map := RegionMap.new()
	map.name = "RegionMap"
	map_panel.add_child(map)
	var quotes: Dictionary = {}
	for entry: Dictionary in region.nodes:
		var plan := Travel.plan(profile.world,entry.id)
		if plan.is_empty(): continue
		quotes[entry.id] = {"inspect_allowed":profile.active_run.is_empty() and profile.world.pending_event.is_empty(),"tooltip":"%s / %s stops / %sh / %s food\n%s" % [entry.name,plan.legs.size(),plan.time_hours,plan.food,entry.description]}
	if Travel.plan(profile.world,journey_destination).is_empty(): journey_destination=""
	map.configure(region,profile.world.location_id,quotes,journey_destination,viewed_province)
	map.destination_selected.connect(_preview_journey)
	map.province_selected.connect(_view_province)
	UI.label(map_panel,"Company: %s / %s" % [Travel.node_name(profile.world.location_id),Travel.province(region,Travel.province_id(profile.world.location_id)).name],18 if compact else 22,UI.GOLD)
	if not compact: UI.label(map_panel,"Select a landmark to plan a route. Red ink marks the selected journey.",20,UI.MUTED)
	var columns := VBoxContainer.new()
	columns.custom_minimum_size.x = 360
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",18)
	layout.add_child(columns)
	content = UI.card(columns,"Journey","%s  /  %s" % [Travel.node_name(profile.world.location_id),Travel.clock_text(profile.world)])
	if not profile.world.pending_event.is_empty(): _render_road_event(profile.world.pending_event)
	elif not profile.active_run.is_empty():
		_label("Your expedition is in progress. Resume its saved checkpoint.",22)
		_button("resume","Resume expedition",_resume)
	else:
		if journey_destination.is_empty():
			for route: Dictionary in Travel.routes(region,profile.world.location_id):
				var destination: String = route.to
				var quote := Travel.quote(profile.world,destination)
				var text := "%s  /  %sh  /  %s food" % [Travel.node_name(destination),quote.time_hours,quote.food]
				var caption := "%s\n%sh / %s food" % [Travel.node_name(destination),quote.time_hours,quote.food] if compact else "Inspect "+text
				_button("travel_"+destination,caption,func() -> void: _preview_journey(destination))
				_label("Danger %s%%  /  Return reserve %s food" % [int(quote.danger*100),quote.return_food],20,UI.MUTED)
		_render_journey_preview(profile)
	content = UI.card(columns,"At the company location",str(Travel.node(region,profile.world.location_id).description))
	_button("town","Enter Ravenford",func() -> void: _navigate("town")).disabled = not _campaign().at_town()
	if profile.active_run.is_empty(): _button("prepare","Old Mine  /  Prepare expedition",_prepare).disabled = profile.world.location_id != "dungeon_old_mine" or not profile.world.pending_event.is_empty()
	_button("inventory","Open stash",_open_stash)
	if profile.world.last_journey.has("event_result"): _label("Last road event: "+str(profile.world.last_journey.event_result).capitalize(),20,UI.MUTED)
	_button("living_world","Living Marches / Mercenary pilot",func() -> void: _go_scene("res://scenes/world/LivingWorld.tscn"))
	if not profile.last_return.is_empty(): _label("Last expedition: %s  /  +%sg  +%s XP  /  %s items" % [profile.last_return.outcome,int(profile.last_return.gold),int(profile.last_return.xp),profile.last_return.items.size()],20,UI.MUTED)
	content = main


func _view_province(id: String) -> void:
	if id != "" and Travel.province(Travel.region(),id).is_empty(): return
	viewed_province = id
	_render()
	shell.body_scroll.scroll_vertical = 0
	var key := "world_overview" if id.is_empty() else "province_"+id
	UI.focus_later(action_buttons[key])


func _navigate(id: String) -> void:
	if _campaign().living_active() and id=="region":
		_go_scene("res://scenes/world/LivingWorld.tscn")
		return
	if _campaign().living_active() and id=="town" and _campaign().state.world.location_id!="town_ravenford": return
	if id == "town" and not _campaign().at_town(): return
	if id in ["trade","training"] and not _campaign().can_trade(): return
	inventory_view = id == "stash"
	trading_view = id == "trade"
	training_view = id == "training"
	if id == "region": town_view = false
	if id in ["town","trade","training"]: town_view = true
	_render()


func _label(text: String, font_size: int, color: Color = UI.TEXT) -> Label:
	if shell.selected_tab == "region" and get_viewport_rect().size.x < 1500: font_size = mini(font_size,20)
	return UI.label(content,text,font_size,color)


func _button(id: String,text: String,callback: Callable,parent: Node = null) -> Button:
	var button := UI.button(text,id in ["prepare","resume","event_fight"] or id.begins_with("travel_"))
	if shell.selected_tab == "region" and get_viewport_rect().size.x < 1500: button.add_theme_font_size_override("font_size",20)
	button.pressed.connect(callback)
	(parent if parent != null else content).add_child(button)
	action_buttons[id] = button
	return button


func _buy(key: String) -> void:
	_campaign().purchase(key)
	_render()


func _recover() -> void:
	_campaign().recover()
	_render()


func _prepare() -> void:
	if not _campaign().loaded or not _campaign().state.active_run.is_empty() or _campaign().state.world.location_id != "dungeon_old_mine" or not _campaign().state.world.pending_event.is_empty():
		return
	var session := get_node("/root/DungeonRunSession")
	session.clear()
	session.town_preparation = true
	get_tree().change_scene_to_file("res://scenes/dungeon/DungeonDebug.tscn")


func _resume() -> void:
	var session := get_node("/root/DungeonRunSession")
	if session.restore_campaign():
		get_tree().change_scene_to_file("res://scenes/dungeon/DungeonDebug.tscn")


func _campaign() -> Node:
	return get_node("/root/CampaignSession")


func _travel(destination: String) -> void:
	if _campaign().travel(destination):
		viewed_province = Travel.province_id(destination)
		if destination == journey_destination: journey_destination=""
	_render()


func _preview_journey(destination: String) -> void:
	var campaign:=_campaign()
	if not campaign.loaded or not campaign.state.active_run.is_empty() or not campaign.state.world.pending_event.is_empty() or Travel.plan(campaign.state.world,destination).is_empty(): return
	journey_destination=destination
	_render()
	var button: Button=action_buttons.get("travel_confirm")
	if button!=null and not button.disabled:
		UI.focus_later(button)
		_reveal_journey(button)
	elif action_buttons.has("travel_cancel"):
		UI.focus_later(action_buttons.travel_cancel)
		_reveal_journey(action_buttons.travel_cancel)


func _reveal_journey(button: Button) -> void:
	await get_tree().process_frame
	if not is_instance_valid(button) or not button.is_inside_tree(): return
	var ancestor: Node=button.get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer: ancestor.ensure_control_visible(button)
		ancestor=ancestor.get_parent()


func _render_journey_preview(profile: Dictionary) -> void:
	if journey_destination.is_empty():
		_label("Select a destination to inspect the journey before leaving.",22,UI.MUTED)
		return
	var plan := Travel.plan(profile.world,journey_destination)
	if plan.is_empty(): return
	var quote: Dictionary = plan.legs[0]
	UI.rule(content)
	_label("To "+Travel.node_name(journey_destination),28,UI.GOLD)
	_label(str(Travel.node(Travel.region(),journey_destination).description),22,UI.MUTED)
	if plan.legs.size() > 1:
		if Travel.node(Travel.region(),journey_destination).type == "town": _label("Return route / conserves provisions",22,UI.GOLD)
		_label("Whole route: %s legs / %sh / %s food\nCarry %s food to cover every leg and its return reserve." % [plan.legs.size(),plan.time_hours,plan.food,plan.required_food],22,UI.GOLD).name="JourneyTotals"
		var stops: Array[String] = []
		for index in range(plan.stops.size()): stops.append("%s. %s" % [index+1,Travel.node_name(plan.stops[index])])
		_label("\n".join(stops),22,UI.MUTED).name="JourneyItinerary"
		_label("Next stop: "+Travel.node_name(quote.to),26,UI.GOLD)
		_label("Travel one leg, resolve any road event, then continue.",20,UI.MUTED)
	_label("Road danger %s%%" % int(quote.danger*100),24,UI.MUTED)
	var arrival: Dictionary=profile.world.duplicate(true)
	arrival.elapsed_hours=int(arrival.elapsed_hours)+int(quote.time_hours)
	_label("Arrival before road events: "+Travel.clock_text(arrival),24).name="JourneyArrival"
	var left: int=int(profile.supplies.food)-int(quote.food)
	_label("Spend %s food  /  %s hours" % [quote.food,quote.time_hours],24)
	_label("After travel: %s food\nKeep %s for return; %s remains beyond the reserve." % [maxi(0,left),quote.return_food,maxi(0,left-int(quote.return_food))],24,UI.MUTED).name="JourneyReserve"
	var enough: bool=int(profile.supplies.food)>=int(quote.food)+int(quote.return_food)
	if not enough: _label("Need %s food for this trip and return reserve; carrying %s." % [int(quote.food)+int(quote.return_food),profile.supplies.food],24,Color("e2a487"))
	elif int(profile.supplies.food)<int(plan.required_food): _label("Whole route needs %s more food. You can travel only the next leg with the current provisions." % [int(plan.required_food)-int(profile.supplies.food)],22,Color("e2a487"))
	var confirm:=_button("travel_confirm","Travel to "+Travel.node_name(quote.to),_confirm_journey.bind(str(quote.from),int(profile.world.journey_count)))
	confirm.disabled=not enough
	_button("travel_cancel","Cancel journey plan",_cancel_journey)


func _confirm_journey(expected_from: String = "",expected_count: int = -1) -> void:
	var world: Dictionary = _campaign().state.world
	if expected_count >= 0 and (world.location_id != expected_from or int(world.journey_count) != expected_count): return
	var plan := Travel.plan(_campaign().state.world,journey_destination)
	if not plan.is_empty(): _travel(str(plan.legs[0].to))


func _cancel_journey() -> void:
	var previous:=journey_destination
	journey_destination=""
	_render()
	if action_buttons.has("travel_"+previous): UI.focus_later(action_buttons["travel_"+previous])
	else:
		var map := find_child("RegionMap",true,false)
		if map != null and map.marker_buttons.has(previous): UI.focus_later(map.marker_buttons[previous])


func _open_stash() -> void:
	training_view = false
	trading_view = false
	inventory_view = true
	_render()


func _close_stash() -> void:
	if _campaign().living_active():
		_go_scene("res://scenes/world/LivingWorld.tscn")
		return
	inventory_view = false
	_render()


func _open_trade() -> void:
	if not town_view or not _campaign().can_trade():
		return
	inventory_view = false
	training_view = false
	trading_view = true
	_render()


func _open_training() -> void:
	if not town_view or not _campaign().can_trade():
		return
	inventory_view = false
	trading_view = false
	training_view = true
	_render()


func _remember_trade_selection() -> void:
	var view := find_child("TradingView", true, false)
	if view != null:
		trade_buy_id = view.selected_buy_id()
		trade_sell_id = view.selected_sell_id()


func _trade_buy(item_id: String) -> void:
	_remember_trade_selection()
	_campaign().purchase_item(item_id)
	_render()


func _trade_sell(item_id: String) -> void:
	_remember_trade_selection()
	_campaign().sell_item(item_id)
	_render()


func _close_trade() -> void:
	_remember_trade_selection()
	trading_view = false
	_render()


func _render_road_event(pending: Dictionary) -> void:
	var definitions := Travel.event_definitions()
	var entry: Dictionary = definitions[pending.kind]
	_label(entry.title, 30, Color("e9c36d"))
	_label(entry.description, 23)
	if pending.kind == "cart":
		for choice: Dictionary in entry.choices:
			var id: String = choice.id
			_button("event_" + id, choice.label, func() -> void: _choose_road_event(id))
	elif pending.phase == "combat":
		_button("resume_ambush", "Resume ambush", _resume_ambush)
	else:
		_button("event_fight", "Fight the bandits", func() -> void: _choose_road_event("fight"))
		_button("event_pay", "Pay toll  /  %sg" % int(entry.toll_gold), func() -> void: _choose_road_event("pay")).disabled = int(_campaign().state.gold) < int(entry.toll_gold)


func _choose_road_event(choice: String) -> void:
	if _campaign().choose_road_event(choice) and choice == "fight":
		_resume_ambush()
	else:
		_render()


func _resume_ambush() -> void:
	var session := get_node("/root/DungeonRunSession")
	if session.restore_road_combat():
		get_tree().change_scene_to_file(session.COMBAT_SCENE_PATH)
