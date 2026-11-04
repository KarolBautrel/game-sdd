"""Authoring safety for the bounded stage70 arena pilots."""
import copy
import json
import unittest
from collections import deque

from tools.qa.build_painted_arenas import ARENAS, PILOT, ROOT, derived


class PaintedArenaTests(unittest.TestCase):
    def test_canonical_exports_and_actor_preservation(self):
        pilot = json.loads(PILOT.read_text(encoding="utf-8"))
        for arena_id in ARENAS:
            with self.subTest(arena=arena_id):
                mapped, encounter = derived(arena_id)
                for folder, expected in (("maps", mapped), ("combat_encounters", encounter)):
                    actual = json.loads((ROOT / f"resources/data/{folder}/{arena_id}.json").read_text(encoding="utf-8"))
                    self.assertEqual(actual, expected, "canonical TMX/export drift")
                original = copy.deepcopy(pilot)
                for data in (original, encounter):
                    for key in ("id", "seed", "grid", "map_path", "background_path", "terrain_theme", "terrain_decorations"):
                        data.pop(key, None)
                    for unit in data["units"]:
                        unit.pop("position")
                self.assertEqual(encounter, original, "arena must not alter accepted kits/stats/art")

    def test_connected_lanes_safe_spawns_and_alternate_crossings(self):
        for arena_id in ARENAS:
            with self.subTest(arena=arena_id):
                mapped, encounter = derived(arena_id)
                walkable = {(t["x"], t["y"]) for t in mapped["tiles"] if t["type"] != "blocked"}
                seen = set()
                queue = deque([next(iter(walkable))])
                while queue:
                    cell = queue.popleft()
                    if cell in seen:
                        continue
                    seen.add(cell)
                    x, y = cell
                    queue.extend(n for n in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)) if n in walkable and n not in seen)
                self.assertEqual(seen, walkable, "no isolated pocket or unreachable target")
                starts = {(u["position"]["x"], u["position"]["y"]) for u in encounter["units"]}
                self.assertEqual(len(starts), 7)
                self.assertTrue(starts <= walkable)
                self.assertTrue({(2,7), (3,7)} <= walkable, "safe native movement probe")
                allies = [u for u in encounter["units"] if u["team"] == "player"]
                enemies = [u for u in encounter["units"] if u["team"] == "enemy"]
                self.assertTrue(all(abs(a["position"]["x"]-e["position"]["x"])+abs(a["position"]["y"]-e["position"]["y"]) > 1 for a in allies for e in enemies))
                types = {t["type"] for t in mapped["tiles"]}
                self.assertTrue({"floor", "blocked", "cover_low", "highground"} <= types)
                if arena_id == "painted_mine_breach":
                    self.assertTrue({(6,3),(6,6),(6,7)} <= walkable)
                    self.assertNotIn((6,5), walkable)
                else:
                    self.assertTrue(all((x,1) in walkable for x in range(14)))
                    self.assertTrue(all((x,10) in walkable for x in range(14)))

    def test_catalogue_retains_default_and_unique_review_entries(self):
        rows = json.loads((ROOT / "resources/data/combat_scenarios/catalogue.json").read_text(encoding="utf-8"))["scenarios"]
        self.assertEqual(rows[0]["id"], "full_combat_showcase")
        self.assertEqual(len(rows), len({r["id"] for r in rows}))
        for arena_id in ARENAS:
            row = next(r for r in rows if r["id"] == arena_id)
            self.assertTrue((ROOT / row["path"].removeprefix("res://")).is_file())


if __name__ == "__main__":
    unittest.main()
