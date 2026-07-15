extends SceneTree

const WIDTH := 18
const HEIGHT := 11
const TILE_SIZE := 112
const OUTPUT_DIR := "res://assets/combat/terrain/backgrounds"

const GRASS_SIZE := 64
const GRASS_STEP := 26
const GRASS_EDGE_BLEND := 14
const TUFT_SIZE := 46
const SEAM_SOFTEN_PASSES := 2
const STONE_SIZE := 128
const STONE_STEP := 104
const STONE_EDGE_BLEND := 18
const DUNGEON_PROP_SIZE := 58

const GRASS_PATHS := [
	"res://assets/combat/terrain/grass/meadow_grass_floor_00.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_01.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_02.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_03.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_04.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_05.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_06.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_07.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_08.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_09.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_10.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_11.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_12.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_13.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_14.png",
	"res://assets/combat/terrain/grass/meadow_grass_floor_15.png",
]

const TUFT_PATHS := [
	"res://assets/combat/terrain/nature/grass_tuft/grass_tuft_frame_1.png",
	"res://assets/combat/terrain/nature/grass_tuft/grass_tuft_frame_2.png",
	"res://assets/combat/terrain/nature/grass_tuft/grass_tuft_frame_5.png",
	"res://assets/combat/terrain/nature/grass_tuft/grass_tuft_frame_8.png",
	"res://assets/combat/terrain/nature/grass_tuft/grass_tuft_frame_9.png",
	"res://assets/combat/terrain/nature/grass_tuft/grass_tuft_frame_12.png",
	"res://assets/combat/terrain/nature/grass_tuft/grass_tuft_frame_13.png",
	"res://assets/combat/terrain/nature/grass_tuft/grass_tuft_frame_15.png",
]

const STONE_PATHS := [
	"res://assets/combat/terrain/floors/stone/stones1.png",
	"res://assets/combat/terrain/floors/stone/stones2.png",
]

const DUNGEON_PROP_PATHS := [
	"res://assets/combat/dungeons/props/skull_pile_01.png",
	"res://assets/combat/dungeons/props/hanging_chains_01.png",
	"res://assets/combat/dungeons/props/ornate_floor_tablet_01.png",
	"res://assets/combat/dungeons/props/gold_gem_pile_01.png",
]

const BACKGROUNDS := [
	{
		"name": "old_mine_meadow_00_lush",
		"seed": 101,
		"base": Color(0.055, 0.215, 0.065),
		"primary": [3],
		"accent": [4, 5, 8, 10],
		"accent_rate": 4,
		"tuft_count": 7,
	},
	{
		"name": "old_mine_meadow_01_deep_green",
		"seed": 137,
		"base": Color(0.040, 0.170, 0.060),
		"primary": [5],
		"accent": [3, 8, 10, 11],
		"accent_rate": 4,
		"tuft_count": 7,
	},
]

var grass_images: Dictionary = {}
var tuft_images: Dictionary = {}
var stone_images: Dictionary = {}
var dungeon_prop_images: Dictionary = {}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_remove_old_backgrounds()
	_load_sources()
	for config: Dictionary in BACKGROUNDS:
		_generate_background(config)
	_generate_dungeon_background({
		"name": "old_mine_dungeon_00_stone",
		"seed": 211,
		"base": Color(0.105, 0.108, 0.112),
		"prop_count": 12,
	})
	print("Generated combat backgrounds in %s" % OUTPUT_DIR)
	quit()


func _remove_old_backgrounds() -> void:
	var dir := DirAccess.open(OUTPUT_DIR)
	if dir == null:
		return
	for file_name in dir.get_files():
		if (file_name.begins_with("old_mine_meadow_") or file_name.begins_with("old_mine_dungeon_")) and file_name.ends_with(".png"):
			dir.remove(file_name)


func _load_sources() -> void:
	for index in range(GRASS_PATHS.size()):
		var image := Image.new()
		var error := image.load(GRASS_PATHS[index])
		if error == OK:
			grass_images[index] = image
		else:
			push_error("Cannot load grass source: %s" % GRASS_PATHS[index])

	for index in range(TUFT_PATHS.size()):
		var image := Image.new()
		var error := image.load(TUFT_PATHS[index])
		if error == OK:
			tuft_images[index] = image
		else:
			push_error("Cannot load grass tuft source: %s" % TUFT_PATHS[index])

	for index in range(STONE_PATHS.size()):
		var image := Image.new()
		var error := image.load(STONE_PATHS[index])
		if error == OK:
			stone_images[index] = image
		else:
			push_error("Cannot load stone floor source: %s" % STONE_PATHS[index])

	for index in range(DUNGEON_PROP_PATHS.size()):
		var image := Image.new()
		var error := image.load(DUNGEON_PROP_PATHS[index])
		if error == OK:
			dungeon_prop_images[index] = image
		else:
			push_error("Cannot load dungeon prop source: %s" % DUNGEON_PROP_PATHS[index])


func _generate_background(config: Dictionary) -> void:
	var image := Image.create(WIDTH * TILE_SIZE, HEIGHT * TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(config["base"])
	_paint_grass_asset_carpet(image, config)
	_soften_dark_grass_seams(image)
	_apply_meadow_color_wash(image, int(config["seed"]))
	_paint_tuft_accents(image, config)

	var output_path := "%s/%s.png" % [OUTPUT_DIR, config["name"]]
	var error := image.save_png(output_path)
	if error != OK:
		push_error("Cannot save combat background: %s" % output_path)


func _paint_grass_asset_carpet(target: Image, config: Dictionary) -> void:
	var seed := int(config["seed"])
	var columns := int(ceil(float(target.get_width()) / float(GRASS_STEP))) + 3
	var rows := int(ceil(float(target.get_height()) / float(GRASS_STEP))) + 3

	for row in range(rows):
		for column in range(columns):
			var grass_index := _pick_grass_index(column, row, config)
			if not grass_images.has(grass_index):
				continue
			var stagger := 0 if row % 2 == 0 else int(GRASS_STEP / 2)
			var jitter := Vector2i(
				_hash_signed(column, row, 11, seed, 9),
				_hash_signed(row, column, 17, seed, 9)
			)
			var destination := Vector2i(
				column * GRASS_STEP - GRASS_SIZE + stagger,
				row * GRASS_STEP - GRASS_SIZE
			) + jitter
			_blend_patch_feathered(target, grass_images[grass_index], destination)


func _paint_tuft_accents(target: Image, config: Dictionary) -> void:
	if tuft_images.is_empty():
		return
	var seed := int(config["seed"])
	for index in range(int(config["tuft_count"])):
		var tuft_index := _hash(index, 23, 29, seed) % tuft_images.size()
		if not tuft_images.has(tuft_index):
			continue
		var scaled: Image = tuft_images[tuft_index].duplicate()
		scaled.resize(TUFT_SIZE, TUFT_SIZE, Image.INTERPOLATE_NEAREST)
		var position := Vector2i(
			_hash(index, 31, 37, seed) % maxi(1, target.get_width() - TUFT_SIZE),
			_hash(index, 41, 43, seed) % maxi(1, target.get_height() - TUFT_SIZE)
		)
		_blend_patch_clipped(target, scaled, position)


func _generate_dungeon_background(config: Dictionary) -> void:
	var image := Image.create(WIDTH * TILE_SIZE, HEIGHT * TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(config["base"])
	_paint_stone_asset_carpet(image, config)
	_apply_dungeon_color_wash(image, int(config["seed"]))
	_paint_dungeon_prop_accents(image, config)

	var output_path := "%s/%s.png" % [OUTPUT_DIR, config["name"]]
	var error := image.save_png(output_path)
	if error != OK:
		push_error("Cannot save combat background: %s" % output_path)


func _paint_stone_asset_carpet(target: Image, config: Dictionary) -> void:
	if stone_images.is_empty():
		return
	var seed := int(config["seed"])
	var columns := int(ceil(float(target.get_width()) / float(STONE_STEP))) + 2
	var rows := int(ceil(float(target.get_height()) / float(STONE_STEP))) + 2

	for row in range(rows):
		for column in range(columns):
			var stone_index := _hash(column, row, 71, seed) % stone_images.size()
			if not stone_images.has(stone_index):
				continue
			var jitter := Vector2i(
				_hash_signed(column, row, 73, seed, 13),
				_hash_signed(row, column, 79, seed, 13)
			)
			var destination := Vector2i(
				column * STONE_STEP - 12,
				row * STONE_STEP - 12
			) + jitter
			_blend_patch_feathered_with_edge(target, stone_images[stone_index], destination, STONE_EDGE_BLEND)


func _paint_dungeon_prop_accents(target: Image, config: Dictionary) -> void:
	if dungeon_prop_images.is_empty():
		return
	var seed := int(config["seed"])
	for index in range(int(config["prop_count"])):
		var prop_index := _hash(index, 83, 89, seed) % dungeon_prop_images.size()
		if not dungeon_prop_images.has(prop_index):
			continue
		var scaled: Image = dungeon_prop_images[prop_index].duplicate()
		scaled.resize(DUNGEON_PROP_SIZE, DUNGEON_PROP_SIZE, Image.INTERPOLATE_NEAREST)
		var position := Vector2i(
			_hash(index, 97, 101, seed) % maxi(1, target.get_width() - DUNGEON_PROP_SIZE),
			_hash(index, 103, 107, seed) % maxi(1, target.get_height() - DUNGEON_PROP_SIZE)
		)
		_blend_patch_clipped(target, scaled, position)


func _apply_dungeon_color_wash(target: Image, seed: int) -> void:
	for y in range(target.get_height()):
		for x in range(target.get_width()):
			var color: Color = target.get_pixel(x, y)
			var variation: float = (
				sin((float(x) + float(seed * 11)) * 0.010)
				+ cos((float(y) + float(seed * 17)) * 0.013)
				+ sin((float(x - y) + float(seed * 3)) * 0.005)
			) / 3.0
			var cold_tint := Color(0.10, 0.115, 0.125)
			var warm_dirt := Color(0.16, 0.14, 0.115)
			var patch_roll: float = float(_hash(x / 128, y / 128, 109, seed) % 100) / 100.0
			color = color.lerp(cold_tint.lerp(warm_dirt, patch_roll), 0.07)
			if variation > 0.2:
				color = color.lightened(0.025)
			elif variation < -0.2:
				color = color.darkened(0.035)
			target.set_pixel(x, y, color)


func _soften_dark_grass_seams(target: Image) -> void:
	for _pass_index in range(SEAM_SOFTEN_PASSES):
		var source := target.duplicate()
		for y in range(1, target.get_height() - 1):
			for x in range(1, target.get_width() - 1):
				var center: Color = source.get_pixel(x, y)
				var neighbor_average: Color = (
					source.get_pixel(x - 1, y)
					+ source.get_pixel(x + 1, y)
					+ source.get_pixel(x, y - 1)
					+ source.get_pixel(x, y + 1)
				) / 4.0
				var center_luma := _luma(center)
				var neighbor_luma := _luma(neighbor_average)
				if neighbor_luma - center_luma < 0.045:
					continue
				target.set_pixel(x, y, center.lerp(neighbor_average, 0.42))


func _apply_meadow_color_wash(target: Image, seed: int) -> void:
	for y in range(target.get_height()):
		for x in range(target.get_width()):
			var color: Color = target.get_pixel(x, y)
			var broad_variation: float = (
				sin((float(x) + float(seed * 13)) * 0.012)
				+ cos((float(y) + float(seed * 7)) * 0.010)
				+ sin((float(x + y) + float(seed * 5)) * 0.006)
			) / 3.0
			var warm_patch: float = float(_hash(x / 96, y / 96, 61, seed) % 100) / 100.0
			var tint_strength: float = 0.025 + abs(broad_variation) * 0.035
			var tint: Color = Color(0.075, 0.23, 0.065).lerp(Color(0.17, 0.30, 0.085), warm_patch)
			color = color.lerp(tint, tint_strength)
			if broad_variation > 0.18:
				color = color.lightened(0.018)
			elif broad_variation < -0.22:
				color = color.darkened(0.018)
			target.set_pixel(x, y, color)


func _pick_grass_index(column: int, row: int, config: Dictionary) -> int:
	var seed := int(config["seed"])
	var roll := _hash(column, row, 47, seed) % 100
	var source: Array = config["primary"]
	if roll < int(config["accent_rate"]):
		source = config["accent"]
	var source_index := _hash(row + 3, column + 7, 53, seed) % source.size()
	return int(source[source_index])


func _blend_patch_clipped(target: Image, patch: Image, destination: Vector2i) -> void:
	var src_position := Vector2i.ZERO
	var dst_position := destination
	var size := patch.get_size()

	if dst_position.x < 0:
		src_position.x = -dst_position.x
		size.x -= src_position.x
		dst_position.x = 0
	if dst_position.y < 0:
		src_position.y = -dst_position.y
		size.y -= src_position.y
		dst_position.y = 0
	if dst_position.x + size.x > target.get_width():
		size.x = target.get_width() - dst_position.x
	if dst_position.y + size.y > target.get_height():
		size.y = target.get_height() - dst_position.y
	if size.x <= 0 or size.y <= 0:
		return

	target.blend_rect(patch, Rect2i(src_position, size), dst_position)


func _blend_patch_feathered(target: Image, patch: Image, destination: Vector2i) -> void:
	_blend_patch_feathered_with_edge(target, patch, destination, GRASS_EDGE_BLEND)


func _blend_patch_feathered_with_edge(target: Image, patch: Image, destination: Vector2i, edge_blend: int) -> void:
	var src_position := Vector2i.ZERO
	var dst_position := destination
	var size := patch.get_size()

	if dst_position.x < 0:
		src_position.x = -dst_position.x
		size.x -= src_position.x
		dst_position.x = 0
	if dst_position.y < 0:
		src_position.y = -dst_position.y
		size.y -= src_position.y
		dst_position.y = 0
	if dst_position.x + size.x > target.get_width():
		size.x = target.get_width() - dst_position.x
	if dst_position.y + size.y > target.get_height():
		size.y = target.get_height() - dst_position.y
	if size.x <= 0 or size.y <= 0:
		return

	for y in range(size.y):
		for x in range(size.x):
			var source := src_position + Vector2i(x, y)
			var target_position := dst_position + Vector2i(x, y)
			var source_color: Color = patch.get_pixelv(source)
			var edge_distance: int = mini(mini(source.x, source.y), mini(patch.get_width() - 1 - source.x, patch.get_height() - 1 - source.y))
			var edge_alpha: float = clamp(float(edge_distance) / float(edge_blend), 0.0, 1.0)
			var blend_alpha: float = source_color.a * edge_alpha
			if blend_alpha <= 0.0:
				continue
			var target_color: Color = target.get_pixelv(target_position)
			source_color.a = blend_alpha
			target.set_pixelv(target_position, target_color.blend(source_color))


func _hash(a: int, b: int, c: int, seed: int) -> int:
	var value := a * 73856093 ^ b * 19349663 ^ c * 83492791 ^ seed * 2654435761
	return absi(value)


func _hash_signed(a: int, b: int, c: int, seed: int, span: int) -> int:
	return int(_hash(a, b, c, seed) % span) - int(span / 2)


func _luma(color: Color) -> float:
	return color.r * 0.299 + color.g * 0.587 + color.b * 0.114
