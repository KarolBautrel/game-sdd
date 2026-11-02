extends Control
signal destination_selected(destination: String)
const Travel := preload("res://scripts/domain/world_travel.gd")
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const MAP := preload("res://assets/ui/campaign/marches_map.png")
const ANCHORS := {"town_ravenford":Vector2(0.22,0.34),"event_broken_cart":Vector2(0.50,0.575),"dungeon_old_mine":Vector2(0.84,0.65)}
var region: Dictionary = {}
var location := ""
var quotes: Dictionary = {}
var marker_buttons: Dictionary = {}

func _ready() -> void:
	custom_minimum_size = Vector2(380,600)
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(_layout)

func configure(data: Dictionary,current: String,available: Dictionary = {}) -> void:
	region = data.duplicate(true)
	location = current
	quotes = available.duplicate(true)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	marker_buttons.clear()
	for entry: Dictionary in region.get("nodes",[]):
		var id: String = entry.id
		var quote: Dictionary = quotes.get(id,{})
		var caption := "You are here" if id == current else str(quote.get("caption","No direct road"))
		var button := UI.button("%s\n%s" % [Travel.node_name(id),caption],id == current)
		button.add_theme_font_size_override("font_size",24)
		button.custom_minimum_size = Vector2(224,90)
		button.disabled = not bool(quote.get("allowed",false)) or id == current
		if id == current:
			button.add_theme_stylebox_override("disabled",UI.box(Color("51452e"),UI.GOLD,14))
			button.add_theme_color_override("font_disabled_color",UI.GOLD)
		button.tooltip_text = str(quote.get("tooltip",caption))
		button.pressed.connect(func() -> void:
			if button.disabled: return
			for marker: Button in marker_buttons.values(): marker.disabled = true
			destination_selected.emit(id)
		)
		add_child(button)
		marker_buttons[id] = button
	_layout()

func _point(id: String) -> Vector2:
	var paper := paper_rect()
	return paper.position + paper.size * Vector2(ANCHORS.get(id,Vector2(0.5,0.5)))

func paper_rect() -> Rect2:
	var scale_factor := minf(size.x/1280.0,size.y/720.0)
	var dimensions := Vector2(1280,720)*scale_factor
	return Rect2((size-dimensions)/2,dimensions)

func _layout() -> void:
	custom_minimum_size.y = clampf(size.x*720.0/1280.0,360,960)
	for id: String in marker_buttons:
		var button: Button = marker_buttons[id]
		button.size = Vector2(224,90)
		var desired := _point(id)+Vector2(-112,24)
		if size.x < 700:
			desired.y = 20 + ANCHORS.keys().find(id)*104
		button.position = Vector2(clampf(desired.x,0,maxf(0,size.x-button.size.x)),clampf(desired.y,0,maxf(0,size.y-button.size.y)))
	queue_redraw()

func _draw() -> void:
	if region.is_empty(): return
	draw_texture_rect(MAP,paper_rect(),false)
	for id: String in marker_buttons:
		var point := _point(id)
		var color := Color("9b3927") if id == location else UI.INK_MUTED
		draw_circle(point,10,color)
		draw_arc(point,14,0,TAU,32,color,2,true)
		# Label tether stays on its authored landmark, including narrow layouts.
		draw_line(point+Vector2(0,14),marker_buttons[id].position+Vector2(112,0),color,2,true)
