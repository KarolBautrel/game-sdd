extends Control
signal course_requested(position: Vector2,site_id: String)
signal actor_selected(id: String)
const R := preload("res://scripts/domain/strategic_region.gd")
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const Illustration := preload("res://scripts/presentation/world/region_illustration.gd")
const Camera := preload("res://scripts/presentation/world/map_camera.gd")
const COLORS := {"river_league":Color("83b9b1"),"iron_march":Color("b0afc6"),"cinder_compact":Color("d9b773"),"thornwood_accord":Color("9fad77")}
var profile: Dictionary={}
var previous_world: Dictionary={}
var motion: Dictionary={}
var phase := 1.0
var camera := Camera.new()
var illustration: RefCounted
var ground: TextureRect
var site_buttons: Dictionary={}
var actor_buttons: Dictionary={}
var camera_buttons: Dictionary={}
var toolbar: HBoxContainer
var minimap: Control
var drag_button := 0

func _ready() -> void:
	clip_contents=true;mouse_filter=Control.MOUSE_FILTER_STOP
	custom_minimum_size=Vector2(450,300)
	if profile.is_empty(): return
	camera.configure_world(R.G.world_scale(profile.region))
	illustration=Illustration.new();illustration.configure(profile.region.base)
	var extra: Array=["ironhold","ashmere","thornhaven"]
	illustration.symbols=illustration.symbols.filter(func(symbol):
		if symbol.slot>=8: return true
		for id: String in extra:
			if ((symbol.position-R.G.point(profile.region.sites[id].position))*R.G.Terrain.ASPECT).length()<.04: return false
		return true)
	for id: String in extra: illustration.symbols.append({"slot":10 if id=="ironhold" else (8 if id=="ashmere" else 9),"position":R.G.point(profile.region.sites[id].position),"size":Vector2.ONE*140})
	illustration.symbols.sort_custom(func(a,b): return a.position.y<b.position.y)
	ground=illustration.background();add_child(ground)
	for id: String in R.C.S.sorted_ids(profile.region.sites):
		var button := Button.new();button.text=profile.region.sites[id].name;button.focus_mode=Control.FOCUS_ALL
		button.tooltip_text="Travel to "+button.text;button.add_theme_font_size_override("font_size",17)
		for state: String in ["normal","hover","pressed","disabled"]: button.add_theme_stylebox_override(state,UI.box(Color("30251b"),UI.GOLD,0))
		button.pressed.connect(func(): course_requested.emit(R.G.point(profile.region.sites[id].position),id))
		add_child(button);site_buttons[id]=button
	toolbar=HBoxContainer.new();toolbar.position=Vector2(8,8);toolbar.z_index=5;add_child(toolbar)
	for entry: Array in [["out","-"],["in","+"],["overview","Overview"],["company","Company"]]:
		var button := Button.new();button.text=entry[1];button.custom_minimum_size=Vector2(36,34);button.add_theme_font_size_override("font_size",16)
		toolbar.add_child(button);camera_buttons[entry[0]]=button;button.pressed.connect(func(): camera_action(entry[0]))
	minimap=Control.new();minimap.size=Vector2(144,86);minimap.z_index=5;add_child(minimap)
	minimap.draw.connect(_draw_minimap);minimap.gui_input.connect(_minimap_input)
	resized.connect(_layout)
	camera.focus(R.G.point(profile.travel.position),size)
	_sync_actors();_layout()

func update_state(value: Dictionary, trace: Dictionary={}) -> void:
	if not profile.is_empty() and profile.strategy_world.core.tick!=value.strategy_world.core.tick:
		previous_world=profile.strategy_world;motion=trace;phase=0
		if int(value.strategy_world.core.tick)-int(previous_world.core.tick)!=1: previous_world={};motion={};phase=1
	profile=value
	if is_node_ready(): _sync_actors();_layout()

func set_phase(value: float) -> void:
	phase=clampf(value,0,1);_layout_actors();queue_redraw()
func snap() -> void: phase=1;motion={};_layout_actors();queue_redraw()

func company_position() -> Vector2:
	if motion.get("tick",-1)==profile.strategy_world.core.tick and not motion.get("samples",[]).is_empty():
		var cost: float=float(motion.budget)*phase
		for i in range(1,motion.samples.size()):
			var a: Dictionary=motion.samples[i-1];var b: Dictionary=motion.samples[i]
			if cost<=float(b.cost): return R.G.point(a.position).lerp(R.G.point(b.position),clampf((cost-float(a.cost))/maxf(.00000001,float(b.cost)-float(a.cost)),0,1))
		return R.G.point(motion.samples.back().position)
	return R.G.point(profile.travel.position)

func actor_position(id: String) -> Vector2:
	var world: Dictionary=profile.strategy_world
	var field := "forces" if world.forces.has(id) else "trades"
	return R.G.actor_position(profile.region,world[field][id],previous_world.get(field,{}).get(id,{}),phase)

func _sync_actors() -> void:
	var world: Dictionary=profile.strategy_world;var ids: Array=[]
	for id: String in R.C.S.sorted_ids(world.forces):
		if world.core.parties[id].headcount>0: ids.append(id)
	for id: String in R.C.S.sorted_ids(world.trades):
		if world.trades[id].status in ["transit","waiting"]: ids.append(id)
	for id: String in actor_buttons.keys():
		if id not in ids: actor_buttons[id].queue_free();actor_buttons.erase(id)
	for id: String in ids:
		if actor_buttons.has(id): continue
		var button := Button.new();button.custom_minimum_size=Vector2(28,28);button.size=Vector2(28,28);button.z_index=2;button.add_theme_font_size_override("font_size",16)
		var faction: String=world.core.parties[id].faction_id if world.forces.has(id) else world.trades[id].seller
		button.text="" if world.trades.has(id) else world.core.factions[faction].name.left(1)
		if world.trades.has(id): button.icon=UI.icon("bag");button.expand_icon=true;button.add_theme_constant_override("icon_max_width",18)
		button.tooltip_text=("Convoy / " if world.trades.has(id) else "Patrol / ")+world.core.factions[faction].name
		for state: String in ["normal","hover","pressed"]: button.add_theme_stylebox_override(state,UI.box(UI.PANEL,COLORS[faction],0))
		button.add_theme_color_override("font_color",COLORS[faction]);button.pressed.connect(func(): actor_selected.emit(id))
		add_child(button);actor_buttons[id]=button

func _layout() -> void:
	if ground==null or size.x<=0 or size.y<=0: return
	camera.clamp_view(size)
	var paper := camera.rect(size);ground.position=paper.position;ground.size=paper.size
	minimap.position=size-minimap.size-Vector2(8,8);minimap.visible=camera.zoom>1.05;minimap.queue_redraw()
	var occupied: Array[Rect2]=[toolbar.get_rect().grow(5)]
	if minimap.visible: occupied.append(minimap.get_rect().grow(5))
	var bounds := Rect2(Vector2(8,50),size-Vector2(16,66))
	for id: String in site_buttons:
		var button: Button=site_buttons[id];var at := camera.pixel_at(R.G.point(profile.region.sites[id].position),size)
		button.size=Vector2(136,32);button.visible=bounds.has_point(at);button.disabled=not profile.company.active_run.is_empty()
		if not button.visible: continue
		for offset: Vector2 in [Vector2(-68,18),Vector2(-68,-50),Vector2(18,18),Vector2(-154,18),Vector2(-68,58),Vector2(-68,-90)]:
			var candidate := (at+offset).clamp(bounds.position,bounds.end-button.size)
			button.position=candidate
			if occupied.all(func(rect): return not rect.grow(3).intersects(Rect2(candidate,button.size))): break
		occupied.append(button.get_rect())
	_layout_actors();queue_redraw()

func _layout_actors() -> void:
	if profile.is_empty(): return
	var occupied: Array[Rect2]=[]
	for button: Button in site_buttons.values():
		if button.visible: occupied.append(button.get_rect())
	if toolbar!=null: occupied.append(toolbar.get_rect())
	if minimap!=null and minimap.visible: occupied.append(minimap.get_rect())
	for id: String in R.C.S.sorted_ids(actor_buttons):
		var button: Button=actor_buttons[id]
		var anchor := camera.pixel_at(actor_position(id),size)
		button.visible=Rect2(Vector2.ZERO,size).has_point(anchor)
		if not button.visible: continue
		for attempt in range(40):
			var offset := Vector2([0,1,-1,2,-2][attempt%5]*30-14,-38-(attempt/5)*30)
			button.position=(anchor+offset).clamp(Vector2.ZERO,(size-button.size).max(Vector2.ZERO))
			if occupied.all(func(rect): return not rect.grow(1).intersects(button.get_rect())): break
		occupied.append(button.get_rect())
	if minimap!=null: minimap.queue_redraw()

func camera_action(id: String) -> void:
	match id:
		"company": camera.focus(company_position(),size)
		"overview": camera.overview(size)
		"in": camera.zoom_at(size*.5,1.25,size)
		"out": camera.zoom_at(size*.5,.8,size)
	_layout()

func _input(event: InputEvent) -> void:
	if ground==null: return
	if event is InputEventMouseButton and not event.pressed and event.button_index==drag_button: drag_button=0;return
	if event is InputEventMouseMotion and drag_button!=0: camera.pan_pixels(event.relative,size);_layout();get_viewport().set_input_as_handled();return
	if not event is InputEventMouseButton or not get_global_rect().has_point(event.position): return
	var local: Vector2=event.position-get_global_position()
	if toolbar.get_rect().has_point(local) or (minimap.visible and minimap.get_rect().has_point(local)): return
	if event.pressed and event.button_index in [MOUSE_BUTTON_RIGHT,MOUSE_BUTTON_MIDDLE]: drag_button=event.button_index;get_viewport().set_input_as_handled()
	elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]: camera.zoom_at(local,1.2 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1/1.2,size);_layout();get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var p := camera.world_at(event.position,size)
		if p.x>=0 and p.x<1 and p.y>=0 and p.y<1: course_requested.emit(p,"");accept_event()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT: drag_button=0

func _draw() -> void:
	if illustration==null: return
	var paper := camera.rect(size)
	illustration.draw_features(self,paper)
	for edge: Dictionary in profile.region.routes.values():
		var points := PackedVector2Array()
		for p: Dictionary in edge.points: points.append(camera.pixel_at(R.G.point(p),size))
		draw_polyline(points,Color("705331a0"),2,true)
	var path := PackedVector2Array([camera.pixel_at(company_position(),size)])
	if motion.get("tick",-1)==profile.strategy_world.core.tick:
		for sample: Dictionary in motion.get("samples",[]):
			if sample.cost>float(motion.get("budget",0))*phase: path.append(camera.pixel_at(R.G.point(sample.position),size))
	for p: Dictionary in profile.travel.path: path.append(camera.pixel_at(R.G.point(p),size))
	if path.size()>1: draw_polyline(path,Color("a94229"),3,true)
	for id: String in site_buttons:
		var at := camera.pixel_at(R.G.point(profile.region.sites[id].position),size)
		draw_circle(at,5,UI.GOLD);draw_circle(at,7,UI.INK,false,1.5,true)
	for id: String in actor_buttons:
		var button: Button=actor_buttons[id]
		if button.visible: draw_line(camera.pixel_at(actor_position(id),size),button.position+button.size*.5,Color("705331"),1,true)
	var company := camera.pixel_at(company_position(),size)
	draw_line(company,company+Vector2(0,-45),UI.INK,2,true)
	draw_circle(company,7,Color("ad4d35"));draw_circle(company,10,UI.GOLD,false,2,true)
	draw_colored_polygon(PackedVector2Array([company+Vector2(-14,-60),company+Vector2(14,-60),company+Vector2(14,-38),company+Vector2(0,-30),company+Vector2(-14,-38)]),Color("7b2f25"))
	draw_string(UI.heading_font(),company+Vector2(-7,-40),"B",HORIZONTAL_ALIGNMENT_LEFT,-1,20,UI.TEXT)

func _draw_minimap() -> void:
	minimap.draw_texture_rect(illustration.base,Rect2(Vector2.ZERO,minimap.size),false)
	for entry: Dictionary in profile.region.sites.values(): minimap.draw_circle(minimap.size*R.G.point(entry.position),2,UI.GOLD)
	minimap.draw_circle(minimap.size*company_position(),3,Color("c85136"))
	var visible := camera.visible_world(size)
	minimap.draw_rect(Rect2(visible.position*minimap.size,visible.size*minimap.size),UI.TEXT,false,1.5)

func _minimap_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		camera.center=(event.position/minimap.size).clamp(Vector2.ZERO,Vector2.ONE);_layout();minimap.accept_event()

func _get_tooltip(at: Vector2) -> String:
	if profile.is_empty(): return ""
	var p := camera.world_at(at,size)
	var code: String=R.G.Gen.navigation(profile.region.base).code_at(p)
	var entry: Dictionary=R.G.Terrain.TYPES[code]
	return entry.name+" / "+("impassable" if entry.cost==0 else "%d%% base speed" % roundi(100/float(entry.cost)))
