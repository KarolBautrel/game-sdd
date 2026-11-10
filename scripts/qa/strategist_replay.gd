extends SceneTree
## Offline checkpoint/tail verification. Does not instantiate a transport/session.
const M := preload("res://scripts/domain/strategist_campaign.gd")
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var path: String=args[0] if args.size()==1 else "res://resources/data/strategist_replays/mine_region_2087.json"
	var allowed := RegEx.create_from_string("^res://resources/data/strategist_replays/[a-z0-9_]+[.]json$")
	if args.size()>1 or allowed.search(path)==null or not FileAccess.file_exists(path): fail("Unknown local replay case.");return
	var manifest: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not M.W._shape(manifest,["schema","version","checkpoint","commands","expected_digest"]) or not manifest.checkpoint is String or not manifest.commands is Array: fail("Invalid replay manifest.");return
	allowed=RegEx.create_from_string("^res://resources/data/strategist_campaigns/[a-z0-9_]+[.]json$")
	if allowed.search(manifest.checkpoint)==null or not FileAccess.file_exists(manifest.checkpoint): fail("Unknown local checkpoint.");return
	var checkpoint: Variant=JSON.parse_string(FileAccess.get_file_as_string(manifest.checkpoint))
	if not checkpoint is Dictionary: fail("Invalid checkpoint.");return
	var result := M.replay(checkpoint,manifest.commands)
	var ok: bool=result.ok and M.A.P.digest(result.state)==manifest.expected_digest
	var directory := "res://artifacts/qa-runs/strategist-replay"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file := FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file==null: fail("Cannot write owned replay receipt.");return
	file.store_string(JSON.stringify({"ok":ok,"processed":result.processed,"digest":M.A.P.digest(result.state),"transport":"NOT_INSTANTIATED"},"\t",true,true)+"\n");file.close()
	print("strategist_replay: ",ok," / ",result.processed," commands / no transport");quit(0 if ok else 1)
func fail(reason: String) -> void:
	push_error(reason);quit(1)
