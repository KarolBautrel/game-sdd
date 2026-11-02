import copy
import json
import unittest
from tools.validators.validate_all import ROOT, validate_party_levels

class PartyLevelsTests(unittest.TestCase):
    def setUp(self):
        self.data = json.loads((ROOT/'resources/data/progression/party_levels.json').read_text())
    def test_canonical(self):
        self.assertEqual(validate_party_levels(self.data), [])
    def test_duplicate_level(self):
        self.data['levels'][2]['level'] = 2
        self.assertTrue(validate_party_levels(self.data))
    def test_hp_bonus_forbidden(self):
        self.data['levels'][1]['bonuses']['max_hp'] = 1
        self.assertTrue(validate_party_levels(self.data))
    def test_invalid_cost(self):
        for value in [0,-1,True,1.5]:
            data=copy.deepcopy(self.data);data['levels'][1]['cost']=value
            self.assertTrue(validate_party_levels(data))
    def test_loss_of_bonus_or_changed_baseline(self):
        self.data['levels'][2]['bonuses']['strength']=0
        self.assertTrue(validate_party_levels(self.data))
        self.data['levels'][0]['bonuses']['strength']=1
        self.assertTrue(validate_party_levels(self.data))
