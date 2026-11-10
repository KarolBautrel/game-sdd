extends RefCounted
const F := preload("res://scripts/domain/life_campaign.gd")
const UI := preload("res://scripts/presentation/world/campaign_skin.gd")
var view: Control
var root: VBoxContainer
var reports: Label
var activity: Label
var rows: Dictionary={}
func build(host: Control, parent: VBoxContainer) -> void:
	view=host;root=parent
	view._label(root,"A world with its own plans",26,UI.GOLD)
	view._label(root,"Situations continue while you travel or explore. Inspecting the map is free; waiting spends ordinary campaign time.",19,UI.MUTED)
	view._button(root,"life_wait","Wait one day / normal upkeep",func(): view.set_speed(0);view._act("advance",{"ticks":96}))
	for id: String in F.L.Regions.DISTRICTS:
		view._button(root,"district_"+id,"Show "+F.L.Regions.DISTRICTS[id],func():
			var x: float={"riverlands":1.0/6,"marches":.5,"highlands":5.0/6}[id]
			view.map.camera.focus(Vector2(x,.5),view.map.size);view.map._layout())
	reports=view._label(root,"",19,UI.MUTED)
	activity=view._label(root,"",19)
func refresh(s: Dictionary) -> void:
	var lines: Array[String]=[]
	for id: String in F.L.Regions.DISTRICTS:
		var report: Dictionary=s.life.regions.bulletins.get(id,{})
		lines.append(F.L.Regions.DISTRICTS[id])
		if report.is_empty(): lines.append("No messenger report received. Visit a town after the next day.")
		else:
			lines.append("%s / %s\nKnown occupied sites: %d/%d" % [view.clock(int(report.tick)),report.source,report.threats,report.sites])
			for control: String in report.control: lines.append(control)
	reports.text="\n".join(lines)
	lines=[]
	if not s.life.politics.dispute.is_empty(): lines.append("High Pass / "+s.life.politics.dispute.status.capitalize()+"\n"+s.life.politics.dispute.reason)
	for a: Dictionary in s.life.actors.values(): lines.append(a.name+" / "+a.status.capitalize())
	for post: Dictionary in s.life.politics.outposts.values(): lines.append(post.name+" / "+s.strategy_world.core.factions[post.owner].name+(" / recovering" if post.cooldown>s.strategy_world.core.tick else ""))
	activity.text="\n".join(lines)
	view.buttons.life_wait.disabled=not s.company.active_run.is_empty()
	for id: String in F.R.C.S.sorted_ids(s.life.episodes):
		var e: Dictionary=s.life.episodes[id]
		if not rows.has(id):
			var panel := PanelContainer.new();panel.add_theme_stylebox_override("panel",UI.box(UI.RAISED,UI.EDGE,14));root.add_child(panel)
			var box := VBoxContainer.new();box.add_theme_constant_override("separation",8);panel.add_child(box)
			var title: Label=view._label(box,"",23,UI.GOLD)
			var body: Label=view._label(box,"",19)
			var inspect: Button=view._button(box,"inspect_"+id,"Inspect on map",func(): view.select_life_site(s.life.episodes[id].site))
			var accept: Button=view._button(box,"accept_"+id,"Accept / 5 days exclusive",func(): view.set_speed(0);view._act("accept_life",{"id":id}))
			var report: Button=view._button(box,"report_"+id,"Report / 24g + 8XP",func(): view.set_speed(0);view._act("report_life",{"id":id}))
			rows[id]={"panel":panel,"title":title,"body":body,"inspect":inspect,"accept":accept,"report":report}
		var row: Dictionary=rows[id];var c: Dictionary=e.contract;var site: Dictionary=s.life.sites[e.site]
		row.title.text=site.name+" / "+e.phase.capitalize()
		var text: String=view.clock(int(e.created_tick))+"\n"+e.cause
		if not c.is_empty():
			text+="\nPatron: "+s.strategy_world.core.factions[c.issuer].name+" / "+s.region.sites[c.town].name+"\n24g + 8XP / "+str(c.status).capitalize()
			if c.status=="company": text+="\nExclusive until "+view.clock(int(c.deadline))+". Active expedition protects the claim."
			if c.status=="objective": text+="\nCompleted work remains payable. Return to the issuer."
		if e.resolved_tick!=null: text+="\nResolved by "+str(e.result)+" / "+view.clock(int(e.resolved_tick))
		row.body.text=text
		row.accept.disabled=F.contract_reason(s,id)!="";row.accept.tooltip_text=F.contract_reason(s,id)
		row.report.disabled=F.contract_reason(s,id,true)!="";row.report.tooltip_text=F.contract_reason(s,id,true)
