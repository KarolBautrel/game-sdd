extends RefCounted
## Source-verified complete profiles. Pending source previews never replace a unit.
const PATH := "res://resources/data/presentation/drawn_roster.json"
const ACTIONS := ["neutral_idle","combat_idle","neutral_walk","combat_walk","attack","hit","death"]
const KNIGHT_EXTRAS := ["draw","sheathe","attack_alt","block","dodge"]
const DIRECTIONS := ["south","south_west","west","north_west","north","north_east","east","south_east"]

static func visual_configs() -> Dictionary:
	if not FileAccess.file_exists(PATH):return {}
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not data is Dictionary or data.get("schema","")!="sdd.drawn-roster-v1":return {}
	var result: Dictionary={}
	for p: Dictionary in data.get("profiles",[]):
		if not p.get("enabled",false) or not p.get("source_roundtrip",false):continue
		var valid: bool=p.get("facings",[])==DIRECTIONS
		for action: String in ACTIONS:
			valid=valid and int(p.get("frame_counts",{}).get(action,0))>0
		for action: String in p.get("frame_counts",{}):
			valid=valid and p.get("durations_ms",{}).get(action,[]).size()==int(p.get("frame_counts",{}).get(action,0))
		if not valid:
			push_error("Incomplete drawn animation profile: "+str(p.get("id","")))
			continue
		result[p.id]={"root":p.root,"prefix":p.id,"directions":true,"drawn":true,
			"canvas_size":Vector2i(p.canvas[0],p.canvas[1]),"pivot":Vector2i(p.pivot[0],p.pivot[1]),
			"final_death_frame":true,"frame_counts":p.frame_counts,"durations_ms":p.durations_ms,
			"impact_frame":p.impact_frame,"walk_stride_pixels":p.walk_stride_pixels,
			"frames":{},"frame_seconds":{},"view_sources":p.view_sources}
		var aliases: Dictionary={"pose":"neutral_idle","combat_idle":"combat_idle","walk":"neutral_walk","combat_walk":"combat_walk","combat":"attack","hit":"hit","status_reaction":"hit","death":"death"}
		for alias: String in aliases:result[p.id].frame_seconds[alias]=float(p.durations_ms[aliases[alias]][0])/1000.0
	return result
