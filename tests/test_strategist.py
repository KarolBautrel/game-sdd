import copy
import json
from pathlib import Path
import unittest
from tools.validators.strategist import reference_errors,request_errors,reply_errors,replay_errors,shape,digest
ROOT=Path(__file__).resolve().parents[1]
def load(path): return json.loads((ROOT/path).read_text())
class Strategist(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.s=load('resources/data/strategist_campaigns/reference_2087.json')
        cls.q=load('resources/data/strategist_requests/cinder_2087.json')
        cls.p=load('resources/data/strategist_replies/cinder_2087.json')
    def test_runtime_exports(self):
        self.assertEqual(reference_errors(self.s),[])
        self.assertEqual(request_errors(self.q),[])
        self.assertEqual(reply_errors(self.q,self.p),[])
        self.assertEqual(shape('rules',load('resources/data/strategists/rules_v1.json')),[])
        self.assertEqual(shape('examples',load('resources/data/strategists/recorded_examples_v1.json')),[])
    def test_request_identity_hash_and_privacy(self):
        for mutate in [lambda q:q.update(generation=True),lambda q:q.update(observation_tick=2),lambda q:q['observation']['own'].update(other_faction_plans={}),lambda q:q.update(observation_hash='0'*64),lambda q:q['capabilities']['intents'].update(invented={'action':'spawn_army','payload':{}})]:
            q=copy.deepcopy(self.q);mutate(q);self.assertTrue(request_errors(q))
    def test_proposal_inventions_and_context(self):
        for field,value in [('version',True),('generation',99),('goal_id','unknown'),('cited_events',['invented_victory']),('intent_ids',['unknown']),('public_summary','x'*181),('extra','OS.execute')]:
            with self.subTest(field=field):
                p=copy.deepcopy(self.p);p[field]=value;self.assertTrue(reply_errors(self.q,p))
    def test_unknown_contingencies_and_duplicates(self):
        p=copy.deepcopy(self.p);p['supporting']=['trade','trade'];self.assertTrue(reply_errors(self.q,p))
        p=copy.deepcopy(self.p);p['contingencies']=[dict(predicate='invented_war',intent_id='unknown')];self.assertTrue(reply_errors(self.q,p))
    def test_save_budget_watermarks_and_pending(self):
        for mutate in [lambda s:s.update(version=3),lambda s:s['strategist'].update(request_seq=0),lambda s:s['strategist']['budget'].update(calls=9),lambda s:s['strategist'].update(mode='classic'),lambda s:s['strategist'].update(generation=99)]:
            s=copy.deepcopy(self.s);mutate(s);self.assertTrue(reference_errors(s))
    def test_explicit_checkpoint_tail(self):
        case=load('resources/data/strategist_replays/mine_region_2087.json')
        self.assertEqual(replay_errors(case),[])
        case['commands'][0]['sequence']+=1;self.assertTrue(replay_errors(case))
    def test_integral_json_numbers_have_stable_protocol_hash(self):
        self.assertEqual(digest({'n':1}),digest({'n':1.0}))
        self.assertNotEqual(digest({'n':True}),digest({'n':1}))
if __name__=='__main__': unittest.main()
