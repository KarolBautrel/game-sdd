extends SceneTree
## Structural/native-animation checks. Pixel evidence belongs to the GPU fixture.
const Atlas := preload("res://scripts/presentation/combat/modular_actor_atlas.gd")
var checks:=0
var failures: Array[String]=[]

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)

func _run() -> void:
	var atlas:=Atlas.new();root.add_child(atlas)
	var roster: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/data/presentation/original_roster.json"))
	check(atlas.resolve_appearance({"loadout":{"main_hand":"iron_sword"}},"warrior").weapon=="sword","legacy encounter-local sword retains a visible main hand")
	check(atlas.resolve_appearance({"loadout":{"main_hand":"hunting_bow"}},"warrior",{"hunting_bow":{"grants_actions":["ranged_attack"]}}).weapon=="bow","trusted encounter-local bow selects bow without swapping hero body")
	for profile: Dictionary in roster.characters:
		var id:=str(profile.id)
		check(atlas.available(id),"modular resource "+id)
		var unit: Dictionary={"id":"test","visual":{"character":id}}
		for direction: String in roster.camera.yaw:
			for kind: String in roster.frame_counts:
				for frame in [0,int(roster.frame_counts[kind])-1]:
					var texture: Texture2D=atlas.texture(unit,id,direction,"%s:%s" % [kind,frame])
					check(texture!=null and texture.get_size()==Vector2(640,448),id+direction+kind+str(frame)+" atlas cell")
					check(not str(atlas.actors.test.clip).is_empty(),id+kind+" animation resolves")
		atlas.clear();await process_frame
	for id: String in ["warrior","archer_1"]:
		for weapon: String in ["sword","bow","spear","crossbow","axe","mace","dagger","cleaver","none"]:
			var unit: Dictionary={"id":"gear","appearance":{"weapon":weapon,"armor":"plate","boots":"steel","helmet":"closed","offhand":"none"}}
			atlas.texture(unit,id,"east","pose:0")
			var shown: Array[String]=[]
			for mesh: MeshInstance3D in atlas.actors.gear.root.find_children("*","MeshInstance3D",true,false):
				if mesh.visible:shown.append(str(mesh.name))
			check(shown.has("part_body") and shown.has("part_armor_plate") and shown.has("part_boots_steel") and shown.has("part_helmet_closed"),id+weapon+" independent clothing channels")
			check(shown.has("part_weapon_"+weapon) if weapon!="none" else not shown.any(func(name: String)->bool:return name.begins_with("part_weapon_")),id+weapon+" exclusive weapon")
			check(not shown.has("part_headwear_default") and not shown.has("part_armor_default"),id+" helmet and armour replacement")
		atlas.clear();await process_frame
	atlas.queue_free();await process_frame
	for failure in failures:push_error(failure)
	print("Modular actors: %s checks, %s failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
