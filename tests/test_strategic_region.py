import copy
import json
from pathlib import Path
import unittest
from tools.validators.strategic_region import reference_errors, rules_errors

ROOT=Path(__file__).resolve().parents[1]


class StrategicRegion(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.reference=json.loads((ROOT/'resources/data/strategic_regions/reference_2087.json').read_text())

    def setUp(self):
        self.s=copy.deepcopy(self.reference)

    def test_runtime_export_and_rules(self):
        self.assertEqual(reference_errors(self.s),[])
        self.assertEqual(rules_errors(self.s['region_rules']),[])
        self.assertEqual(len(self.s['region']['sites']),9)

    def test_shape_and_mode_rejections(self):
        for field,value in (('version',4),('version',True),('request_seq',1.5),('company',{}),('extra',1)):
            with self.subTest(field=field):
                s=copy.deepcopy(self.s);s[field]=value
                self.assertTrue(reference_errors(s))

    def test_reward_funding_and_cause(self):
        job=next(iter(self.s['jobs'].values()))
        job['gold']+=1;job['cause']['tick']=1
        errors=reference_errors(self.s)
        self.assertIn('job lacks its funded immutable reward',errors)
        self.assertIn('job cause/window mismatch',errors)

    def test_physical_binding_and_clock(self):
        self.s['strategy_world']['core']['settlements']['ashmere']['x']+=.01
        self.s['company']['world']['elapsed_hours']=2
        errors=reference_errors(self.s)
        self.assertIn('core settlement differs from physical binding',errors)
        self.assertIn('regional company/world clock mismatch',errors)

    def test_conversion_and_mine_cannot_be_faked(self):
        self.s['region_rules']['delivery']['world_food']=99
        self.s['mine']['status']='restored'
        errors=reference_errors(self.s)
        self.assertIn('regional food conversion differs',errors)
        self.assertIn('mine status/production mismatch',errors)

    def test_unknown_issuer_and_receipt(self):
        job=next(iter(self.s['jobs'].values()));job['issuer']='missing'
        self.s['request_seq']=1
        errors=reference_errors(self.s)
        self.assertIn('unknown job issuer/target',errors)
        self.assertIn('regional receipt tail length mismatch',errors)
