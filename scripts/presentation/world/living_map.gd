extends Control
signal course_requested(position: Vector2,site_id: String)
signal actor_selected(id: String)
const World := preload("res://scripts/domain/living_world.gd")
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const PLATE := preload("res://assets/ui/campaign/world_atlas.png")
const COLORS := {"caravan":Color("dfbd6d"),"league_patrol":Color("82b4bc"),"iron_patrol":Color("a6a6bb"),"mine_raiders":Color("d77c66")}
var site_buttons: Dictionary={}
var actor_buttons: Dictionary={}
var profile: Dictionary={}
var previous_positions: Dictionary={}
var blend:=1.0
var duration:=.6
var selected_site: String="town_ravenford"
func _ready() -> void:
	custom_minimum_size=Vector2(500,280)
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter=Control.MOUSE_FILTER_STOP
	for entry: Dictionary in World.definition().sites:
		var id: String=entry.id
		var button:=Button.new()
		button.text=entry.name
		button.focus_mode=Control.FOCUS_ALL
		button.tooltip_text="Travel to "+str(entry.name)
		button.pressed.connect(func() -> void: course_requested.emit(World.point(entry.position),id))
		button.add_theme_stylebox_override("focus",UI.focus_box())
		add_child(button);site_buttons[id]=button
	for id: String in COLORS:
		var button:=Button.new()
		button.text={"caravan":"C","league_patrol":"L","iron_patrol":"I","mine_raiders":"R"}[id]
		button.tooltip_text=id.replace("_"," ").capitalize()
		button.custom_minimum_size=Vector2(32,32)
		button.add_theme_font_size_override("font_size",18)
		button.add_theme_color_override("font_color",COLORS[id])
		button.add_theme_stylebox_override("normal",_box(Color("211a15"),COLORS[id]))
		button.add_theme_stylebox_override("hover",_box(Color("51402c"),COLORS[id]))
		button.pressed.connect(func() -> void: actor_selected.emit(id))
		add_child(button);actor_buttons[id]=button
	resized.connect(_layout)
	_layout()
func _box(background: Color,border: Color) -> StyleBoxFlat:
	var box:=StyleBoxFlat.new()
	box.bg_color=background;box.border_color=border
	box.set_border_width_all(1);box.set_corner_radius_all(3)
	box.set_content_margin_all(5)
	return box
func paper_rect() -> Rect2:
	var dimensions:=Vector2(16,9)*minf(size.x/16.0,size.y/9.0)
	return Rect2((size-dimensions)/2,dimensions)
func _point(position: Vector2) -> Vector2:
	var paper:=paper_rect()
	return paper.position+paper.size*position
func displayed(id: String) -> Vector2:
	var current: Vector2=World.point(profile.living_world.party.position) if id=="company" else Vector2.ZERO
	if id!="company":
		for actor: Dictionary in profile.living_world.actors:
			if actor.id==id: current=World.point(actor.position)
	return Vector2(previous_positions.get(id,current)).lerp(current,blend)
func update_state(value: Dictionary,seconds: float = .6) -> void:
	var changed: bool=profile.is_empty() or int(profile.living_world.tick)!=int(value.living_world.tick)
	if changed:
		if not profile.is_empty():
			previous_positions.company=displayed("company")
			for id: String in actor_buttons: previous_positions[id]=displayed(id)
		blend=0.0
	profile=value
	duration=maxf(.01,seconds)
	var locked: bool=not value.active_run.is_empty() or not value.world.pending_event.is_empty()
	for id: String in site_buttons:
		var current: bool=World.at_site(value.living_world,id)
		var button: Button=site_buttons[id]
		button.disabled=locked
		var border: Color=UI.GOLD if current or id==selected_site else Color("9d7b4e")
		for state in ["normal","disabled","pressed"]: button.add_theme_stylebox_override(state,_box(Color("30251be8"),border))
		button.add_theme_stylebox_override("hover",_box(Color("4e3928"),UI.GOLD))
		button.add_theme_color_override("font_color",UI.TEXT)
		button.add_theme_color_override("font_disabled_color",UI.MUTED)
	_layout()
func snap() -> void:
	blend=1.0
	_layout_units();queue_redraw()
func _process(delta: float) -> void:
	if profile.is_empty(): return
	if blend<1.0:
		blend=minf(1.0,blend+delta/duration)
		_layout_units();queue_redraw()
func _layout() -> void:
	var compact:=get_viewport_rect().size.x<1500
	var paper:=paper_rect()
	for id: String in site_buttons:
		var button: Button=site_buttons[id]
		button.add_theme_font_size_override("font_size",16 if compact else 21)
		button.custom_minimum_size=Vector2(128 if compact else 184,44 if compact else 54)
		button.size=button.custom_minimum_size
		var desired:=_point(World.point(World.site(id).position))+Vector2(-button.size.x/2,20)
		button.position=Vector2(clampf(desired.x,paper.position.x,maxf(paper.position.x,paper.end.x-button.size.x)),clampf(desired.y,paper.position.y,maxf(paper.position.y,paper.end.y-button.size.y)))
	_layout_units();queue_redraw()
func _layout_units() -> void:
	if profile.is_empty(): return
	for actor: Dictionary in profile.living_world.actors:
		var button: Button=actor_buttons[actor.id]
		button.visible=actor.active
		var offset:=Vector2(15,-22) if actor.id=="caravan" else Vector2(-22,-30)
		button.position=_point(displayed(actor.id))+offset-Vector2(16,16)
		button.size=Vector2(32,32)
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and paper_rect().has_point(event.position):
		course_requested.emit((event.position-paper_rect().position)/paper_rect().size,"")
		accept_event()
func _draw() -> void:
	draw_texture_rect(PLATE,paper_rect(),false)
	if profile.is_empty(): return
	var state: Dictionary=profile.living_world
	var route:=PackedVector2Array([_point(displayed("company"))])
	for position: Dictionary in state.party.path: route.append(_point(World.point(position)))
	if route.size()>1:
		draw_polyline(route,Color("f0d6a2"),5,true)
		draw_polyline(route,Color("993d2a"),2,true)
	for entry: Dictionary in World.definition().sites:
		var location:=_point(World.point(entry.position))
		draw_circle(location,7,Color("efd6a0"))
		draw_arc(location,10,0,TAU,28,UI.INK,2,true)
	var actual:=_point(displayed("company"))
	var banner:=actual+Vector2(0,-66)
	draw_line(actual,banner,UI.INK,2,true)
	draw_circle(actual,7,Color("ad4d35"))
	draw_circle(actual,10,UI.GOLD,false,2,true)
	draw_colored_polygon(PackedVector2Array([banner+Vector2(-17,-10),banner+Vector2(17,-10),banner+Vector2(17,15),banner+Vector2(0,25),banner+Vector2(-17,15)]),Color("7b2f25"))
	draw_polyline(PackedVector2Array([banner+Vector2(-17,-10),banner+Vector2(17,-10),banner+Vector2(17,15),banner+Vector2(0,25),banner+Vector2(-17,15),banner+Vector2(-17,-10)]),UI.GOLD,2,true)
	draw_string(UI.heading_font(),banner+Vector2(-8,9),"B",HORIZONTAL_ALIGNMENT_LEFT,-1,20,UI.TEXT)
