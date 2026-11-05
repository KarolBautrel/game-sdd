extends RefCounted
## Presentation-only semantic adapter. Map authoring IDs/domain stay authoritative.
const Assets := preload("res://scripts/presentation/shared/asset_catalog.gd")
static var _data: Dictionary={}
static var _boards: Dictionary={}
static func data() -> Dictionary:
	if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/presentation/world_art.json"))
	return _data

static func prop(path: String) -> Dictionary:
	if path.is_empty():return {}
	var catalogue:=data()
	if catalogue.floor_routes.has(path):return {"path":catalogue.floors[catalogue.floor_routes[path]],"size":[140,104],"pivot":[70,104],"floor":true}
	if path.begins_with("res://assets/combat/environment/props/") or path.begins_with("res://assets/combat/environment/painted_v2/"):return catalogue.assets.get(path.get_file().get_basename(),{})
	var id:=str(catalogue.legacy_routes.get(path,""))
	return catalogue.assets.get(id,{})

static func texture(path: String) -> Texture2D:
	var row:=prop(path)
	return Assets.texture(str(row.get("path",path)))

static func ledge(theme: String) -> Texture2D:
	return Assets.texture(data().ledges.get(theme,data().ledges.nature))

static func terrain_explanation(kind: String) -> String:
	match kind:
		"blocked":return "Impassable. Blocks ranged line of sight."
		"cover_low":return "Low cover: incoming ranged hit chance -20. Walkable:1 MP."
		"highground":return "High ground: ranged hit chance +10, maximum range +1. Entry:2 MP."
		_:return "Open ground:1 MP."

static func board(state: Dictionary,size: Vector2i,theme: String) -> Texture2D:
	var id:=str(state.get("id",""))
	var kind:="flagstone" if theme=="dungeon" else ("woodland" if id.contains("forest") else ("earth" if id.contains("road") or id.contains("ambush") else "woodland"))
	var key:="%s:%s:%s" % [kind,size.x,size.y]
	if _boards.has(key):return _boards[key]
	var patch:=Assets.image_copy(data().floors[kind])
	var image:=Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
	for y in range(0,size.y,patch.get_height()):
		for x in range(0,size.x,patch.get_width()):image.blit_rect(patch,Rect2i(Vector2i.ZERO,patch.get_size()),Vector2i(x,y))
	var result:=ImageTexture.create_from_image(image)
	_boards[key]=result
	return result
