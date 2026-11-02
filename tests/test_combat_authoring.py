import copy
import json
import unittest

from tools.validators.combat_authoring import ROOT, CATALOGUE, catalogue_errors, encounter_errors


class CombatAuthoringTests(unittest.TestCase):
    def setUp(self):
        self.catalogue = json.loads((ROOT / CATALOGUE).read_text())
        self.encounter = json.loads((ROOT / 'resources/data/combat_encounters/clearing_crossfire.json').read_text())

    def test_valid_catalogue_and_reference(self):
        self.assertEqual(catalogue_errors(), [])
        self.assertEqual(encounter_errors(self.encounter), [])
        self.assertEqual(len(self.catalogue['scenarios']), 12)
        self.assertIn('ash_road_raiders', {row['id'] for row in self.catalogue['scenarios']})

    def test_duplicate_and_invalid_catalogue(self):
        self.catalogue['scenarios'].append(copy.deepcopy(self.catalogue['scenarios'][0]))
        self.assertTrue(any('Duplicate' in error for error in catalogue_errors(self.catalogue)))
        self.assertTrue(catalogue_errors({'schema':'bad','scenarios':[]}))
        self.assertTrue(catalogue_errors({'schema':'sdd.combat-scenarios-v1','scenarios':[{}]}))

    def test_missing_or_escaping_path(self):
        for path in ['res://resources/data/combat_encounters/missing_test.json','res://../outside.json']:
            with self.subTest(path=path):
                self.catalogue['scenarios'][0]['path'] = path
                self.assertTrue(catalogue_errors(self.catalogue))

    def test_missing_map(self):
        self.encounter['map_path'] = 'res://resources/data/maps/missing_test.json'
        self.assertTrue(encounter_errors(self.encounter))

    def test_invalid_or_overlapping_start(self):
        for position in [{'x':1,'y':2}, {'x':-1,'y':0}, self.encounter['units'][1]['position']]:
            with self.subTest(position=position):
                changed = copy.deepcopy(self.encounter)
                changed['units'][0]['position'] = position
                self.assertTrue(encounter_errors(changed))

    def test_unknown_archetype_item_and_weapon(self):
        for field, value in [('archetype_id','missing_test'), ('loadout',{'main_hand':'missing_test'}), ('equipped_weapon_id','missing_test')]:
            with self.subTest(field=field):
                changed = copy.deepcopy(self.encounter)
                changed['units'][0][field] = value
                self.assertTrue(encounter_errors(changed))

    def test_bad_turn_references_and_duplicate_ids(self):
        self.encounter['turn_state']['active_unit_id'] = 'missing_test'
        self.assertTrue(encounter_errors(self.encounter))
        self.encounter['units'][1]['id'] = self.encounter['units'][0]['id']
        self.assertTrue(encounter_errors(self.encounter))

    def test_missing_visual(self):
        self.encounter['background_path'] = 'res://assets/combat/terrain/backgrounds/missing_test.png'
        self.assertTrue(encounter_errors(self.encounter))
