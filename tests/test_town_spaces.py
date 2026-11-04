import copy
import unittest
from pathlib import Path
from tools.validators.town_spaces import errors

ROOT=Path(__file__).resolve().parents[1]


class TownSpaceTests(unittest.TestCase):
    def fixture(self):
        import json
        return json.loads((ROOT/'resources/data/town_spaces/ravenford_courtyard.json').read_text())

    def test_valid_connected_space(self):
        self.assertEqual(errors(ROOT),[])

    def test_bad_map_spawn_and_profile(self):
        for field,value in [('spawn_id','missing'),('profile','painted_wolf')]:
            data=self.fixture();data['npcs'][0][field]=value
            self.assertTrue(errors(ROOT,data))
        data=self.fixture();data['map_path']='res://resources/data/maps/missing.json'
        self.assertTrue(errors(ROOT,data))

    def test_duplicate_or_overlapping_roles(self):
        data=self.fixture();data['npcs'].append(copy.deepcopy(data['npcs'][0]))
        self.assertTrue(errors(ROOT,data))
        data=self.fixture();data['npcs'][0]['spawn_id']=data['entry_spawn']
        self.assertTrue(errors(ROOT,data))


if __name__=='__main__':unittest.main()
