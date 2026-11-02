extends RefCounted
## Composition only; the HUD/model still owns every expedition command.
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const Model := preload("res://scripts/domain/dungeon_state_model.gd")
var inspector_scroll: ScrollContainer
var map_heading: Label
var light_summary: Label
var shade: ColorRect

func setup(hud) -> void:
	hud.theme = UI.theme()
	var leather := TextureRect.new()
	leather.texture = UI.Assets.texture(UI.ART+"leather.png")
	leather.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	leather.stretch_mode = TextureRect.STRETCH_TILE
	leather.modulate = Color(0.42,0.40,0.37)
	leather.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(leather)
	hud.move_child(leather,1)
	var margin: MarginContainer = hud.detail_panel.get_node("MarginContainer")
	for side in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+side,0)
	inspector_scroll = ScrollContainer.new()
	inspector_scroll.name = "ExpeditionInspectorScroll"
	inspector_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(inspector_scroll)
	hud.detail_box.reparent(inspector_scroll)
	hud.detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.detail_box.add_theme_constant_override("separation",16)
	hud.detail_panel.add_theme_stylebox_override("panel",UI.paper_box(28))
	hud.loadout_panel.reparent(hud.detail_box)
	hud.loadout_panel.custom_minimum_size = Vector2.ZERO
	hud.loadout_panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	hud.detail_box.move_child(hud.loadout_panel,2)
	hud.action_row.columns = 1
	hud.map_frame_panel.add_theme_stylebox_override("panel",UI.paper_box(24))
	map_heading = UI.label(hud,"MINE CHART",28,UI.INK)
	light_summary = UI.label(hud,"",24,UI.GOLD)
	_resources(hud)
	for card: PanelContainer in hud.party_cards.values():
		card.add_theme_stylebox_override("panel",UI.frame("frame_dark",10))
		card.custom_minimum_size = Vector2(180,0)
		for side in ["left","top","right","bottom"]: card.get_node("Margin").add_theme_constant_override("margin_"+side,4)
		card.get_node("Margin/Content").add_theme_constant_override("separation",3)
		card.get_node("Margin/Content/Name").add_theme_font_size_override("font_size",24)
		card.hp_label.add_theme_font_size_override("font_size",24)
	hud.party_log_label.custom_minimum_size.x = 180
	hud.party_log_label.custom_minimum_size.y = 120
	hud.party_log_label.add_theme_font_size_override("font_size",24)
	hud.party_log_label.max_lines_visible = 4
	hud.party_log_label.clip_text = true
	hud.party_panel.add_theme_stylebox_override("panel",UI.frame("frame_dark",14))
	_style_text(hud.detail_box,UI.INK)
	hud.panel_title.add_theme_font_override("font",UI.heading_font())
	hud.panel_title.add_theme_font_size_override("font_size",32)
	hud.title_label.add_theme_font_override("font",UI.heading_font())
	hud.title_label.add_theme_font_size_override("font_size",44)
	hud.title_label.add_theme_color_override("font_color",UI.GOLD)
	hud.title_label.max_lines_visible = 1
	hud.status_label.add_theme_font_size_override("font_size",24)
	hud.status_label.add_theme_color_override("font_color",UI.MUTED)
	hud.status_label.max_lines_visible = 1
	hud.status_label.clip_text = true
	hud.status_label.hide()
	hud.progress_label.hide()
	for button: Button in hud.find_children("*","Button",true,false): style_button(button)
	_event(hud)
	layout(hud)
	refresh(hud)
	_settle(hud)

func _settle(hud) -> void:
	await hud.get_tree().process_frame
	await hud.get_tree().process_frame
	if is_instance_valid(hud) and hud.is_inside_tree(): layout(hud)

func _style_text(parent: Node,color: Color) -> void:
	for label: Label in parent.find_children("*","Label",true,false):
		label.add_theme_font_override("font",UI.body_font())
		label.add_theme_font_size_override("font_size",24)
		label.add_theme_color_override("font_color",color)

func style_button(button: Button) -> void:
	for state in ["normal","hover","pressed","disabled","focus"]: button.remove_theme_stylebox_override(state)
	button.add_theme_font_size_override("font_size",24)
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size.y = 60
	if button.text in ["+","-"]: button.custom_minimum_size.x = 64
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.tooltip_text = button.text
	button.add_theme_stylebox_override("focus",UI.focus_box())

func _resources(hud) -> void:
	for child in hud.resource_tray_panel.get_children():
		hud.resource_tray_panel.remove_child(child)
		child.queue_free()
	hud.resource_tray_panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	hud.resource_tray_panel.add_child(row)
	hud.resource_tiles.clear()
	hud.resource_tile_labels.clear()
	var glyphs := {"torch":"oil","pickaxe":"pickaxe","trap_tools":"trap","bandage":"bandage","camping_kit":"tent","food":"food"}
	var names := {"torch":"Oil","pickaxe":"Pick","trap_tools":"Tools","bandage":"Heal","camping_kit":"Camp","food":"Food"}
	for id: String in hud._resource_tile_ids():
		var tile := PanelContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.add_theme_stylebox_override("panel",UI.frame("frame_metal",12))
		tile.mouse_filter = Control.MOUSE_FILTER_STOP
		row.add_child(tile)
		var box := HBoxContainer.new()
		box.add_theme_constant_override("separation",8)
		tile.add_child(box)
		var art := TextureRect.new()
		art.texture = UI.icon(glyphs[id])
		art.custom_minimum_size = Vector2(32,32)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(art)
		var name := UI.label(box,names[id],24,UI.MUTED)
		name.name = "ResourceName"
		name.autowrap_mode = TextServer.AUTOWRAP_OFF
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var value := UI.label(box,"0",28,UI.GOLD)
		value.autowrap_mode = TextServer.AUTOWRAP_OFF
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		value.custom_minimum_size.x = 32
		hud.resource_tiles[id] = tile
		hud.resource_tile_labels[id] = value

func layout(hud) -> void:
	var view: Vector2 = hud.get_viewport_rect().size
	var footer_height := 224.0 if view.y >= 1000 else 176.0
	for label: Label in hud.resource_tray_panel.find_children("ResourceName","Label",true,false): label.visible=view.x>=1800
	if not hud.layout_edit_enabled:
		var detail_width := clampf(view.x*0.28,420,720)
		var map_width := view.x-detail_width-72
		hud.detail_area = Rect2(view.x-detail_width-24,140,detail_width,view.y-164)
		hud.resource_tray_area = Rect2(24,140,map_width,80)
		hud.party_area = Rect2(24,view.y-footer_height-24,map_width,footer_height)
		hud.map_area = Rect2(24,236,map_width,maxf(180,hud.party_area.position.y-252))
		hud.loadout_area = Rect2(hud.detail_area.position+Vector2(28,120),Vector2(detail_width-56,960))
	var header: MarginContainer = hud.get_node("Header")
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	header.position = Vector2(24,18)
	header.size = Vector2(view.x-440,110)
	for side in ["left","top","right","bottom"]: header.add_theme_constant_override("margin_"+side,0)
	hud.world_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	hud.world_button.position = Vector2(view.x-388,32)
	hud.world_button.size = Vector2(364,68)
	for entry in [[hud.detail_panel,hud.detail_area],[hud.map_frame_panel,hud.map_area],[hud.resource_tray_panel,hud.resource_tray_area],[hud.party_panel,hud.party_area]]:
		var control: Control = entry[0]
		var rect: Rect2 = entry[1]
		control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		control.custom_minimum_size = Vector2.ZERO
		control.position = rect.position
		control.size = rect.size
	map_heading.position = hud.map_area.position+Vector2(28,18)
	map_heading.size = Vector2(hud.map_area.size.x-56,42)
	light_summary.position = Vector2(24,96)
	light_summary.size = Vector2(view.x-48,32)
	for card: PanelContainer in hud.party_cards.values():
		card.get_node("Margin/Content/Portrait").custom_minimum_size.y = 82 if footer_height>200 else 36
	hud.loadout_panel.custom_minimum_size = Vector2.ZERO
	hud.detail_label.visible = not hud._loadout_pending()
	for row: Dictionary in hud.loadout_rows.values():
		var supply_name: Label = row.value_label.get_parent().get_child(0)
		supply_name.custom_minimum_size.x = 112
		supply_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		supply_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud._recalculate_graph_transform()
	var rect := map_scroll_rect(hud)
	hud.map_scroll_container.position = rect.position
	hud.map_scroll_container.custom_minimum_size = Vector2.ZERO
	hud.map_scroll_container.size = rect.size
	hud.graph_layer.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	hud.graph_layer.position = Vector2.ZERO
	hud.graph_layer.custom_minimum_size = hud.graph_content_size
	hud.graph_layer.size = hud.graph_content_size
	center_event(hud)

func map_scroll_rect(hud) -> Rect2:
	return Rect2(hud.map_area.position+Vector2(24,68),(hud.map_area.size-Vector2(48,92)).max(Vector2(120,120)))

func _event(hud) -> void:
	var popup: Control = hud.corridor_event_panel
	var background: NinePatchRect = popup.get_child(0)
	background.texture = UI.Assets.texture(UI.ART+"frame_paper.png")
	for side in ["left","right","top","bottom"]: background.set("patch_margin_"+side,36)
	var margin: MarginContainer = popup.get_child(1)
	margin.offset_left = 36
	margin.offset_top = 32
	margin.offset_right = -36
	margin.offset_bottom = -32
	var column: VBoxContainer = margin.get_child(0)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	column.reparent(scroll)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",20)
	_style_text(popup,UI.INK)
	hud.corridor_event_title_label.add_theme_font_override("font",UI.heading_font())
	hud.corridor_event_title_label.add_theme_font_size_override("font_size",36)
	shade = ColorRect.new()
	shade.name = "EventBackdrop"
	shade.color = Color(0,0,0,0.62)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.visible = false
	hud.add_child(shade)
	hud.move_child(popup,-1)
	popup.visibility_changed.connect(func() -> void: shade.visible=popup.visible)

func center_event(hud) -> void:
	if hud.corridor_event_panel==null: return
	var popup: Control = hud.corridor_event_panel
	var view: Vector2 = hud.get_viewport_rect().size
	popup.custom_minimum_size = Vector2.ZERO
	popup.size = Vector2(minf(960,view.x-64),minf(620,view.y-64))
	popup.position = (view-popup.size)/2
	for button: Button in hud.corridor_hazard_choice_buttons:
		style_button(button)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y = 84

func refresh(hud) -> void:
	if light_summary==null: return
	light_summary.text = "Light %s / %s  |  %s  |  %s" % [hud.run_state.get("light_level",0),hud.run_state.get("max_light_level",4),str(hud.run_state.get("light_state","bright")).capitalize(),hud._route_state_text()]
	hud.status_label.tooltip_text = hud._status_summary()
	hud.party_log_label.tooltip_text = hud._party_log_text()+"\n"+hud._progress_summary()
	hud.detail_label.visible = not hud._loadout_pending()
	for button: Button in hud.generated_difficulty_buttons:
		style_button(button)
		if int(button.text.trim_prefix("D"))==hud.generated_dungeon_difficulty: UI.select_button(button)
	for id: String in hud.room_nodes:
		var stamp: Label = hud.room_nodes[id].get_node_or_null("RoomBody/State")
		if stamp!=null: stamp.text = "HERE" if id==str(hud.run_state.get("current_room_id","")) else hud._room_state_summary(id).to_upper()

func room_style(hud,id: String,kind: String) -> StyleBox:
	var tint := Color(1.15,0.72,0.58) if kind in ["combat","guarded_treasure"] else Color(0.88,0.85,0.75)
	if Model.room_is_cleared(hud.run_state,id): tint=Color(0.85,1.0,0.80)
	if id==str(hud.run_state.get("current_room_id","")): tint=Color(1.45,1.18,0.72)
	return UI.frame("frame_metal",12,tint)

func room_panel(hud,room: Dictionary) -> PanelContainer:
	var id: String = room.id
	var panel := PanelContainer.new()
	panel.position = hud._room_screen_position(room)
	panel.size = hud.room_node_size
	panel.custom_minimum_size = hud.room_node_size
	panel.add_theme_stylebox_override("panel",room_style(hud,id,str(room.kind)))
	var box := VBoxContainer.new()
	box.name = "RoomBody"
	box.add_theme_constant_override("separation",4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)
	var kind: String = str(room.kind)
	var illustration := "entrance" if id==str(hud.dungeon.start_room_id) else ("locked" if room.has("locked_by_item_id") else ("spider" if kind=="combat" else kind))
	if kind=="empty": illustration="shrine" if not room.get("content",[]).filter(func(c):return c.get("type")=="room_event").is_empty() else "tunnel"
	var path := UI.ART+"rooms/"+illustration+".png"
	var art := TextureRect.new()
	art.texture = UI.Assets.texture(path if ResourceLoader.exists(path) else hud._room_icon_path(room))
	art.custom_minimum_size = Vector2(128,90)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(art)
	var name := UI.label(box,str(room.display_name),24)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.custom_minimum_size.y = 62
	name.max_lines_visible = 2
	var stamp := UI.label(box,"",24,UI.GOLD)
	stamp.name = "State"
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var hit := Button.new()
	hit.name = "RoomHit"
	hit.flat = true
	hit.tooltip_text = str(room.display_name)
	hit.focus_mode = Control.FOCUS_ALL
	for state in ["normal","disabled"]: hit.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	for state in ["hover","pressed","focus"]: hit.add_theme_stylebox_override(state,UI.focus_box())
	hit.pressed.connect(func() -> void: hud._try_enter_room(id))
	panel.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return panel
