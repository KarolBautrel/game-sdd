extends RefCounted
## A presentation schedule from already-resolved events; no combat decisions.
const Art := preload("res://scripts/presentation/combat/combat_unit_art.gd")

static func uses_drawn(events: Array, units: Dictionary, art: Art) -> bool:
	for event: Dictionary in events:
		if event.get("type","") not in ["hit_roll_resolved","damage_applied"]:continue
		for key in ["actor_id","target_unit_id"]:
			if art.is_drawn_unit(units.get(str(event.get(key,"")),{})):return true
	return false

static func duration(unit: Dictionary, action: String, art: Art, final_hold: bool = true) -> float:
	if unit.is_empty():return 0.0
	var character: String=art.unit_visual_config(unit).character
	var count:=art.processed_sheet_frame_count(character,action)
	var fallback:=float(count if final_hold else maxi(0,count-1))*art.frame_seconds(unit,action,0.08)
	return art.clip_seconds(unit,action,fallback,final_hold)

static func build(events: Array, units: Dictionary, art: Art) -> Dictionary:
	var groups: Dictionary={};var independent: Array=[]
	for event: Dictionary in events:
		if event.get("type","") not in ["hit_roll_resolved","damage_applied"]:continue
		var id:=str(event.get("actor_id",""))
		if id!="" and not event.has("source_status_id"):
			if not groups.has(id):groups[id]=[]
			groups[id].append(event)
		else:independent.append(event)
	# Resolver status events may omit actor_id. Attach on-hit status feedback to
	# the impact for the same victim rather than showing recoil at time zero.
	for event: Dictionary in events:
		if event.get("type","")!="status_applied":continue
		var owner:=str(event.get("actor_id",""))
		if not groups.has(owner):
			for id: String in groups:
				for related: Dictionary in groups[id]:
					if related.type=="damage_applied" and related.get("target_unit_id","")==event.get("target_unit_id",""):owner=id;break
				if groups.has(owner):break
		if groups.has(owner):groups[owner].append(event)
		else:independent.append(event)
	var actors: Array=[];var impacts: Array=[];var finish:=0.0
	for id: String in groups:
		var unit: Dictionary=units.get(id,{})
		var attacks:=false
		for event: Dictionary in groups[id]:
			if event.type in ["hit_roll_resolved","damage_applied"]:attacks=true
		var at:=art.impact_seconds(unit,0.28) if attacks else 0.0
		if attacks:
			actors.append({"id":id,"action":"combat"})
			finish=maxf(finish,duration(unit,"combat",art))
		impacts.append({"at":at,"events":groups[id]})
	if not independent.is_empty():impacts.append({"at":0.0,"events":independent})
	for impact: Dictionary in impacts:
		var reactions: Dictionary={}
		for event: Dictionary in impact.events:
			var target:=str(event.get("target_unit_id",""))
			if target=="":continue
			if event.type=="damage_applied":
				reactions[target]="death" if int(event.get("hp_after",1))<=0 else "hit"
			elif event.type=="status_applied" and not reactions.has(target):reactions[target]="status_reaction"
		impact.reactions=reactions
		for id: String in reactions:
			var death: bool=reactions[id]=="death"
			finish=maxf(finish,float(impact.at)+duration(units.get(id,{}),reactions[id],art,not death)+(0.45 if death else 0.0))
	impacts.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:return float(a.at)<float(b.at))
	return {"actors":actors,"impacts":impacts,"duration":finish}
