extends RefCounted
## Explicit format discrimination. No reads, writes or implicit conversion.
const STRATEGY_SCHEMA := "sdd.strategy-campaign"
const STRATEGY_PREFIX := "user://qa_strategy_world_"
static var strategy_filename := RegEx.create_from_string("^user://qa_strategy_world_[A-Za-z0-9_-]+[.]json$")

static func is_strategy_path(path: String) -> bool:
	return strategy_filename.search(path) != null

static func classify(value: Variant) -> String:
	if not value is Dictionary: return "unknown"
	if value.get("schema") == STRATEGY_SCHEMA: return "strategy"
	var version: Variant = value.get("version")
	# JSON produces integral floats; bools/fractions still are not versions.
	if (version is int or version is float) and is_finite(float(version)) and version >= 1 and version <= 4 and float(version) == floor(float(version)) and value.has("gold"): return "legacy"
	return "unknown"
