@tool
extends EditorPlugin
func _enter_tree() -> void:
	if "--build-campaign-theme" in OS.get_cmdline_user_args(): _export_campaign_theme.call_deferred()
func _export_campaign_theme() -> void:
	while EditorInterface.get_resource_filesystem().is_scanning(): await get_tree().process_frame
	var generator := preload("res://tools/ui/campaign_theme.gd").new()
	generator._run()
	generator = null
	print("ThemeGen campaign theme exported through editor plugin")
	for frame in range(5): await get_tree().process_frame
	get_tree().quit()
