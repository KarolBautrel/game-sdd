extends Control
signal course_requested(position: Vector2,site_id: String)
signal actor_selected(id: String)
const World := preload("res://scripts/domain/living_world.gd")
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const PLATE := preload("res://assets/ui/campaign/world_atlas.png")
const Illustration:=preload("res://scripts/presentation/world/region_illustration.gd")
const Camera:=preload("res://scripts/presentation/world/map_camera.gd")
const COLORS := {"caravan":Color("dfbd6d"),"league_patrol":Color("82b4bc"),"iron_patrol":Color("a6a6bb"),"mine_raiders":Color("d77c66")}
var site_buttons: Dictionary={}
var actor_buttons: Dictionary={}
var profile: Dictionary={}
var motion_units: Dictionary={}
var blend:=1.0
var selected_site: String="town_ravenford"
var banner_layer: Control
var region_state: Dictionary={}
var preview_only:=false
var semantic_overlay:=false
var illustration: RefCounted
var ground: TextureRect
var camera:=Camera.new()
var camera_buttons: Dictionary={}
var camera_bar: HBoxContainer
var camera_hint: Label
var minimap: Control
var drag_button:=0
func camera_enabled() -> bool: return _state().has("geography")
func _state() -> Dictionary: return profile.living_world if not profile.is_empty() else region_state
func _ready() -> void:
	clip_contents=true
	custom_minimum_size=Vector2(500,280)
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter=Control.MOUSE_FILTER_STOP
	if region_state.has("geography"):
		illustration=Illustration.new();illustration.configure(region_state.geography)
		ground=illustration.background();add_child(ground)
	for entry: Dictionary in World.definition(_state()).sites:
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
		# Keep native hit targets/focus, draw moving banners at subpixel positions.
		button.self_modulate=Color(1,1,1,0)
		button.tooltip_text=id.replace("_"," ").capitalize()
		button.custom_minimum_size=Vector2(32,32)
		button.add_theme_font_size_override("font_size",18)
		button.add_theme_color_override("font_color",COLORS[id])
		button.add_theme_stylebox_override("normal",_box(Color("211a15"),COLORS[id]))
		button.add_theme_stylebox_override("hover",_box(Color("51402c"),COLORS[id]))
		button.pressed.connect(func() -> void: actor_selected.emit(id))
		button.mouse_entered.connect(_redraw);button.mouse_exited.connect(_redraw)
		button.focus_entered.connect(_redraw);button.focus_exited.connect(_redraw)
		add_child(button);actor_buttons[id]=button
	banner_layer=Control.new()
	banner_layer.name="MovingBanners"
	banner_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	banner_layer.z_index=1
	banner_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner_layer.draw.connect(_draw_actor_banners)
	add_child(banner_layer)
	if camera_enabled():
		_build_camera_controls()
		if int(_state().geography.version)==2:
			camera.focus(World.point(_state().party.position),size)
			_initial_camera.call_deferred()
	resized.connect(_layout)
	_layout()
func _initial_camera() -> void:
	await get_tree().process_frame
	if is_inside_tree(): _camera_action("company")
func _build_camera_controls() -> void:
	camera_bar=HBoxContainer.new();camera_bar.position=Vector2(10,8);camera_bar.add_theme_constant_override("separation",4);camera_bar.z_index=3;add_child(camera_bar)
	for item: Array in [["out","-"],["in","+"],["overview","Overview"],["company","Center" if preview_only else "Company"]]:
		var button:=Button.new();button.text=item[1];button.custom_minimum_size=Vector2(34,34);button.add_theme_font_size_override("font_size",16)
		for state: String in ["normal","hover","pressed","disabled"]: button.add_theme_stylebox_override(state,_box(Color("211a15ef"),UI.GOLD))
		camera_bar.add_child(button);camera_buttons[item[0]]=button
		button.pressed.connect(func() -> void: _camera_action(item[0]))
	camera_hint=Label.new();camera_hint.text="Wheel: zoom | RMB/MMB: pan";camera_hint.add_theme_font_size_override("font_size",14);camera_hint.add_theme_color_override("font_color",UI.TEXT);camera_hint.mouse_filter=Control.MOUSE_FILTER_IGNORE;camera_hint.z_index=3;add_child(camera_hint)
	minimap=Control.new();minimap.name="OverviewChart";minimap.custom_minimum_size=Vector2(160,96);minimap.size=Vector2(160,96);minimap.z_index=3;minimap.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;minimap.tooltip_text="Click to move the view. Company orders are unchanged.";add_child(minimap)
	minimap.draw.connect(_draw_minimap);minimap.gui_input.connect(_minimap_input)
func _camera_action(id: String) -> void:
	match id:
		"overview": camera.overview(size)
		"company": camera.focus(World.point(_state().party.position) if profile.is_empty() else displayed("company"),size)
		"in": camera.zoom_at(size*.5,1.25,size)
		"out": camera.zoom_at(size*.5,.8,size)
	_layout()
func reveal(position: Vector2) -> void:
	if camera_enabled(): camera.center=position;camera.clamp_view(size);_layout()
func _draw_minimap() -> void:
	var inner:=Rect2(Vector2(4,4),minimap.size-Vector2(8,8))
	minimap.draw_style_box(_box(Color("211a15"),UI.GOLD),Rect2(Vector2.ZERO,minimap.size))
	minimap.draw_texture_rect(illustration.base,inner,false)
	for entry: Dictionary in World.definition(_state()).sites: minimap.draw_circle(inner.position+inner.size*World.point(entry.position),2.0,UI.GOLD)
	if not profile.is_empty(): minimap.draw_circle(inner.position+inner.size*displayed("company"),3,Color("b5513c"))
	var visible:=camera.visible_world(size)
	minimap.draw_rect(Rect2(inner.position+visible.position*inner.size,visible.size*inner.size),UI.TEXT,false,1.5)
func _minimap_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		camera.center=((event.position-Vector2(4,4))/(minimap.size-Vector2(8,8))).clamp(Vector2.ZERO,Vector2.ONE)
		camera.clamp_view(size);_layout();minimap.accept_event()
func _input(event: InputEvent) -> void:
	if not camera_enabled(): return
	if event is InputEventMouseButton and not event.pressed and event.button_index==drag_button:
		drag_button=0;get_viewport().set_input_as_handled();return
	if event is InputEventMouseMotion and drag_button!=0:
		camera.pan_pixels(event.relative,size);_layout();get_viewport().set_input_as_handled();return
	if not event is InputEventMouseButton: return
	var local: Vector2=event.position-get_global_position()
	if not Rect2(Vector2.ZERO,size).has_point(local): return
	if minimap.visible and minimap.get_rect().has_point(local): return
	if camera_bar.get_rect().has_point(local): return
	if event.pressed and event.button_index in [MOUSE_BUTTON_MIDDLE,MOUSE_BUTTON_RIGHT]:
		drag_button=event.button_index;get_viewport().set_input_as_handled()
	elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		camera.zoom_at(local,1.2 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0/1.2,size);_layout();get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT: drag_button=0
func _box(background: Color,border: Color) -> StyleBoxFlat:
	var box:=StyleBoxFlat.new()
	box.bg_color=background;box.border_color=border
	box.set_border_width_all(1);box.set_corner_radius_all(3)
	box.set_content_margin_all(5)
	return box
func paper_rect() -> Rect2:
	if camera_enabled(): return camera.rect(size)
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
	if not motion_units.has(id): return current
	var samples: Array=motion_units[id]
	for index in range(1,samples.size()):
		var first: Dictionary=samples[index-1]
		var last: Dictionary=samples[index]
		if blend<=float(last.time):
			var fraction: float=clampf((blend-float(first.time))/maxf(.000000001,float(last.time)-float(first.time)),0,1)
			return World.point(first.position).lerp(World.point(last.position),fraction)
	return current
func update_state(value: Dictionary,_seconds: float = .6,motion: Dictionary={}) -> void:
	var changed: bool=profile.is_empty() or int(profile.living_world.tick)!=int(value.living_world.tick)
	if changed:
		motion_units=motion.get("units",{}).duplicate(true) if not profile.is_empty() and int(motion.get("tick",-1))==int(value.living_world.tick) else {}
		blend=0.0 if not motion_units.is_empty() else 1.0
	profile=value
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
	motion_units.clear()
	blend=1.0
	_layout_units();queue_redraw()
func set_phase(value: float) -> void:
	blend=clampf(value,0,1)
	_layout_units();queue_redraw()
func unplayed_company_path() -> Array[Vector2]:
	var result: Array[Vector2]=[displayed("company")]
	for sample: Dictionary in motion_units.get("company",[]):
		if float(sample.time)>blend: result.append(World.point(sample.position))
	return result
func _layout() -> void:
	if size.x<=0 or size.y<=0: return
	if camera_enabled():
		camera.clamp_view(size)
		minimap.position=size-minimap.size-Vector2(10,10);minimap.visible=camera.zoom>1.05;minimap.queue_redraw()
		camera_hint.position=Vector2(12,size.y-24)
		camera_buttons.out.disabled=camera.zoom<=1;camera_buttons["in"].disabled=camera.zoom>=Camera.MAX_ZOOM
	var compact:=get_viewport_rect().size.x<1500
	var paper:=paper_rect()
	if ground!=null: ground.position=paper.position;ground.size=paper.size
	var occupied: Array[Rect2]=[]
	if camera_enabled():
		occupied.append(camera_bar.get_rect().grow(5))
		if minimap.visible: occupied.append(minimap.get_rect().grow(5))
	for id: String in site_buttons:
		var button: Button=site_buttons[id]
		button.add_theme_font_size_override("font_size",16 if compact else 21)
		button.custom_minimum_size=Vector2(128 if compact else 184,44 if compact else 54)
		button.size=button.custom_minimum_size
		var anchor:=_point(World.point(World.site(id,_state()).position))
		button.visible=Rect2(Vector2(8,52) if camera_enabled() else Vector2.ZERO,size-Vector2(16,82) if camera_enabled() else size).has_point(anchor)
		if camera_enabled() and minimap.visible and minimap.get_rect().grow(8).has_point(anchor): button.visible=false
		if not button.visible: continue
		var label_bounds:=Rect2(Vector2(8,50),size-Vector2(16,78)) if camera_enabled() else paper
		var desired:=anchor+Vector2(-button.size.x/2,20)
		button.position=Vector2(clampf(desired.x,paper.position.x,maxf(paper.position.x,paper.end.x-button.size.x)),clampf(desired.y,paper.position.y,maxf(paper.position.y,paper.end.y-button.size.y)))
		if _state().has("geography"):
			for offset: Vector2 in [Vector2(-button.size.x/2,20),Vector2(-button.size.x/2,-button.size.y-20),Vector2(12,20),Vector2(-button.size.x-12,20),Vector2(-button.size.x/2,76),Vector2(-button.size.x/2,-button.size.y-76)]:
				var candidate:=anchor+offset
				candidate=Vector2(clampf(candidate.x,label_bounds.position.x,label_bounds.end.x-button.size.x),clampf(candidate.y,label_bounds.position.y,label_bounds.end.y-button.size.y))
				var available:=true
				for previous: Rect2 in occupied:
					if previous.grow(4).intersects(Rect2(candidate,button.size)): available=false
				if available: button.position=candidate;break
			occupied.append(button.get_rect())
	_layout_units();queue_redraw()
func _layout_units() -> void:
	if profile.is_empty(): return
	for actor: Dictionary in profile.living_world.actors:
		var button: Button=actor_buttons[actor.id]
		button.visible=actor.active and not preview_only
		var offset:=Vector2(15,-22) if actor.id=="caravan" else Vector2(-22,-30)
		button.position=_point(displayed(actor.id))+offset-Vector2(16,16)
		button.size=Vector2(32,32)
	if banner_layer!=null: banner_layer.queue_redraw()
	if minimap!=null: minimap.queue_redraw()
func _redraw() -> void:
	queue_redraw()
	if banner_layer!=null: banner_layer.queue_redraw()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and paper_rect().has_point(event.position):
		course_requested.emit((event.position-paper_rect().position)/paper_rect().size,"")
		accept_event()
func _draw() -> void:
	if illustration!=null: illustration.draw_features(self,paper_rect(),semantic_overlay)
	else: draw_texture_rect(PLATE,paper_rect(),false)
	if profile.is_empty(): return
	var state: Dictionary=profile.living_world
	for crossing: Dictionary in World.navigation(state).data.get("crossings",[]):
		if World.navigation(state).code_at(World.point(crossing.position))!="B": continue
		var location:=_point(World.point(crossing.position))
		draw_line(location+Vector2(-5,-4),location+Vector2(5,4),UI.INK,4,true)
		draw_line(location+Vector2(-5,-4),location+Vector2(5,4),UI.GOLD,2,true)
	var route:=PackedVector2Array()
	for position: Vector2 in unplayed_company_path(): route.append(_point(position))
	for position: Dictionary in state.party.path: route.append(_point(World.point(position)))
	if route.size()>1:
		draw_polyline(route,Color("f0d6a2"),5,true)
		draw_polyline(route,Color("993d2a"),2,true)
	for entry: Dictionary in World.definition(state).sites:
		var location:=_point(World.point(entry.position))
		draw_circle(location,7,Color("efd6a0"))
		draw_arc(location,10,0,TAU,28,UI.INK,2,true)
		if state.has("geography"):
			if not site_buttons[entry.id].visible: continue
			var rect: Rect2=site_buttons[entry.id].get_rect()
			var edge:=Vector2(clampf(location.x,rect.position.x,rect.end.x),rect.position.y if rect.position.y>location.y else rect.end.y)
			draw_line(location,edge,Color("61452e"),1,true)
	if preview_only: return
	var actual:=_point(displayed("company"))
	var banner:=actual+Vector2(0,-66)
	draw_line(actual,banner,UI.INK,2,true)
	draw_circle(actual,7,Color("ad4d35"))
	draw_circle(actual,10,UI.GOLD,false,2,true)
	draw_colored_polygon(PackedVector2Array([banner+Vector2(-17,-10),banner+Vector2(17,-10),banner+Vector2(17,15),banner+Vector2(0,25),banner+Vector2(-17,15)]),Color("7b2f25"))
	draw_polyline(PackedVector2Array([banner+Vector2(-17,-10),banner+Vector2(17,-10),banner+Vector2(17,15),banner+Vector2(0,25),banner+Vector2(-17,15),banner+Vector2(-17,-10)]),UI.GOLD,2,true)
	draw_string(UI.heading_font(),banner+Vector2(-8,9),"B",HORIZONTAL_ALIGNMENT_LEFT,-1,20,UI.TEXT)

func _draw_actor_banners() -> void:
	if profile.is_empty() or preview_only: return
	for actor: Dictionary in profile.living_world.actors:
		if not actor.active: continue
		var button: Button=actor_buttons[actor.id]
		var offset:=Vector2(15,-22) if actor.id=="caravan" else Vector2(-22,-30)
		var rect:=Rect2(_point(displayed(actor.id))+offset-Vector2(16,16),Vector2(32,32))
		banner_layer.draw_style_box(button.get_theme_stylebox("hover" if button.is_hovered() else "normal"),rect)
		if button.has_focus(): banner_layer.draw_style_box(UI.focus_box(),rect)
		var font:=button.get_theme_font("font")
		var text_size:=font.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,18)
		var baseline:=Vector2((32-text_size.x)/2,(32-font.get_height(18))/2+font.get_ascent(18))
		banner_layer.draw_string(font,rect.position+baseline,button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,COLORS[actor.id])

func _get_tooltip(at_position: Vector2) -> String:
	if not paper_rect().has_point(at_position): return ""
	var terrain:=preload("res://scripts/domain/terrain_navigation.gd")
	var position: Vector2=(at_position-paper_rect().position)/paper_rect().size
	var kind: Dictionary=terrain.TYPES[World.navigation(_state()).code_at(position)]
	return "%s / %s" % [kind.name,"impassable" if kind.cost==0 else "%d%% base travel speed" % roundi(100.0/float(kind.cost))]
