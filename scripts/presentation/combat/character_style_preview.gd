extends PanelContainer
## Opt-in static art comparison; no resolver, campaign or production art mutation.
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
const IDS := ["a_painterly_veteran", "b_ink_warden", "c_heroic_miniature"]
const TITLES := ["A · Malarski weteran", "B · Mroczny komiks", "C · Heroiczna figurka"]
const DESCRIPTIONS := ["Naturalne proporcje · skóra i wełna · brygantyna", "Kontur · kreskowanie · wyraźne plamy światła", "Większa twarz · mocna sylwetka · błękit i mosiądz"]
const VIEWS := ["three_quarter", "front", "side", "rear"]
const VIEW_LABELS := ["Ukos", "Przód", "Bok", "Tył"]
const GROUNDS := ["earth", "woodland", "cave"]
const ZOOMS := [1.0, 1.5, 2.0, 2.5, 3.0]
const ART := "res://assets/ui/character_studies/"
var direction := 0
var zoom := 2.0
var ground := 0
var faces := false
var stages: Array[Control] = []
var direction_control: OptionButton
var zoom_control: OptionButton
var ground_control: OptionButton
var face_control: Button
var host: Node
var host_input_was_enabled := false


class StudyStage extends Control:

	var actor: Texture2D
	var floor_art: Texture2D
	var shadow: Texture2D = preload("res://assets/combat/environment/contact_shadow.png")
	var magnification := 2.0
	var face_mode := false

	func _ready() -> void:
		clip_contents = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		resized.connect(queue_redraw)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("1c211f"))
		if floor_art != null:
			draw_texture_rect(floor_art, Rect2(Vector2.ZERO, size), true, Color(.68, .68, .68))
		if actor == null:
			return
		if face_mode:
			var side: float = minf(size.x - 36, size.y - 36)
			draw_rect(Rect2(Vector2.ZERO, size), Color("252b2d"))
			draw_texture_rect(actor, Rect2((size - Vector2.ONE * side) * .5, Vector2.ONE * side), false)
		else:
			var pivot := Vector2(size.x * .5, size.y * .75)
			draw_texture_rect(shadow, Rect2(pivot - Vector2(45, 11) * magnification, Vector2(90, 26) * magnification), false)
			draw_texture_rect(actor, Rect2(pivot - Vector2(140, 229) * magnification, Vector2(280, 280) * magnification), false)


func _ready() -> void:
	name = "CharacterStylePreview"
	z_index = 4091
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	add_theme_stylebox_override("panel", UI.frame("frame_dark", 28))
	mouse_filter = Control.MOUSE_FILTER_STOP
	if get_parent() is Control:
		host = get_parent()
		host_input_was_enabled = host.is_processing_input()
		host.set_process_input(false)
	else:
		DisplayServer.window_set_title("SDD · Porównanie postaci A/B/C")
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var heading := UI.label(header, "Trzy kierunki postaci", 42, UI.GOLD)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := UI.button("Zamknij" if host != null else "Do walki")
	close.name = "CloseStudyPreview"
	close.pressed.connect(_close_preview)
	header.add_child(close)
	UI.label(column, "Porównaj sylwetkę, twarz i materiały na wspólnym podłożu.", 26, UI.TEXT)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 20)
	column.add_child(controls)
	direction_control = _choice(controls, "StudyDirection", VIEW_LABELS)
	direction_control.item_selected.connect(func(index: int) -> void: direction = index; _refresh())
	zoom_control = _choice(controls, "StudyZoom", ["Skala 100%", "Skala 150%", "Skala 200%", "Skala 250%", "Skala 300%"])
	zoom_control.select(2)
	zoom_control.item_selected.connect(func(index: int) -> void: zoom = ZOOMS[index]; _refresh())
	ground_control = _choice(controls, "StudyGround", ["Podłoże: ziemia", "Podłoże: las", "Podłoże: loch"])
	ground_control.item_selected.connect(func(index: int) -> void: ground = index; _refresh())
	face_control = UI.button("Zbliżenie twarzy")
	face_control.name = "StudyFaces"
	face_control.toggle_mode = true
	face_control.toggled.connect(func(value: bool) -> void: faces = value; _refresh())
	controls.add_child(face_control)
	var cards := HBoxContainer.new()
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation", 22)
	column.add_child(cards)
	for index in range(3):
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_stretch_ratio = 1.0
		card.add_theme_stylebox_override("panel", UI.frame("frame_dark", 18))
		cards.add_child(card)
		var content := VBoxContainer.new()
		card.add_child(content)
		UI.label(content, TITLES[index], 32, UI.GOLD)
		var description := UI.label(content, DESCRIPTIONS[index], 22, UI.MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.custom_minimum_size.y = 64
		var stage := StudyStage.new()
		stage.name = "Study_" + IDS[index]
		stage.custom_minimum_size = Vector2(280, 420)
		stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content.add_child(stage)
		stages.append(stage)
	UI.label(column, "Statyczne próbki stylu · bez animacji ruchu. 100% = docelowa skala postaci na planszy.", 24, UI.MUTED)
	_refresh()
	direction_control.grab_focus()
	_report_window.call_deferred()


func _choice(parent: Node, node_name: String, labels: Array) -> OptionButton:
	var choice := OptionButton.new()
	choice.name = node_name
	choice.custom_minimum_size = Vector2(250, 64)
	for label: String in labels:
		choice.add_item(label)
	parent.add_child(choice)
	return choice


func _refresh() -> void:
	for index in range(stages.size()):
		var stage = stages[index]
		stage.actor = load(ART + IDS[index] + "/" + ("face" if faces else VIEWS[direction]) + ".png") as Texture2D
		stage.floor_art = load("res://assets/combat/environment/floors/" + GROUNDS[ground] + ".png") as Texture2D
		stage.magnification = zoom
		stage.face_mode = faces
		stage.queue_redraw()
	zoom_control.disabled = faces
	direction_control.disabled = faces


func _close_preview() -> void:
	if host != null:
		queue_free()
	else:
		get_tree().change_scene_to_file("res://scenes/combat/CombatDebug.tscn")


func _exit_tree() -> void:
	if is_instance_valid(host):
		host.set_process_input(host_input_was_enabled)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close_preview()


func _report_window() -> void:
	print("STYLE_PREVIEW_WINDOW ", JSON.stringify({"screen": DisplayServer.window_get_current_screen(), "position": [DisplayServer.window_get_position().x, DisplayServer.window_get_position().y], "size": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y], "mode": DisplayServer.window_get_mode()}))
