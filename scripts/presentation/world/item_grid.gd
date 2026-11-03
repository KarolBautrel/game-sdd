extends GridContainer
signal chosen(item_id: String)
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const Presentation := preload("res://scripts/presentation/world/item_presentation.gd")
var item_buttons: Dictionary = {}
var selected_id := ""

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("h_separation",10)
	add_theme_constant_override("v_separation",10)
	resized.connect(_fit)
	_fit()

func configure(rows: Array, selected: String = "", compatible_slot: String = "") -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	item_buttons.clear()
	selected_id = selected
	for row: Dictionary in rows:
		var id: String = row.id
		var tile := UI.button("")
		tile.custom_minimum_size = Vector2(152,218)
		tile.tooltip_text = "%s\n%s" % [row.name,row.description]
		if id == selected: tile.add_theme_stylebox_override("normal",UI.box(Color("4d412a"),UI.GOLD,8))
		elif not compatible_slot.is_empty() and row.get("combat_profile",{}).get("slot") == compatible_slot:
			tile.add_theme_stylebox_override("normal",UI.box(UI.RAISED,Color("91ad8b"),8))
		else: tile.add_theme_stylebox_override("normal",UI.box(UI.RAISED,UI.EDGE,8))
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,8)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(margin)
		if id == selected:
			var marker := UI.label(tile,"✓",24,UI.GOLD)
			marker.name = "SelectedMarker"
			marker.autowrap_mode = TextServer.AUTOWRAP_OFF
			marker.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			marker.position = Vector2(-32,4)
			marker.size = Vector2(28,32)
		var body := VBoxContainer.new()
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_theme_constant_override("separation",4)
		margin.add_child(body)
		var icon := TextureRect.new()
		icon.texture = Presentation.icon_for(row)
		icon.custom_minimum_size.y = 90
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(icon)
		var label := UI.label(body,row.name,24)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.max_lines_visible = 2
		label.clip_text = true
		label.custom_minimum_size.y = ceilf(UI.BODY_FONT.get_height(24)*2)
		var badge := str(row.get("badge","x%s" % int(row.get("quantity",1))))
		if int(row.get("assigned",0)) > 0: badge += "  /  Worn %s" % row.assigned
		var quantity := UI.label(body,badge,24,UI.GOLD)
		quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quantity.max_lines_visible = 1
		quantity.clip_text = true
		quantity.custom_minimum_size.y = ceilf(UI.BODY_FONT.get_height(24))
		tile.tooltip_text += "\n"+badge
		tile.pressed.connect(func() -> void:
			selected_id = id
			chosen.emit(id)
		)
		add_child(tile)
		item_buttons[id] = tile
	_fit()

func _fit() -> void:
	columns = clampi(int((size.x+10)/162),1,5)
