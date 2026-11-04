extends RefCounted
## Composition only; the HUD/model still owns every expedition command.
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const Materials := preload("res://scripts/presentation/dungeon/dungeon_materials.gd")
const Passages := preload("res://scripts/presentation/dungeon/dungeon_passages.gd")
const Model := preload("res://scripts/domain/dungeon_state_model.gd")
const CHART_PATH := "res://assets/ui/dungeon/illustrated/old_mine_chart.png"
const CHART_POSITIONS := {"entrance":Vector2i(0,1),"dusty_crossing":Vector2i(1,1),"collapsed_cache":Vector2i(2,0),"spider_nest":Vector2i(2,2),"guarded_cache":Vector2i(3,1),"lower_exit":Vector2i(4,1),"sealed_armory":Vector2i(4,0)}
const CHART_ANCHORS := {"entrance":Vector2(.09,.64),"dusty_crossing":Vector2(.28,.64),"collapsed_cache":Vector2(.51,.32),"spider_nest":Vector2(.51,.88),"guarded_cache":Vector2(.705,.64),"lower_exit":Vector2(.91,.64),"sealed_armory":Vector2(.91,.32)}
const CHART_LINKS := ["dusty_crossing|entrance","collapsed_cache|dusty_crossing","dusty_crossing|spider_nest","dusty_crossing|guarded_cache","guarded_cache|lower_exit","guarded_cache|sealed_armory"]
var inspector_scroll: ScrollContainer
var map_heading: Label
var light_summary: Label
var shade: ColorRect
var preview_room_id := ""
var preview_box: VBoxContainer
var preview_label: Label
var travel_button: Button
var current_button: Button
var modal_focus_modes: Dictionary = {}
var previous_focus: Control
var passages: Control

func setup(hud) -> void:
	hud.theme = Materials.theme()
	hud.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var leather := Materials.backdrop()
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
	hud.detail_panel.add_theme_stylebox_override("panel",Materials.frame("frame_dark",28))
	hud.loadout_panel.reparent(hud.detail_box)
	hud.loadout_panel.custom_minimum_size = Vector2.ZERO
	hud.loadout_panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	hud.detail_box.move_child(hud.loadout_panel,2)
	hud.action_row.columns = 1
	hud.map_frame_panel.add_theme_stylebox_override("panel",Materials.frame("frame_dark",24))
	map_heading = UI.label(hud,"MINE CHART",28,UI.GOLD)
	light_summary = UI.label(hud,"",24,UI.GOLD)
	_resources(hud)
	for card: PanelContainer in hud.party_cards.values():
		card.add_theme_stylebox_override("panel",Materials.frame("frame_dark",12))
		card.use_expedition_layout(false)
	hud.party_log_label.custom_minimum_size.x = 180
	hud.party_log_label.custom_minimum_size.y = 0
	hud.party_log_label.add_theme_font_size_override("font_size",24)
	hud.party_log_label.max_lines_visible = 4
	hud.party_log_label.clip_text = true
	hud.party_panel.add_theme_stylebox_override("panel",Materials.frame("frame_dark",14))
	_style_text(hud.detail_box,UI.TEXT)
	hud.panel_title.add_theme_font_override("font",UI.heading_font())
	hud.panel_title.add_theme_color_override("font_color",UI.GOLD)
	hud.panel_title.add_theme_font_size_override("font_size",32)
	_preview_controls(hud)
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
	if is_instance_valid(hud) and hud.is_inside_tree():
		layout(hud)
		_follow_company(hud)

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
		tile.add_theme_stylebox_override("panel",Materials.frame("frame_metal",12))
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
	var footer_height := 180.0 if view.y >= 1000 else 152.0
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
		card.use_expedition_layout(view.x<1800)
	hud.party_log_label.max_lines_visible = 3 if view.x>=1800 else 2
	hud.party_log_label.custom_minimum_size.y = 108 if view.x>=1800 else 72
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
	background.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	background.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
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
	if hud._loadout_pending() or hud._expedition_decision_pending() or not hud.run_state.get("pending_combat_request", {}).is_empty() or bool(hud.run_state.get("completed", false)):
		preview_room_id = ""
	light_summary.text = "Light %s / %s  |  %s  |  %s" % [hud.run_state.get("light_level",0),hud.run_state.get("max_light_level",4),str(hud.run_state.get("light_state","bright")).capitalize(),hud._route_state_text()]
	hud.status_label.tooltip_text = hud._status_summary()
	hud.party_log_label.tooltip_text = hud._party_log_text()+"\n"+hud._progress_summary()
	hud.detail_label.visible = not hud._loadout_pending()
	for button: Button in hud.generated_difficulty_buttons:
		style_button(button)
		if int(button.text.trim_prefix("D"))==hud.generated_dungeon_difficulty:
			button.add_theme_stylebox_override("normal",Materials.frame("frame_metal",18,Color(1.2,1.02,.72)))
	for id: String in hud.room_nodes:
		var stamp: Label = hud.room_nodes[id].get_node_or_null("RoomBody/State")
		if stamp!=null:
			stamp.text = "YOU ARE HERE" if id==str(hud.run_state.get("current_room_id","")) else ("SELECTED" if id==preview_room_id else ("PASSAGE" if _adjacent(hud,id) else hud._room_state_summary(id).to_upper()))
	_update_preview(hud)
	if is_instance_valid(passages): passages.select_passage(str(hud.run_state.get("current_room_id","")),preview_room_id)
	_sync_event_focus(hud)

func room_style(hud,id: String,kind: String) -> StyleBox:
	var tint := Color(1.15,0.72,0.58) if kind in ["combat","guarded_treasure"] else Color(0.88,0.85,0.75)
	if Model.room_is_cleared(hud.run_state,id): tint=Color(0.85,1.0,0.80)
	if id==str(hud.run_state.get("current_room_id","")): tint=Color(1.45,1.18,0.72)
	elif id==preview_room_id: tint=Color(1.3,1.2,0.92)
	elif _adjacent(hud,id): tint=Color(1.04,1.0,0.88)
	return Materials.frame("frame_metal",16,tint)

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
	if use_mine_chart(hud):
		art.hide()
		art.custom_minimum_size=Vector2.ZERO
	var name := UI.label(box,str(room.display_name),24)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.custom_minimum_size.y = 62
	name.max_lines_visible = 2
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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
	hit.pressed.connect(func() -> void: preview_room(hud,id))
	panel.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return panel

func use_mine_chart(hud) -> bool:
	if str(hud.dungeon.get("id",""))!="dungeon_old_mine" or hud.dungeon.get("rooms",[]).size()!=CHART_POSITIONS.size(): return false
	var seen: Dictionary={}
	for room: Dictionary in hud.dungeon.get("rooms",[]):
		var id: String=str(room.get("id",""))
		var point: Dictionary=room.get("position",{})
		if seen.has(id) or not CHART_POSITIONS.has(id) or Vector2i(int(point.get("x",-99)),int(point.get("y",-99)))!=CHART_POSITIONS[id]: return false
		seen[id]=true
	var links: Array[String]=[]
	for corridor: Dictionary in hud.dungeon.get("corridors",[]):
		var pair: Array[String]=[str(corridor.get("from","")),str(corridor.get("to",""))]
		pair.sort()
		links.append("|".join(pair))
	links.sort()
	var expected: Array=CHART_LINKS.duplicate()
	expected.sort()
	return links==expected and ResourceLoader.exists(CHART_PATH)

func build_backdrop(hud) -> void:
	if not use_mine_chart(hud): return
	var chart:=TextureRect.new()
	chart.name="IllustratedMineChart"
	chart.texture=UI.Assets.texture(CHART_PATH)
	chart.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	chart.size=hud.graph_content_size
	chart.mouse_filter=Control.MOUSE_FILTER_IGNORE
	chart.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	hud.graph_layer.add_child(chart)

func build_passages(hud) -> void:
	passages = Passages.new()
	passages.name = "DungeonPassages"
	hud.graph_layer.add_child(passages)
	var rooms: Dictionary = {}
	for room: Dictionary in hud.dungeon.get("rooms",[]):
		rooms[str(room.id)] = Rect2(hud._room_screen_position(room),hud.room_node_size)
	passages.configure(rooms,hud.dungeon.get("corridors",[]),hud.graph_content_size)
	passages.select_passage(str(hud.run_state.get("current_room_id","")),preview_room_id)

func chart_room_position(hud,id: String) -> Vector2:
	return Vector2(CHART_ANCHORS.get(id,Vector2(.5,.5)))*hud.graph_content_size-hud.room_node_size*.5

func _preview_controls(hud) -> void:
	preview_box = VBoxContainer.new()
	preview_box.name = "PassagePreview"
	preview_box.add_theme_constant_override("separation",14)
	hud.detail_box.add_child(preview_box)
	hud.detail_box.move_child(preview_box,1)
	preview_label = UI.label(preview_box,"",24,UI.TEXT)
	preview_label.name = "PassagePreviewText"
	travel_button = Button.new()
	travel_button.name = "TravelToPreview"
	travel_button.text = "Travel to room"
	travel_button.pressed.connect(func() -> void: travel_preview(hud))
	preview_box.add_child(travel_button)
	style_button(travel_button)
	current_button = Button.new()
	current_button.name = "ReturnToCurrentRoom"
	current_button.text = "Back to current room"
	current_button.pressed.connect(func() -> void: preview_room(hud,str(hud.run_state.get("current_room_id",""))))
	preview_box.add_child(current_button)
	style_button(current_button)
	preview_box.hide()

func _adjacent(hud,id: String) -> bool:
	return not _corridor(hud,id).is_empty()

func _corridor(hud,id: String) -> Dictionary:
	var here := str(hud.run_state.get("current_room_id",""))
	for link: Dictionary in hud.dungeon.get("corridors",[]):
		if (str(link.get("from",""))==here and str(link.get("to",""))==id) or (str(link.get("to",""))==here and str(link.get("from",""))==id):
			return link
	return {}

func preview_room(hud,id: String) -> void:
	if hud._loadout_pending() or hud._expedition_decision_pending() or bool(hud.run_state.get("completed",false)) or not hud.run_state.get("pending_combat_request",{}).is_empty():
		return
	if not hud._rooms_by_id().has(id):
		return
	preview_room_id = "" if id==str(hud.run_state.get("current_room_id","")) else id
	hud._update_detail()
	hud._refresh_room_styles()
	if not preview_room_id.is_empty():
		if travel_button.disabled: current_button.grab_focus()
		else: travel_button.grab_focus()

func travel_preview(hud) -> void:
	if preview_room_id.is_empty() or travel_button.disabled or hud._expedition_decision_pending():
		return
	var target := preview_room_id
	preview_room_id = ""
	hud._try_enter_room(target)
	_follow_company.call_deferred(hud)

func _follow_company(hud) -> void:
	if not is_instance_valid(hud) or not hud.is_inside_tree():
		return
	var card: Control = hud.room_nodes.get(str(hud.run_state.get("current_room_id","")))
	if card != null:
		hud.map_scroll_container.ensure_control_visible(card)

func _update_preview(hud) -> void:
	if preview_box==null: return
	var previewing := not preview_room_id.is_empty()
	preview_box.visible=previewing
	if previewing:
		var room: Dictionary= hud._rooms_by_id().get(preview_room_id,{})
		var link := _corridor(hud,preview_room_id)
		var unlocked: bool = hud._room_is_unlocked_or_keyed(room)
		var lines: PackedStringArray=["From %s" % hud._room_display_name(str(hud.run_state.get("current_room_id",""))),"",hud._content_summary(room)]
		if link.is_empty():
			lines.append("No direct passage from the current room.")
		else:
			var before: int=int(hud.run_state.get("light_level",0))
			var cost: int=int(link.get("light_decay",0))
			lines.append("Travel light: %s -> %s / %s (-%s)." % [before,maxi(0,before-cost),hud.run_state.get("max_light_level",4),cost])
			var hazard: String=hud._corridor_marker_label(link)
			if not hazard.is_empty(): lines.append("Passage: %s." % hazard)
		if not unlocked: lines.append("Locked. A matching key is required.")
		preview_label.text="\n".join(lines)
		travel_button.disabled=link.is_empty() or not unlocked
		travel_button.tooltip_text="No direct passage." if link.is_empty() else ("A matching key is required." if not unlocked else "Confirm travel; the expedition applies the actual cost.")
		hud.panel_title.text=room.get("display_name",preview_room_id)
		hud.detail_label.hide()
		hud.action_row.hide()
		hud.exit_row.hide()
	elif not hud._loadout_pending() and not bool(hud.run_state.get("completed",false)):
		var room: Dictionary=hud._rooms_by_id().get(str(hud.run_state.get("current_room_id","")),{})
		var lines: PackedStringArray=["You are here. %s." % str(hud._room_state_summary(str(room.get("id","")))).capitalize(),"",hud._content_summary(room)]
		var reward: String=hud._reward_summary(room)
		if not reward.is_empty(): lines.append(reward)
		if not hud.run_state.get("pending_combat_request",{}).is_empty(): lines.append("Enemies hold this room. Enter combat to continue.")
		elif not hud._expedition_decision_pending(): lines.append("Choose a passage below, or inspect a room on the chart.")
		hud.detail_label.text="\n".join(lines)
		hud.detail_label.show()
		hud.panel_title.text=room.get("display_name","Current room")
	hud.world_button.disabled=hud._expedition_decision_pending()

func _sync_event_focus(hud) -> void:
	var popup: Control=hud.corridor_event_panel
	if popup==null: return
	if popup.visible:
		if modal_focus_modes.is_empty():
			previous_focus=hud.get_viewport().gui_get_focus_owner()
		for button: Button in hud.find_children("*","Button",true,false):
			if not popup.is_ancestor_of(button):
				if not modal_focus_modes.has(button): modal_focus_modes[button]=button.focus_mode
				button.focus_mode=Control.FOCUS_NONE
		var choices: Array[Button]=[]
		for button: Button in hud.corridor_hazard_choice_buttons:
			if is_instance_valid(button) and not button.disabled: choices.append(button)
		for index in choices.size():
			var before: Button=choices[posmod(index-1,choices.size())]
			var after: Button=choices[(index+1)%choices.size()]
			choices[index].focus_previous=before.get_path()
			choices[index].focus_neighbor_left=before.get_path()
			choices[index].focus_neighbor_top=before.get_path()
			choices[index].focus_next=after.get_path()
			choices[index].focus_neighbor_right=after.get_path()
			choices[index].focus_neighbor_bottom=after.get_path()
		var focus: Control=hud.get_viewport().gui_get_focus_owner()
		if not choices.is_empty() and (focus==null or not popup.is_ancestor_of(focus)): choices[0].grab_focus.call_deferred()
	else:
		var was_modal := not modal_focus_modes.is_empty()
		for button in modal_focus_modes:
			if is_instance_valid(button): button.focus_mode=modal_focus_modes[button]
		modal_focus_modes.clear()
		if is_instance_valid(previous_focus) and previous_focus.is_inside_tree() and previous_focus.is_visible_in_tree():
			previous_focus.grab_focus.call_deferred()
		elif was_modal:
			var panel: Control=hud.room_nodes.get(str(hud.run_state.get("current_room_id","")))
			if panel!=null:
				var hit: Control=panel.get_node_or_null("RoomHit")
				if hit!=null: hit.grab_focus.call_deferred()
		previous_focus=null
