extends PanelContainer
## Presentation-only inspection; no resolver, save or encounter mutation.
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const Art := preload("res://scripts/presentation/combat/combat_unit_art.gd")
const DIRECTIONS := ["south","south_west","west","north_west","north","north_east","east","south_east"]
const ACTIONS := ["pose","walk","combat","hit","death"]
var profiles: Array = []
var page := 0
var direction := "east"
var action := "pose"
var frame := 0
var playing := true
var grid: GridContainer
var caption: Label
var cards: Array[Dictionary] = []
var art := Art.new()
var timer: Timer
var pause_button: Button
var scroll: ScrollContainer


func _ready() -> void:
	name = "OriginalRosterGallery"
	z_index = 4090
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	profiles = JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/presentation/original_roster.json")).characters
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	add_child(column)
	var bar := HBoxContainer.new()
	column.add_child(bar)
	caption = UI.label(bar,"Original roster",28,UI.GOLD)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for title in ["Previous","Next","Pause","Close"]:
		var button := UI.button(title)
		bar.add_child(button)
		button.pressed.connect(_command.bind(title))
		if title=="Pause":pause_button=button
	var controls := HBoxContainer.new()
	column.add_child(controls)
	var facing := OptionButton.new()
	facing.custom_minimum_size=Vector2(240,64)
	facing.name = "GalleryFacing"
	for value in DIRECTIONS: facing.add_item(value)
	facing.select(DIRECTIONS.find(direction))
	facing.item_selected.connect(func(index: int) -> void: direction=DIRECTIONS[index];frame=0;_refresh())
	controls.add_child(facing)
	var motion := OptionButton.new()
	motion.custom_minimum_size=Vector2(200,64)
	motion.name = "GalleryMotion"
	for value in ACTIONS: motion.add_item(value)
	motion.item_selected.connect(func(index: int) -> void:
		action=ACTIONS[index];frame=0
		timer.wait_time=Art.PROCESSED_SHEET_VISUALS["warrior"].frame_seconds[action]
		_refresh()
	)
	controls.add_child(motion)
	var hint:=UI.label(controls,"100 px/m · shared ground pivot · eight rendered views",24,UI.MUTED)
	hint.autowrap_mode=TextServer.AUTOWRAP_OFF
	hint.clip_text=true
	hint.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	hint.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation",16)
	grid.add_theme_constant_override("v_separation",16)
	scroll.add_child(grid)
	resized.connect(_responsive)
	_responsive()
	_build_page()
	timer = Timer.new()
	timer.wait_time = .2
	timer.timeout.connect(_tick)
	add_child(timer)
	timer.start()
	# The parent battle's _input shortcuts are suspended while inspecting art.
	get_parent().set_process_input(false)


func _responsive() -> void:
	if grid != null: grid.columns = maxi(1,mini(3,int((size.x-48)/660)))


func _command(command: String) -> void:
	match command:
		"Close":
			get_parent().set_process_input(true)
			queue_free()
		"Pause": playing=not playing;pause_button.text="Pause" if playing else "Resume"
		"Previous": page=posmod(page-1,ceili(profiles.size()/6.0));_build_page()
		"Next": page=(page+1)%ceili(profiles.size()/6.0);_build_page()


func _build_page() -> void:
	for child in grid.get_children(): grid.remove_child(child);child.queue_free()
	cards.clear()
	frame=0
	caption.text="Original roster  /  %s–%s of %s" % [page*6+1,mini(page*6+6,profiles.size()),profiles.size()]
	for index in range(page*6,mini(page*6+6,profiles.size())):
		var profile: Dictionary=profiles[index]
		var box:=VBoxContainer.new()
		grid.add_child(box)
		UI.label(box,profile.label,26,UI.GOLD)
		var stage:=Control.new()
		stage.custom_minimum_size=Vector2(640,384)
		stage.mouse_filter=Control.MOUSE_FILTER_IGNORE
		box.add_child(stage)
		var ground:=ColorRect.new()
		ground.color=Color("66513a")
		ground.position=Vector2(24,316)
		ground.size=Vector2(592,1)
		ground.mouse_filter=Control.MOUSE_FILTER_IGNORE
		stage.add_child(ground)
		var unit: Dictionary={"id":profile.id,"team":"enemy","visual":{"faction":"original","character":profile.id}}
		var sprite:=TextureRect.new()
		sprite.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.mouse_filter=Control.MOUSE_FILTER_IGNORE
		sprite.size=Vector2(art.sprite_size(unit,Vector2i(512,384)))
		var pivot: Vector2i=Art.PROCESSED_SHEET_VISUALS[profile.id].pivot
		sprite.position=Vector2(320,316)-Vector2(pivot)
		stage.add_child(sprite)
		UI.label(box,"%s  /  %s" % [profile.id,profile.weapon],24,UI.MUTED)
		cards.append({"id":profile.id,"sprite":sprite})
	_refresh()


func _tick() -> void:
	if not playing:return
	var count:=art.processed_sheet_frame_count("warrior",action)
	frame=mini(frame+1,count-1) if action=="death" else (frame+1)%count
	_refresh()


func _refresh() -> void:
	for card: Dictionary in cards:
		var unit: Dictionary={"id":card.id,"team":"enemy","visual":{"faction":"original","character":card.id}}
		card.sprite.texture=art.icon(unit,{}, {card.id:direction},{card.id:"%s:%s" % [action,frame]},Vector2i(512,384))


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		_command("Close")
		get_viewport().set_input_as_handled()
