extends Node
## Rigged actors rendered as transparent textures in the existing2D board.
const CELL := Vector2i(640,448)
const PIVOT := Vector2(320,314)
const YAW := {"south":0,"south_west":15,"west":30,"north_west":60,"north":180,"north_east":300,"east":330,"south_east":345}
const Items := preload("res://scripts/domain/item_catalog.gd")
var viewport: SubViewport
var camera: Camera3D
var actors: Dictionary={}
var manifest: Dictionary={}
var columns := 4


func _ready() -> void:
	var path:="res://resources/data/presentation/modular_actors.json"
	if FileAccess.file_exists(path):manifest=JSON.parse_string(FileAccess.get_file_as_string(path))
	viewport=SubViewport.new()
	viewport.name="ActorAtlasViewport"
	viewport.own_world_3d=true
	viewport.transparent_bg=true
	viewport.size=CELL*Vector2i(columns,1)
	viewport.msaa_3d=Viewport.MSAA_4X
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var world:=WorldEnvironment.new()
	var environment:=Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color.TRANSPARENT
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color(.5,.48,.44)
	environment.ambient_light_energy=.6
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	world.environment=environment
	viewport.add_child(world)
	for entry in [[Vector3(-45,-35,0),1.5],[Vector3(-25,135,0),.6],[Vector3(-35,180,0),.8]]:
		var light:=DirectionalLight3D.new()
		light.rotation_degrees=entry[0];light.light_energy=entry[1]
		viewport.add_child(light)
	camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	viewport.add_child(camera)
	_layout()


func available(character: String) -> bool:
	return is_instance_valid(viewport) and manifest.has(character) and ResourceLoader.exists(manifest[character].resource)


func _layout() -> void:
	columns=mini(4,maxi(1,ceili(sqrt(float(actors.size())))))
	viewport.size=CELL*Vector2i(columns,maxi(1,ceili(actors.size()/float(columns))))
	camera.size=viewport.size.y/100.0
	var pitch:=deg_to_rad(18.0)
	camera.position=Vector3(0,30*sin(pitch),30*cos(pitch))
	camera.look_at(Vector3.ZERO)
	var up:=Vector3(0,cos(pitch),-sin(pitch))
	for key: String in actors:
		var record: Dictionary=actors[key]
		var slot:=actors.keys().find(key)
		record.slot=slot
		record.texture.region=Rect2(Vector2((slot%columns)*CELL.x,(slot/columns)*CELL.y),Vector2(CELL))
		var pixel:=Vector2((slot%columns)*CELL.x,(slot/columns)*CELL.y)+PIVOT-Vector2(viewport.size)/2.0
		record.root.position=Vector3.RIGHT*pixel.x/100.0-up*pixel.y/100.0


func texture(unit: Dictionary,character: String,direction: String,action: String,profiles: Dictionary={}) -> Texture2D:
	if not available(character):return null
	var key:=str(unit.id)
	if actors.has(key) and actors[key].character!=character:
		actors[key].root.queue_free();actors.erase(key)
	if not actors.has(key):
		var model: Node3D=load(manifest[character].resource).instantiate()
		viewport.add_child(model)
		for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			# A single baked atlas per model; parts do not need empty material slots.
			mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var player: AnimationPlayer=model.find_children("*","AnimationPlayer",true,false)[0] if not model.find_children("*","AnimationPlayer",true,false).is_empty() else null
		var slot:=actors.size()
		var atlas:=AtlasTexture.new()
		atlas.atlas=viewport.get_texture()
		atlas.region=Rect2(Vector2((slot%columns)*CELL.x,(slot/columns)*CELL.y),Vector2(CELL))
		actors[key]={"root":model,"player":player,"texture":atlas,"slot":slot,"character":character,"appearance":{},"clip":""}
		_layout()
	var record: Dictionary=actors[key]
	var appearance:=resolve_appearance(unit,character,profiles)
	if record.appearance!=appearance:
		_apply_parts(record.root,appearance)
		record.appearance=appearance.duplicate(true)
	record.root.rotation.y=deg_to_rad(-float(YAW.get(direction,330)))
	var kind:=action.get_slice(":",0)
	if kind=="combat_idle":kind="pose"
	if kind=="status_reaction":kind="hit"
	var weapon:=str(appearance.weapon)
	var row: Dictionary=manifest[character]
	var map: Dictionary=row.actions.get(weapon,row.actions.get(row.default_weapon,{}))
	var name:=str(map.get(kind,map.get("pose","")))
	var player: AnimationPlayer=record.player
	if player!=null:
		for candidate: StringName in player.get_animation_list():
			if str(candidate)==name or str(candidate).ends_with("/"+name) or str(candidate).ends_with("|"+name):
				if record.clip!=str(candidate):player.play(candidate);player.pause();record.clip=str(candidate)
				var count: int={"pose":4,"walk":8,"combat":8,"hit":4,"death":8}.get(kind,4)
				var frame:=int(action.get_slice(":",1)) if action.contains(":") else 0
				var ratio:=float(posmod(frame,count))/float(count if kind in ["pose","walk"] else count-1)
				player.seek(ratio*player.get_animation(candidate).length,true)
				player.advance(0)
				break
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	return record.texture


func resolve_appearance(unit: Dictionary,character: String,profiles: Dictionary={}) -> Dictionary:
	var row: Dictionary=manifest[character]
	var result: Dictionary={"weapon":row.default_weapon,"armor":"default","boots":"default","helmet":"default","offhand":"default","hero":bool(row.hero)}
	if unit.has("appearance"):result.merge(unit.appearance,true)
	elif bool(row.hero) and unit.has("loadout"):
		result.merge({"weapon":"none","armor":"none","boots":"none","helmet":"none","offhand":"none"},true)
		for slot in ["main_hand","off_hand","armor","boots","helmet"]:
			var id: Variant=unit.loadout.get(slot)
			if id==null:continue
			var item: Dictionary=Items.item(str(id))
			var key: String={"main_hand":"weapon","off_hand":"offhand"}.get(slot,slot)
			var fallback: String={"hero_sword":"sword","salvaged_blade":"sword","hero_bow":"bow","patched_leather":"leather","salvaged_shield":"shield"}.get(str(id),"default")
			if key=="weapon" and fallback=="default":
				fallback=str(row.default_weapon)
				var granted: Array=profiles.get(str(id),{}).get("grants_actions",[])
				if granted.has("ranged_attack"):fallback="crossbow" if str(id).contains("crossbow") else "bow"
				elif granted.has("basic_attack"):fallback="sword"
			result[key]=item.get("appearance",{}).get(key,fallback)
	return result


func _apply_parts(root_node: Node3D,appearance: Dictionary) -> void:
	for mesh: MeshInstance3D in root_node.find_children("*","MeshInstance3D",true,false):
		var name:=str(mesh.name)
		var channel:=name.trim_prefix("part_")
		var visible_part:=channel=="body"
		if channel.begins_with("weapon_"):visible_part=channel=="weapon_"+str(appearance.weapon)
		elif channel.begins_with("armor_"):visible_part=channel=="armor_"+str(appearance.armor)
		elif channel.begins_with("boots_"):visible_part=channel=="boots_"+str(appearance.boots)
		elif channel=="headwear_default":visible_part=appearance.helmet in ["none","default"]
		elif channel.begins_with("helmet_"):visible_part=channel=="helmet_"+str(appearance.helmet)
		elif channel.begins_with("offhand_"):visible_part=channel=="offhand_"+str(appearance.offhand)
		elif channel=="quiver":visible_part=appearance.weapon=="bow" and appearance.offhand!="default"
		mesh.visible=visible_part


func clear() -> void:
	for record: Dictionary in actors.values():
		record.root.queue_free()
	actors.clear()
	_layout()
