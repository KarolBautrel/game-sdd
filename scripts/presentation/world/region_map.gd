extends Control
## Illustrated geography; interaction and state always stay native.
signal destination_selected(destination: String)
signal province_selected(province: String)
const Travel := preload("res://scripts/domain/world_travel.gd")
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
var region: Dictionary = {}
var location := ""
var quotes: Dictionary = {}
var marker_buttons: Dictionary = {}
var selected_destination := ""
var viewed_province := "marches"
var map_texture: Texture2D
var selected_stops: Array = []

func _ready() -> void:
	custom_minimum_size = Vector2(380,360)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(_layout)

func configure(data: Dictionary, current: String, available: Dictionary = {}, selected: String = "", province: String = "marches") -> void:
	region = data.duplicate(true)
	location = current
	quotes = available.duplicate(true)
	selected_destination = selected
	viewed_province = province
	selected_stops = Travel.plan({"location_id":current}, selected).get("stops", [])
	var plate := "res://assets/ui/campaign/world_atlas.png" if province.is_empty() else str(Travel.province(region, province).get("map", ""))
	map_texture = load(plate)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	marker_buttons.clear()
	var entries: Array = region.get("provinces", []) if province.is_empty() else region.get("nodes", []).filter(func(n: Dictionary) -> bool: return n.province == province)
	for entry: Dictionary in entries:
		var id: String = entry.id
		var current_marker := id == (Travel.province_id(current) if province.is_empty() else current)
		var quote: Dictionary = quotes.get(id, {})
		var caption := "Company here" if current_marker else ("Open province" if province.is_empty() else str(entry.type).capitalize())
		var button := UI.button("%s\n%s" % [entry.name, caption], current_marker or id == selected)
		button.add_theme_font_size_override("font_size",20)
		for state in ["normal", "hover", "pressed", "disabled"]:
			var box := StyleBoxFlat.new()
			box.bg_color = Color("30251be8") if state != "hover" else Color("493421f5")
			box.border_color = UI.GOLD if current_marker or id == selected or state == "hover" else Color("9c784c")
			box.set_border_width_all(2 if current_marker or id == selected else 1)
			box.set_corner_radius_all(3)
			box.content_margin_left = 7
			box.content_margin_right = 7
			box.content_margin_top = 4
			box.content_margin_bottom = 4
			button.add_theme_stylebox_override(state, box)
		button.add_theme_color_override("font_color", UI.TEXT)
		button.add_theme_color_override("font_disabled_color", UI.GOLD if current_marker else UI.MUTED)
		button.disabled = province != "" and (current_marker or not bool(quote.get("inspect_allowed", false)))
		button.tooltip_text = str(entry.description) if province.is_empty() else str(quote.get("tooltip", entry.description))
		button.pressed.connect(func() -> void:
			if button.disabled: return
			if viewed_province.is_empty(): province_selected.emit(id)
			else: destination_selected.emit(id)
		)
		add_child(button)
		marker_buttons[id] = button
	_layout()

func _entry(id: String) -> Dictionary:
	return Travel.province(region,id) if viewed_province.is_empty() else Travel.node(region,id)

func _point(id: String) -> Vector2:
	var anchor: Dictionary = _entry(id).get("anchor", {"x":0.5,"y":0.5})
	var paper := paper_rect()
	return paper.position + paper.size * Vector2(float(anchor.x),float(anchor.y))

func paper_rect() -> Rect2:
	var dimensions := Vector2(16,9) * minf(size.x / 16.0, size.y / 9.0)
	return Rect2((size-dimensions)/2,dimensions)

func _layout() -> void:
	var compact := get_viewport_rect().size.x < 1500
	var narrow := size.x < 600
	custom_minimum_size.y = 300 if compact else clampf(size.x*9.0/16.0,360,1100)
	var width := clampf(paper_rect().size.x*(0.24 if compact else 0.19),124 if compact else 150,164 if compact else 224)
	if narrow: width = minf(size.x/2-16,164)
	var index := 0
	for id: String in marker_buttons:
		var button: Button = marker_buttons[id]
		button.add_theme_font_size_override("font_size",16 if compact or narrow else 20)
		button.custom_minimum_size = Vector2(width,50 if compact or narrow else 64)
		button.size = button.custom_minimum_size
		var desired := _point(id) + Vector2(-width/2,20)
		if narrow: desired = Vector2(8+(index%2)*(width+16),20+(index/2)*76)
		button.position = Vector2(clampf(desired.x,0,maxf(0,size.x-button.size.x)),clampf(desired.y,0,maxf(0,size.y-button.size.y)))
		index += 1
	queue_redraw()

func _road(a: Vector2,b: Vector2,selected: bool) -> void:
	var direction := (b-a).normalized()
	var length := a.distance_to(b)
	for step in range(18, int(length)-18, 16):
		var start := a + direction*step
		var end := a + direction*minf(step+8,length-18)
		if selected: draw_line(start,end,Color("ead19b90"),4,true)
		draw_line(start,end,Color("9b3927") if selected else Color("4d3619a0"),2.5 if selected else 1.5,true)

func _draw() -> void:
	if region.is_empty() or map_texture == null: return
	draw_texture_rect(map_texture,paper_rect(),false)
	var drawn: Dictionary = {}
	for edge: Dictionary in region.edges:
		var a: String = edge.from
		var b: String = edge.to
		var selected := false
		for index in range(1,selected_stops.size()):
			if [selected_stops[index-1], selected_stops[index]].has(a) and [selected_stops[index-1], selected_stops[index]].has(b): selected = true
		if viewed_province.is_empty():
			a = str(Travel.node(region,a).province)
			b = str(Travel.node(region,b).province)
			if a == b: continue
		if not marker_buttons.has(a) or not marker_buttons.has(b): continue
		var key := "|".join([a,b] if a < b else [b,a])
		if drawn.has(key):
			drawn[key].selected = drawn[key].selected or selected
		else: drawn[key] = {"a":a,"b":b,"selected":selected}
	for road: Dictionary in drawn.values(): _road(_point(road.a),_point(road.b),road.selected)
	for id: String in marker_buttons:
		var point := _point(id)
		var current := id == (Travel.province_id(location) if viewed_province.is_empty() else location)
		var color := Color("9b3927") if current else UI.INK
		draw_circle(point,8,Color("edd4a0"))
		draw_arc(point,11,0,TAU,32,color,2,true)
		if current: draw_circle(point,5,color)
		draw_line(point+Vector2(0,11),marker_buttons[id].position+Vector2(marker_buttons[id].size.x/2,0),color,1.5,true)
