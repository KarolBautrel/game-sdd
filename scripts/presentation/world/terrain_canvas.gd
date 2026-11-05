extends Control
signal stroke_started
signal painted(position: Vector2)
signal stroke_finished
signal sampled(position: Vector2)
signal probed(position: Vector2)
signal hovered(position: Vector2)
const Terrain:=preload("res://scripts/domain/terrain_navigation.gd")
const World:=preload("res://scripts/domain/living_world.gd")
const PLATE:=preload("res://assets/ui/campaign/world_atlas.png")
const UI:=preload("res://scripts/presentation/world/campaign_skin.gd")
var data: Dictionary={}
var overlay: ImageTexture
var opacity:=.4
var zoom:=1.0
var pan:=Vector2.ZERO
var painting:=false
var panning:=false
var probe_mode:=false
var route: Array=[]
var probe_start:=Vector2.INF
var cursor:=Vector2.INF
var brush_radius:=1
func _ready() -> void:
	clip_contents=true
	mouse_filter=Control.MOUSE_FILTER_STOP
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	custom_minimum_size=Vector2(480,280)
	resized.connect(queue_redraw)
func paper_rect() -> Rect2:
	var dimensions:=Vector2(16,9)*minf(size.x/16.0,size.y/9.0)*zoom
	return Rect2((size-dimensions)/2+pan,dimensions)
func point(position: Vector2) -> Vector2:
	return paper_rect().position+position*paper_rect().size
func normalized(position: Vector2) -> Vector2:
	return (position-paper_rect().position)/paper_rect().size
func update_mask(value: Dictionary) -> void:
	data=value
	var image:=Image.create(int(data.width),int(data.height),false,Image.FORMAT_RGBA8)
	for y in range(int(data.height)):
		for x in range(int(data.width)): image.set_pixel(x,y,Color(Terrain.TYPES[data.rows[y][x]].color))
	if overlay==null: overlay=ImageTexture.create_from_image(image)
	else: overlay.update(image)
	queue_redraw()
func fit() -> void:
	zoom=1;pan=Vector2.ZERO;queue_redraw()
func zoom_at(position: Vector2,factor: float) -> void:
	var before:=normalized(position)
	zoom=clampf(zoom*factor,1,5)
	pan+=position-point(before)
	if zoom==1: pan=Vector2.ZERO
	queue_redraw()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			zoom_at(event.position,1.2 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1/1.2)
		elif event.button_index==MOUSE_BUTTON_MIDDLE: panning=event.pressed
		elif event.button_index==MOUSE_BUTTON_RIGHT and event.pressed and paper_rect().has_point(event.position): sampled.emit(normalized(event.position))
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed and paper_rect().has_point(event.position):
				if probe_mode: probed.emit(normalized(event.position))
				else:
					painting=true;stroke_started.emit();painted.emit(normalized(event.position))
			elif not event.pressed and painting: painting=false;stroke_finished.emit()
		accept_event()
	elif event is InputEventMouseMotion:
		if panning: pan+=event.relative
		cursor=normalized(event.position)
		hovered.emit(cursor)
		if painting and (event.button_mask&MOUSE_BUTTON_MASK_LEFT)!=0 and Rect2(Vector2.ZERO,size).has_point(event.position) and paper_rect().has_point(event.position): painted.emit(cursor)
		elif painting: painting=false;stroke_finished.emit()
		queue_redraw();accept_event()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("15130f"))
	var paper:=paper_rect()
	draw_texture_rect(PLATE,paper,false)
	if overlay!=null and opacity>0:
		draw_texture_rect(overlay,paper,false,Color(1,1,1,opacity))
	for anchor: Dictionary in World.navigation_anchors():
		var position:=point(World.point(anchor.position))
		draw_circle(position,2,UI.GOLD)
	for site: Dictionary in World.definition().sites:
		var location:=point(World.point(site.position))
		draw_circle(location,5,UI.INK)
		draw_circle(location,3,UI.GOLD)
		draw_string(UI.body_font(),location+Vector2(8,-7),site.name,HORIZONTAL_ALIGNMENT_LEFT,-1,16,UI.TEXT)
	if probe_start.is_finite(): draw_circle(point(probe_start),7,Color("92d8b2"))
	var path:=PackedVector2Array()
	if probe_start.is_finite(): path.append(point(probe_start))
	for position: Dictionary in route: path.append(point(World.point(position)))
	if path.size()>1:
		draw_polyline(path,UI.INK,6,true)
		draw_polyline(path,Color("f6e2ac"),3,true)
	if not probe_mode and cursor.is_finite() and Rect2(Vector2.ZERO,Vector2.ONE).has_point(cursor) and not data.is_empty():
		draw_circle(point(cursor),paper.size.x/float(data.width)*(brush_radius+.5),Color.WHITE,false,1,true)
