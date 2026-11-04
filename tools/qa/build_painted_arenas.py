"""Export two canonical TMX arenas and encounters; --check never writes files."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tools.maps.tiled_to_map_json import convert_tmx

ARENAS = {
    "painted_forest_ambush": {"label": "Painted arenas - Forest Ambush", "seed": 2070},
    "painted_mine_breach": {"label": "Painted arenas - Mine Breach", "seed": 2071},
}
PILOT = ROOT / "resources/data/combat_encounters/painted_enemy_pilot.json"


def derived(arena_id: str) -> tuple[dict, dict]:
    mapped = convert_tmx(ROOT / f"resources/tiled/maps/{arena_id}.tmx")
    encounter = json.loads(PILOT.read_text(encoding="utf-8"))
    encounter["id"] = arena_id
    encounter["seed"] = ARENAS[arena_id]["seed"]
    for key in ("grid", "background_path", "terrain_theme", "terrain_decorations"):
        encounter.pop(key, None)
    encounter["map_path"] = f"res://resources/data/maps/{arena_id}.json"
    spawns = {row["id"]: row for row in mapped["test_spawns"]}
    if set(spawns) != {unit["id"] for unit in encounter["units"]}:
        raise ValueError(f"{arena_id}: spawn ids must match the approved pilot actors")
    for unit in encounter["units"]:
        row = spawns[unit["id"]]
        unit["position"] = {"x": row["x"], "y": row["y"]}
    return mapped, encounter


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--export", action="store_true", help="write derived JSON; never rewrite TMX")
    parser.add_argument("--check", action="store_true", help="compare only (default)")
    args = parser.parse_args()
    if args.export and args.check:
        parser.error("choose --export or --check")
    failures = []
    for arena_id in ARENAS:
        mapped, encounter = derived(arena_id)
        for folder, data in (("maps", mapped), ("combat_encounters", encounter)):
            path = ROOT / f"resources/data/{folder}/{arena_id}.json"
            if args.export:
                path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
            elif not path.exists() or json.loads(path.read_text(encoding="utf-8")) != data:
                failures.append(str(path.relative_to(ROOT)))
    if failures:
        print("Arena export drift: " + ", ".join(failures))
        return 1
    print("Painted arenas: canonical exports " + ("written" if args.export else "match"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
