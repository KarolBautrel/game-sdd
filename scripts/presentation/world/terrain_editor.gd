extends Control
signal scene_requested(path: String)
const Terrain:=preload("res://scripts/domain/terrain_navigation.gd")
const World:=preload("res://scripts/domain/living_world.gd")
const Canvas:=preload("res://scripts/presentation/world/terrain_canvas.gd")
const UI:=preload("res://scripts/presentation/world/campaign_skin.gd")
@export var qa_memory:=false
var file_path: String=Terrain.PATH
var data: Dictionary={}
var saved_rows: Array=[]
var history: Array=[]
var future: Array=[]
var stroke_before: Array=[]
var last_cell:=Vector2i(-1,-1)
var selected: String="W"
var radius:=1
var canvas: Control
var status: Label
var hover_label: Label
var title_label: Label
var buttons: Dictionary={}
var palette: Dictionary={}
var slider: HSlider
var brush: SpinBox
var probe_navigation: RefCounted
func _label(parent: Node,text: String,size: int=18,color: Color=UI.TEXT) -> Label:
	var label:=UI.label(parent,text,size,color)
	label.add_theme_font_size_override("font_size",size)
	label.autowrap_mode=TextServer.AUTOWRAP_OFF
	return label
func _ready() -> void:
	theme=UI.theme()
	if data.is_empty(): data=JSON.parse_string(FileAccess.get_file_as_string(Terrain.PATH))
	saved_rows=data.rows.duplicate()
	_build()
	_refresh("Paint terrain; save applies it the next time you open the living map.")
func _button(parent: Node,id: String,text: String,callback: Callable) -> Button:
	var button:=Button.new()
	button.text=text
	button.custom_minimum_size.y=40
	button.add_theme_font_size_override("font_size",18)
	for state in ["normal","hover","pressed","disabled"]: button.add_theme_stylebox_override(state,UI.frame("frame_metal",7))
	button.pressed.connect(callback)
	parent.add_child(button);buttons[id]=button
	return button
func _build() -> void:
	var background:=ColorRect.new()
	background.color=UI.BG;background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,16)
	add_child(margin)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",9);margin.add_child(column)
	var heading:=HBoxContainer.new();column.add_child(heading)
	title_label=_label(heading,"Terrain cartographer",28,UI.GOLD)
	title_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_button(heading,"reload","Reload saved",_reload)
	_button(heading,"save","Save terrain",save_changes)
	_button(heading,"back","Living world",_back)
	var toolbar:=HBoxContainer.new();column.add_child(toolbar)
	var paint:=_button(toolbar,"paint","Paint",func() -> void: _mode(false))
	paint.toggle_mode=true;paint.button_pressed=true
	var probe:=_button(toolbar,"probe","Test route",func() -> void: _mode(true));probe.toggle_mode=true
	_button(toolbar,"undo","Undo",undo)
	_button(toolbar,"redo","Redo",redo)
	_button(toolbar,"fit","Fit map",func() -> void: canvas.fit())
	_label(toolbar,"Brush",18)
	brush=SpinBox.new();brush.min_value=0;brush.max_value=6;brush.value=radius;brush.custom_minimum_size.x=90
	brush.add_theme_font_size_override("font_size",18)
	brush.value_changed.connect(func(value: float) -> void: radius=int(value);canvas.brush_radius=radius)
	toolbar.add_child(brush)
	_label(toolbar,"Overlay",18)
	slider=HSlider.new();slider.min_value=0;slider.max_value=.8;slider.step=.05;slider.value=.4;slider.custom_minimum_size.x=125
	slider.value_changed.connect(func(value: float) -> void: canvas.opacity=value;canvas.queue_redraw())
	toolbar.add_child(slider)
	var body:=HBoxContainer.new();body.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",12);column.add_child(body)
	var side:=PanelContainer.new();side.custom_minimum_size.x=244;side.add_theme_stylebox_override("panel",UI.frame("frame_dark",12));body.add_child(side)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;side.add_child(scroll)
	var tools:=VBoxContainer.new();tools.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tools.add_theme_constant_override("separation",5);scroll.add_child(tools)
	_label(tools,"Terrain / travel speed",19,UI.GOLD)
	for code: String in Terrain.TYPES:
		var kind: Dictionary=Terrain.TYPES[code]
		var text: String="%s / %s" % [kind.name,"blocked" if kind.cost==0 else "%d%%" % roundi(100.0/float(kind.cost))]
		var button:=_button(tools,"terrain_"+code,text,func() -> void: select(code))
		button.toggle_mode=true;button.add_theme_color_override("font_color",Color(kind.color).lightened(.35))
		palette[code]=button
	var help:=_label(tools,"Left drag: paint\nRight click: sample\nWheel: zoom\nMiddle drag: pan\n\nTest route: choose start,\nthen destination.\n\nSave checks every site\nand required world route.",16,UI.MUTED)
	help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;help.custom_minimum_size.x=220
	canvas=Canvas.new();canvas.size_flags_horizontal=Control.SIZE_EXPAND_FILL;canvas.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(canvas)
	canvas.stroke_started.connect(begin_stroke);canvas.painted.connect(paint_at);canvas.stroke_finished.connect(end_stroke)
	canvas.sampled.connect(func(position: Vector2) -> void: select(_code(position)))
	canvas.probed.connect(probe_at);canvas.hovered.connect(_hover)
	hover_label=_label(column,"",18,UI.MUTED)
	status=_label(column,"",18,UI.TEXT);status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y=44
	canvas.update_mask(data)
func _code(position: Vector2) -> String:
	var id:=Vector2i(position*Vector2(int(data.width),int(data.height)))
	if id.x<0 or id.y<0 or id.x>=int(data.width) or id.y>=int(data.height): return "W"
	return data.rows[id.y][id.x]
func select(code: String) -> void:
	selected=code
	_mode(false)
	_refresh("Selected "+str(Terrain.TYPES[code].name)+".")
func _mode(probe: bool) -> void:
	canvas.probe_mode=probe;canvas.route=[];canvas.probe_start=Vector2.INF;canvas.queue_redraw()
	buttons.paint.button_pressed=not probe;buttons.probe.button_pressed=probe
	status.text="Choose a start, then a destination. A third click starts a new probe." if probe else "Left drag paints one undoable stroke. Right click samples."
func _refresh(message: String="") -> void:
	title_label.text="Terrain cartographer / %s" % ("unsaved" if data.rows!=saved_rows else "saved r%d" % int(data.revision))
	buttons.undo.disabled=history.is_empty();buttons.redo.disabled=future.is_empty()
	for code: String in palette: palette[code].button_pressed=code==selected
	if not message.is_empty(): status.text=message
func begin_stroke() -> void:
	stroke_before=data.rows.duplicate();last_cell=Vector2i(-1,-1)
func paint_at(position: Vector2) -> void:
	var id:=Vector2i(position*Vector2(int(data.width),int(data.height)))
	if last_cell.x<0: last_cell=id
	var steps: int=maxi(absi(id.x-last_cell.x),absi(id.y-last_cell.y))+1
	for step in range(steps+1):
		var at:=Vector2i(Vector2(last_cell).lerp(Vector2(id),float(step)/steps).round())
		for y in range(maxi(0,at.y-radius),mini(int(data.height),at.y+radius+1)):
			for x in range(maxi(0,at.x-radius),mini(int(data.width),at.x+radius+1)):
				if Vector2(x-at.x,y-at.y).length()>radius+.25: continue
				var row: String=data.rows[y]
				data.rows[y]=row.substr(0,x)+selected+row.substr(x+1)
	last_cell=id;probe_navigation=null;canvas.route=[];canvas.probe_start=Vector2.INF
	canvas.update_mask(data);_refresh()
func end_stroke() -> void:
	if not stroke_before.is_empty() and stroke_before!=data.rows:
		history.append(stroke_before);future.clear()
		if history.size()>100: history.pop_front()
	stroke_before=[];last_cell=Vector2i(-1,-1);_refresh("Stroke ready. Save terrain to apply it.")
func undo() -> void:
	if history.is_empty(): return
	future.append(data.rows.duplicate());data.rows=history.pop_back();_changed("Stroke undone.")
func redo() -> void:
	if future.is_empty(): return
	history.append(data.rows.duplicate());data.rows=future.pop_back();_changed("Stroke restored.")
func _changed(message: String) -> void:
	probe_navigation=null;canvas.route=[];canvas.probe_start=Vector2.INF;canvas.update_mask(data);_refresh(message)
func _hover(position: Vector2) -> void:
	var code:=_code(position)
	hover_label.text="%s / %s / cell %d, %d" % [Terrain.TYPES[code].name,"impassable" if Terrain.TYPES[code].cost==0 else "%d%% travel speed" % roundi(100.0/float(Terrain.TYPES[code].cost)),int(position.x*int(data.width)),int(position.y*int(data.height))]
	for anchor: Dictionary in World.navigation_anchors():
		if canvas.point(position).distance_to(canvas.point(World.point(anchor.position)))<8:
			hover_label.text+=" / required: "+str(anchor.id)
			break
func probe_at(position: Vector2) -> void:
	if probe_navigation==null:
		probe_navigation=Terrain.new();probe_navigation.configure(data)
	if not probe_navigation.passable(position): status.text="Blocked: "+str(Terrain.TYPES[_code(position)].name)+". Choose accessible ground.";return
	if not canvas.probe_start.is_finite() or not canvas.route.is_empty():
		canvas.probe_start=position;canvas.route=[];status.text="Start chosen. Click a destination."
	else:
		canvas.route=probe_navigation.route(canvas.probe_start,position)
		status.text="No accessible route. The mask separates these points." if canvas.route.is_empty() else "Safe route / terrain cost %.3f. Water and peaks are avoided." % probe_navigation.route_cost(canvas.probe_start,canvas.route)
	canvas.queue_redraw()
func save_changes() -> bool:
	if qa_memory and file_path==Terrain.PATH: status.text="QA memory editor cannot write production terrain.";return false
	var candidate:=data.duplicate(true);candidate.revision=int(data.revision)+1
	var error:=Terrain.save_map(file_path,candidate,World.navigation_anchors())
	if not error.is_empty(): status.text="Not saved: "+error;return false
	data=candidate;saved_rows=data.rows.duplicate()
	_refresh("Saved revision%d. Reopen Living world to use it; previous map backed up locally." % int(data.revision))
	return true
func _reload() -> void:
	if not FileAccess.file_exists(file_path): status.text="No saved terrain file.";return
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(file_path))
	if not Terrain.errors(parsed).is_empty(): status.text="Saved terrain is invalid; current edits retained.";return
	history.append(data.rows.duplicate());future.clear();data=parsed;saved_rows=data.rows.duplicate();_changed("Reloaded saved terrain. Undo can recover your edits.")
func _back() -> void:
	if data.rows!=saved_rows: status.text="Unsaved edits remain here. Save or reload the saved map before leaving.";return
	Terrain.reload()
	if scene_requested.get_connections().is_empty(): get_tree().change_scene_to_file("res://scenes/world/LivingWorld.tscn")
	else: scene_requested.emit("res://scenes/world/LivingWorld.tscn")
