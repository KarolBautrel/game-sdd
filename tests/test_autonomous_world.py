import copy
import json
from pathlib import Path
import unittest
from tools.validators.autonomous_world import reference_errors
from tools.validators.validate_all import _combat_encounter_background

ROOT = Path(__file__).resolve().parents[1]

class AutonomousWorld(unittest.TestCase):
    def setUp(self):
        self.s = json.loads((ROOT/'resources/data/autonomous_campaigns/marches_2087.json').read_text())

    def test_opening_and_independent_ledger(self):
        self.assertEqual(reference_errors(self.s), [])
        self.assertEqual(len(self.s['life']['sites']), 2)
        self.assertEqual(self.s['mine']['status'], 'occupied')

    def test_invalid_versions_shapes_and_free_means(self):
        for mutate in (
            lambda s: s.update(version=4),
            lambda s: s['life']['actors']['grey_lances'].update(strength=27),
            lambda s: s['life']['actors']['grey_lances'].update(wallet=100),
            lambda s: s['life']['politics']['outposts']['river_watch'].update(garrison=11),
            lambda s: s['life']['regions']['reserve'].update(bandits=12),
            lambda s: s['life']['sites']['road_camp'].update(episode='missing'),
        ):
            with self.subTest(mutation=mutate):
                s = copy.deepcopy(self.s); mutate(s)
                self.assertTrue(reference_errors(s))

    def test_mapped_encounter_has_its_actual_background(self):
        e = json.loads((ROOT/'resources/data/combat_encounters/painted_forest_ambush.json').read_text())
        self.assertTrue(_combat_encounter_background(e).endswith('deep_green.png'))
        self.assertEqual(_combat_encounter_background({'map_path':'res://missing.json'}), '')
        self.assertEqual(_combat_encounter_background({}), '')
