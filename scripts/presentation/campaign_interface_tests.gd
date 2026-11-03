extends SceneTree
var errors: Array[String] = []
var checks := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: errors.append(message)

func frames() -> void:
	for frame in range(8): await process_frame

func _run() -> void:
	var campaign := root.get_node("CampaignSession")
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]:
		campaign.load_profile("",true)
		campaign.state.xp = 100
		for index in range(30): campaign.state.items.append("legacy_keepsake_%s_with_a_long_name_retained_from_an_earlier_journey" % index)
		var original: Dictionary = campaign.state.duplicate(true)
		var viewport := SubViewport.new()
		viewport.size = dimensions
		viewport.disable_3d = true
		root.add_child(viewport)
		var app: Control = load("res://scenes/app/App.tscn").instantiate()
		viewport.add_child(app)
		await frames()
		for tab in ["region","town","stash","trade","training"]:
			app.shell.nav_buttons[tab].pressed.emit()
			await frames()
			var shell: Control = app.shell
			var body: Rect2 = shell.body_scroll.get_global_rect()
			var footer: Rect2 = shell.footer.get_global_rect()
			check(shell.size == Vector2(dimensions),"shell fills %s %s" % [dimensions,tab])
			check(body.size.x > 400 and body.size.y > 180,"useful body %s %s" % [dimensions,tab])
			check(footer.position.y >= body.end.y-1 and footer.end.y <= dimensions.y+1,"fixed footer below body %s %s body=%s footer=%s" % [dimensions,tab,body,footer])
			check(shell.rail_scroll.visible == (dimensions.x >= 1500 and tab == "region") and shell.compact_summary.visible == (dimensions.x < 1500 and tab == "region"),"responsive party rail")
			check(shell.feedback.text == campaign.last_feedback,"persistent feedback")
			for id: String in shell.nav_buttons:
				var rect: Rect2 = shell.nav_buttons[id].get_global_rect()
				check(rect.position.x >= 0 and rect.end.x <= dimensions.x and rect.end.y <= footer.position.y,"navigation remains visible")
				check(shell.nav_buttons[id].focus_mode == Control.FOCUS_ALL and shell.nav_buttons[id].get_theme_stylebox("focus").get_border_width(SIDE_LEFT) == 2,"keyboard focus has explicit outline")
			for control: Node in shell.content.find_children("*","Control",true,false):
				if not control.is_visible_in_tree(): continue
				var rect: Rect2 = control.get_global_rect()
				check(rect.position.x >= body.position.x-1 and rect.end.x <= body.end.x+1,"body horizontal bounds %s %s: %s" % [dimensions,tab,control.name])
			check(campaign.state == original,"navigation/read-only no profile mutation")
			if tab == "training":
				for label: Label in shell.content.find_children("*","Label",true,false):
					if label.text in ["Strength","Defense","Accuracy"]:
						check(label.size.x >= label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x,"training stat word readable without letter-column wrapping")
			if tab == "stash":
				var inventory := app.find_child("InventoryView",true,false)
				check(shell.content.size.y <= body.size.y or shell.body_scroll.get_v_scroll_bar().max_value > body.size.y,"body fits or scrolls overflow vertically")
				check(inventory.entries_scroll.get_v_scroll_bar().max_value > inventory.entries_scroll.size.y,"inventory scroll is independent of equipment")
				for tile: Button in inventory.grid.item_buttons.values():
					var bounds: Rect2 = tile.get_global_rect().grow(1)
					for child: Control in tile.find_children("*","Control",true,false):
						check(bounds.encloses(child.get_global_rect()),"tile icon/name/quantity fits its hit rectangle")
						if child is Label and not child.text.is_empty():
							check(child.size.y >= child.get_theme_font("font").get_height(child.get_theme_font_size("font_size"))-1,"tile names/quantities have a readable line height")
				if dimensions.x >= 1920:
					var gear := app.find_child("EquipmentView",true,false)
					check(gear.equip_button.get_global_rect().end.y <= body.end.y,"primary equipment controls visible before scrolling")
			if dimensions.x == 1920: _snapshot(shell,"res://artifacts/qa-runs/campaign-current-layout-%s.json" % tab)
		app.queue_free()
		viewport.queue_free()
		await frames()
	for error in errors: push_error(error)
	print("campaign_interface_tests: ",checks," checks, ",errors.size()," failures")
	quit(0 if errors.is_empty() else 1)

func _snapshot(shell: Control,path: String) -> void:
	# Geometry/style record for an explicitly labelled offline design reconstruction.
	var nodes: Array = []
	var descendants: Array[Node] = [shell]
	descendants.append_array(shell.find_children("*","Control",true,false))
	for node: Node in descendants:
		if not node.is_visible_in_tree(): continue
		var rect: Rect2 = node.get_global_rect()
		var row := {"type":node.get_class(),"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]}
		var clip := Rect2(Vector2.ZERO,shell.size)
		var parent := node.get_parent()
		while parent != null:
			if parent is ScrollContainer: clip = clip.intersection(parent.get_global_rect())
			parent = parent.get_parent()
		row.clip = [clip.position.x,clip.position.y,clip.size.x,clip.size.y]
		if node is ColorRect: row.fill = node.color.to_html()
		if node is PanelContainer or node is Button:
			var style: StyleBox = node.get_theme_stylebox("panel" if node is PanelContainer else ("disabled" if node.disabled else "normal"))
			if style is StyleBoxFlat:
				row.fill = style.bg_color.to_html()
				row.border = style.border_color.to_html()
			elif style is StyleBoxTexture and style.texture != null:
				row.frame = {"texture":style.texture.resource_path,"margins":[style.texture_margin_left,style.texture_margin_top,style.texture_margin_right,style.texture_margin_bottom]}
		if node is Label or node is Button:
			row.text = node.text
			row.font_size = node.get_theme_font_size("font_size")
			row.serif = node is Label and row.font_size >= 26
			row.color = node.get_theme_color("font_color").to_html()
		if node is TextureRect and node.texture != null: row.texture = node.texture.resource_path
		if node.get_script() != null and node.get_script().resource_path.ends_with("region_map.gd"):
			row.map = node.region.duplicate(true)
			row.location = node.location
			row.points = {}
			for entry: Dictionary in node.region.nodes:
				var point: Vector2 = node._point(entry.id)
				row.points[entry.id] = [point.x+rect.position.x,point.y+rect.position.y]
		nodes.append(row)
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"kind":"headless geometry; not native screenshot","size":[shell.size.x,shell.size.y],"nodes":nodes},"  "))
	file.close()
