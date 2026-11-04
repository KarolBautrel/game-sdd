extends Control
## Isolated courtyard pilot; no campaign state or transaction ownership.
const Model := preload("res://scripts/domain/town_exploration_model.gd")
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const Art := preload("res://scripts/presentation/combat/combat_unit_art.gd")
const EnvironmentArt := preload("res://scripts/presentation/combat/environment_art.gd")
const SPACE := "res://resources/data/town_spaces/ravenford_courtyard.json"
var space: Dictionary
var map: Dictionary
var npcs: Array[Dictionary]=[]
var npc_positions: Array[Vector2]=[]
var party_positions: Array[Vector2]=[]
var trail: Array[Vector2]=[]
var actors: Array[Dictionary]=[]
var art:=Art.new()
var held: Dictionary={}
var elapsed:=0.0
var walking:=false
var facing:="south_east"
var near_id:=""
var talking_id:=""
var world_frame: Control
var world: Node2D
var depth: Node2D
var prompt: Label
var dialogue: PanelContainer
var speaker: Label
var speech: Label
var close_dialogue: Button
var blocker: Control

func _ready() -> void:
	theme=UI.theme()
	space=JSON.parse_string(FileAccess.get_file_as_string(SPACE))
	map=JSON.parse_string(FileAccess.get_file_as_string(space.map_path))
	_register_actions()
	for row: Dictionary in space.npcs:
		var npc:=row.duplicate(true);npc.position=_spawn(row.spawn_id)
		npcs.append(npc);npc_positions.append(Vector2(npc.position.x,npc.position.y))
	var start:=_spawn(space.entry_spawn)
	party_positions=[Vector2(start.x,start.y),Vector2.ZERO,Vector2.ZERO]
	for i in range(80):trail.append(party_positions[0]+Model.unproject(Vector2(0,i*2)))
	for i in range(1,3):party_positions[i]=Model.trail_position(trail,i*52.0)
	_build()
	resized.connect(_layout)
	world_frame.resized.connect(_layout)
	_layout.call_deferred()
	set_process_unhandled_input(true)
	focus_mode=Control.FOCUS_ALL
	grab_focus()

func _spawn(id: String) -> Dictionary:
	for row: Dictionary in map.test_spawns:
		if row.id==id:return {"x":float(row.x)+0.5,"y":float(row.y)+0.5}
	push_error("Unknown town spawn: "+id)
	return {"x":5.5,"y":6.5}

func _register_actions() -> void:
	var defaults:={"town_up":[KEY_W,KEY_UP],"town_down":[KEY_S,KEY_DOWN],"town_left":[KEY_A,KEY_LEFT],"town_right":[KEY_D,KEY_RIGHT],"town_interact":[KEY_E,KEY_ENTER],"town_cancel":[KEY_ESCAPE]}
	for action: String in defaults:
		if InputMap.has_action(action):continue
		InputMap.add_action(action)
		for key: int in defaults[action]:
			var event:=InputEventKey.new();event.physical_keycode=key
			InputMap.action_add_event(action,event)

func _build() -> void:
	var leather:=TextureRect.new();leather.texture=UI.Assets.texture(UI.ART+"leather.png")
	leather.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);leather.stretch_mode=TextureRect.STRETCH_TILE
	leather.modulate=Color(0.35,0.34,0.30);leather.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(leather)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","top","right","bottom"]:margin.add_theme_constant_override("margin_"+edge,20)
	add_child(margin)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);margin.add_child(column)
	var header:=PanelContainer.new();header.add_theme_stylebox_override("panel",UI.frame("frame_dark",18));column.add_child(header)
	var labels:=VBoxContainer.new();header.add_child(labels)
	UI.label(labels,"Ravenford | The Lantern Court",32,UI.GOLD)
	UI.label(labels,"Courtyard movement study  /  WASD or arrows to walk  /  E to talk  /  Esc to close a conversation",24,UI.TEXT)
	world_frame=Control.new();world_frame.name="TownWorld";world_frame.size_flags_vertical=Control.SIZE_EXPAND_FILL
	world_frame.clip_contents=true;world_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(world_frame)
	world=Node2D.new();world_frame.add_child(world)
	var ground:=Polygon2D.new()
	ground.polygon=PackedVector2Array([Model.project(Vector2.ZERO),Model.project(Vector2(map.width,0)),Model.project(Vector2(map.width,map.height)),Model.project(Vector2(0,map.height))])
	ground.texture=UI.Assets.texture(EnvironmentArt.data().floors.flagstone)
	ground.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED;ground.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	ground.uv=ground.polygon;ground.modulate=Color(0.80,0.82,0.80);world.add_child(ground)
	depth=Node2D.new();depth.y_sort_enabled=true;world.add_child(depth)
	for decoration: Dictionary in map.terrain_decorations:
		var prop:=EnvironmentArt.prop(decoration.path)
		var node:=Node2D.new();node.position=Model.project(Vector2(decoration.x+0.5,decoration.y+0.5));depth.add_child(node)
		var sprite:=Sprite2D.new();sprite.texture=EnvironmentArt.texture(decoration.path);sprite.centered=false
		sprite.offset=-Vector2(prop.pivot[0],prop.pivot[1]);sprite.scale=Vector2.ONE*0.65;node.add_child(sprite)
	for i in range(3):_actor(["warrior","archer_1","rogue_1"][i],"party",i)
	for i in npcs.size():_actor(npcs[i].profile,"npc",i)
	var footer:=PanelContainer.new();footer.add_theme_stylebox_override("panel",UI.frame("frame_dark",18));column.add_child(footer)
	var row:=HBoxContainer.new();footer.add_child(row)
	prompt=UI.label(row,"Follow the lanterns. Approach someone to speak.",24,UI.GOLD);prompt.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var exit:=UI.button("Close preview");exit.pressed.connect(func() -> void:get_tree().quit());row.add_child(exit)
	blocker=Control.new();blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);blocker.mouse_filter=Control.MOUSE_FILTER_STOP;blocker.hide();add_child(blocker)
	dialogue=PanelContainer.new();dialogue.name="TownDialogue";dialogue.add_theme_stylebox_override("panel",UI.paper_box(24));blocker.add_child(dialogue)
	var body:=VBoxContainer.new();body.add_theme_constant_override("separation",12);dialogue.add_child(body)
	speaker=UI.label(body,"",30,UI.INK)
	var scroll:=ScrollContainer.new();scroll.name="DialogueScroll";scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y=140;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(scroll)
	speech=UI.label(scroll,"",24,UI.INK);speech.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;speech.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	close_dialogue=UI.button("Continue");close_dialogue.pressed.connect(_close_dialogue);body.add_child(close_dialogue)
	_update_actors()

func _actor(profile: String, kind: String, index: int) -> void:
	var node:=Node2D.new();depth.add_child(node)
	var sprite:=Sprite2D.new();sprite.centered=false;sprite.offset=Vector2(-192,-270);sprite.scale=Vector2.ONE*0.65
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;node.add_child(sprite)
	actors.append({"node":node,"sprite":sprite,"profile":profile,"kind":kind,"index":index,"path":"","last":Vector2.INF,"facing":"south_east"})
	if kind=="npc":
		var caption:=Label.new();caption.text=str(npcs[index].name).get_slice(" |",0)
		caption.add_theme_font_override("font",UI.body_font());caption.add_theme_font_size_override("font_size",18)
		caption.add_theme_color_override("font_color",UI.GOLD);caption.add_theme_color_override("font_outline_color",Color.BLACK);caption.add_theme_constant_override("outline_size",4)
		caption.position=Vector2(-70,-148);caption.size=Vector2(140,24);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		node.add_child(caption)

func _layout() -> void:
	if world_frame==null:return
	var area:=Rect2(Vector2(-480,-160),Vector2(1056,736))
	var factor:=minf(world_frame.size.x/area.size.x,world_frame.size.y/area.size.y)
	world.scale=Vector2.ONE*factor
	world.position=(world_frame.size-area.size*factor)/2.0-area.position*factor
	var width:=minf(800,size.x-60)
	var height:=minf(440,maxf(320,size.y-160))
	dialogue.position=Vector2((size.x-width)/2.0,(size.y-height)/2.0)
	dialogue.size=Vector2(width,height)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:return
	for action in ["town_up","town_down","town_left","town_right"]:
		if event.is_action(action):
			if event.is_pressed():held[action]=true
			else:held.erase(action)
			get_viewport().set_input_as_handled()
	if event.is_action_pressed("town_cancel") and not talking_id.is_empty():_close_dialogue();get_viewport().set_input_as_handled()
	elif event.is_action_pressed("town_interact") and talking_id.is_empty():
		_open_dialogue(near_id);get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:held.clear()

func _physics_process(dt: float) -> void:
	if world==null:return
	elapsed+=dt
	if talking_id.is_empty():
		var axis:=Vector2(float(held.get("town_right",false))-float(held.get("town_left",false)),float(held.get("town_down",false))-float(held.get("town_up",false)))
		var old:=party_positions[0]
		party_positions[0]=Model.move(old,axis,dt,map,npc_positions)
		var travel:=Model.project(party_positions[0]-old)
		walking=travel.length()>0.001
		if walking:
			facing=_direction(travel)
			if Model.project(party_positions[0]-trail[0]).length()>=2:
				trail.push_front(party_positions[0]);trail.resize(mini(trail.size(),256))
			for i in range(1,3):party_positions[i]=Model.trail_position(trail,i*52.0,map,npc_positions)
		near_id=Model.nearest(party_positions[0],npcs,100.0,map)
		prompt.text="E  /  Speak to "+_npc(near_id).get("name","") if not near_id.is_empty() else "Follow the lanterns. Approach someone to speak."
	else:walking=false
	_update_actors()

func _direction(vector: Vector2) -> String:
	var index:=posmod(int(round(vector.angle()/(PI/4.0))),8)
	return ["east","south_east","south","south_west","west","north_west","north","north_east"][index]

func _update_actors() -> void:
	for row: Dictionary in actors:
		var point: Vector2=party_positions[row.index] if row.kind=="party" else npc_positions[row.index]
		row.node.position=Model.project(point)
		var moving: bool=walking and row.kind=="party"
		if row.last!=Vector2.INF and moving:row.facing=_direction(Model.project(point-row.last))
		row.last=point
		var action:="neutral_walk" if moving else "neutral_idle"
		var frame:=int(elapsed/(0.125 if moving else 0.25))%(8 if moving else 4)
		var path:=art.processed_sheet_texture_path(row.profile,row.facing,action+":"+str(frame))
		if path!=row.path:row.sprite.texture=UI.Assets.texture(path);row.path=path

func _npc(id: String) -> Dictionary:
	for row: Dictionary in npcs:
		if row.id==id:return row
	return {}

func _open_dialogue(id: String) -> void:
	var npc:=_npc(id)
	if npc.is_empty():return
	talking_id=id;held.clear();walking=false
	speaker.text=npc.name;speech.text=npc.dialogue+"\n\n"+npc.service_hint
	blocker.show();_layout();UI.focus_later(close_dialogue)
	_settle_dialogue()

func _settle_dialogue() -> void:
	# Wrapped text may initially report a tall minimum before its width settles.
	await get_tree().process_frame
	await get_tree().process_frame
	if is_inside_tree() and not talking_id.is_empty():_layout()

func _close_dialogue() -> void:
	talking_id="";held.clear();blocker.hide();grab_focus()
