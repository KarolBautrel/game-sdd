import copy
import json
import math
from pathlib import Path
import unittest
from jsonschema import Draft202012Validator
from tools.validators.strategic_region import reference_errors
from tools.validators.strategist import reference_errors as model_errors
ROOT=Path(__file__).resolve().parents[1]
def load(path): return json.loads((ROOT/path).read_text())
class VastRegions(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.geo=load('resources/data/vast_regions/marches_2087.json')
        cls.s=load('resources/data/strategic_regions/vast_2087.json')
        cls.schema=load('resources/schemas/generated_region.schema.json')
    def test_exported_geometry_and_campaigns(self):
        self.assertEqual(list(Draft202012Validator(self.schema).iter_errors(self.geo)),[])
        self.assertEqual(reference_errors(self.s),[])
        self.assertEqual(model_errors(load('resources/data/strategist_campaigns/vast_2087.json')),[])
    def test_four_times_large_area(self):
        self.assertEqual(self.geo['terrain']['width']*self.geo['terrain']['height'],384*216*4)
        self.assertEqual(len(self.geo['terrain']['rows']),432)
        self.assertEqual(len(self.geo['climates']),3)
    def test_size_cannot_be_relabelled(self):
        geo=copy.deepcopy(self.geo);geo['version']=2
        self.assertTrue(list(Draft202012Validator(self.schema).iter_errors(geo)))
        geo=copy.deepcopy(self.geo);geo['terrain']['width']=384
        self.assertTrue(list(Draft202012Validator(self.schema).iter_errors(geo)))
    def test_measured_route_cost_uses_physical_scale(self):
        for route in self.s['region']['routes'].values(): self.assertEqual(route['ticks'],math.ceil(route['cost']/.0035))
        s=copy.deepcopy(self.s);edge=next(iter(s['region']['routes'].values()));edge['ticks']=math.ceil(edge['cost']/.007)
        self.assertIn('physical route cost/ticks differ',reference_errors(s))
    def test_old_references_still_validate(self):
        for folder in ['generated_regions','large_regions']:
            for p in (ROOT/'resources/data'/folder).glob('*.json'):
                self.assertEqual(list(Draft202012Validator(self.schema).iter_errors(json.loads(p.read_text()))),[])
    def test_wrong_vast_diagnostics_fail(self):
        geo=copy.deepcopy(self.geo);geo['diagnostics']['land_cells']=768*432+1
        self.assertTrue(list(Draft202012Validator(self.schema).iter_errors(geo)))
if __name__=='__main__':unittest.main()
