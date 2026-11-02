extends SceneTree

const PartyCard := preload("res://scenes/ui/PartyCard.tscn")
const Meter := preload("res://scenes/ui/ResourceMeter.tscn")
const PixelSkin := preload("res://scripts/presentation/shared/pixel_skin.gd")
const Roster := preload("res://scripts/domain/party_roster.gd")
const Assets := preload("res://scripts/presentation/shared/asset_catalog.gd")
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var cards: Array = [PartyCard.instantiate(), PartyCard.instantiate()]
	var hero: Dictionary = Roster.heroes_for_formation(Roster.default_party_formation())[0]
	var original := hero.duplicate(true)
	for card in cards:
		root.add_child(card)
		card.configure(hero, 14, Color.RED, PixelSkin.flat_frame(Color.BLACK, Color.GOLD, 1, 4))
	cards[0].set_hp(0)
	if cards[0].hp_label.text != "HP 0/14" or cards[0].hp_bar.value != 0 or cards[1].hp_bar.value != 14:
		failures.append("Party card instances share HP or fail to show incapacitation")
	for refresh in range(4):
		cards[0].set_hp(9)
	if cards[0].hp_label.text != "HP 9/14" or cards[0].get_node("Margin/Content").get_child_count() != 4 or hero != original:
		failures.append("Party refresh duplicates nodes or mutates roster data")
	var meters: Array = [Meter.instantiate(), Meter.instantiate()]
	for meter in meters:
		root.add_child(meter)
		meter.configure(null, Vector2(120, 24))
		meter.set_amount(2, 2)
	meters[0].set_amount(0, 2)
	if meters[0].value != 0 or meters[1].value != 2:
		failures.append("Meter values share state")
	meters[0].set_amount(9, 2)
	if meters[0].value != 2:
		failures.append("Meter no longer clamps overflow")
	var skin := PixelSkin.new()
	var other_skin := PixelSkin.new()
	var path := Assets.paths_under("res://assets/ui/dungeon")[0]
	var first := skin.frame(path, Vector4.ONE * 10, Vector4.ONE * 4)
	var second := skin.frame(path, Vector4.ONE * 10, Vector4.ONE * 8)
	if first == second or first == other_skin.frame(path, Vector4.ONE * 10, Vector4.ONE * 4):
		failures.append("Skin margin variants or independent skin instances alias")
	var small := skin.scaled_texture(path, Vector2i(30, 10))
	var large := skin.scaled_texture(path, Vector2i(60, 20))
	if small.get_size() != Vector2(30, 10) or large.get_size() != Vector2(60, 20):
		failures.append("Scaled UI variants alias")
	for component in cards + meters:
		component.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("hud_component_tests: OK")
	quit(0 if failures.is_empty() else 1)
