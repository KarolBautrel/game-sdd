"""Offline strategist protocol references; gameplay authority remains in Godot."""
from pathlib import Path
import copy
import hashlib
import json
from jsonschema import Draft202012Validator
from tools.validators.strategic_region import reference_errors as regional_errors

ROOT=Path(__file__).resolve().parents[2]
def shape(name,value):
    schema=json.loads((ROOT/'resources/schemas'/f'strategist_{name}.schema.json').read_text())
    return [f'{name} shape: {e.message}' for e in Draft202012Validator(schema).iter_errors(value)]
def normalize(v):
    if isinstance(v,dict): return {k:normalize(x) for k,x in v.items()}
    if isinstance(v,list): return [normalize(x) for x in v]
    return int(v) if isinstance(v,float) and v.is_integer() else v
def digest(value):
    raw=json.dumps(normalize(value),sort_keys=True,separators=(',',':'),ensure_ascii=False)
    return hashlib.sha256(raw.encode()).hexdigest()
def request_errors(q):
    errors=shape('request',q)
    if errors: return errors
    if q['request_id']!=f"request_{int(q['number']):08d}" or q['faction_id']!=q['observation']['actor'] or q['observation_tick']!=q['observation']['tick']:
        errors.append('request identity/observation mismatch')
    if q['apply_by_tick']!=((int(q['observation_tick'])+47)//24)*24 or q['requested_review_tick']!=q['apply_by_tick']+672 or q['horizon_tick']!=q['apply_by_tick']+1344:
        errors.append('request fixed boundary mismatch')
    if digest(dict(observation=q['observation'],capabilities=q['capabilities']))!=q['observation_hash']: errors.append('request snapshot hash mismatch')
    for field,prefix in [('goals','goal_'),('intents','candidate_')]:
        for key,value in q['capabilities'][field].items():
            if key!=prefix+digest(value)[:20]: errors.append('capability identity mismatch')
    if len(json.dumps(q,ensure_ascii=False,separators=(',',':')).encode())>32768: errors.append('request exceeds byte bound')
    return errors
def reply_errors(q,p):
    errors=shape('reply',p)
    if errors: return errors
    if request_errors(q): return ['invalid request context']
    for field in ['policy_version','request_id','faction_id','generation','observation_tick','apply_by_tick','requested_review_tick','horizon_tick','observation_hash']:
        if p[field]!=q[field]: errors.append('reply context mismatch')
    if p['decision_id']!=f"decision_{int(q['number']):08d}" or p['goal_id'] not in q['capabilities']['goals']: errors.append('unknown decision/goal')
    chosen=list(p['intent_ids'])
    for item in p['contingencies']: chosen.append(item['intent_id'])
    if len(chosen)!=len(set(chosen)) or any(key not in q['capabilities']['intents'] for key in chosen): errors.append('unknown/duplicate intent')
    known={event['id'] for event in q['observation']['reports']}
    if set(p['cited_events'])-known: errors.append('invented cited event')
    if len(json.dumps(p,ensure_ascii=False,separators=(',',':')).encode())>16384: errors.append('reply exceeds byte bound')
    return errors
def reference_errors(s):
    errors=shape('campaign',s)
    if errors: return errors
    region=copy.deepcopy(s);a=region.pop('strategist');region['version']=3
    errors.extend(regional_errors(region))
    core=s['strategy_world']['core'];tick=core['tick'];ids=set(core['factions'])
    for field in ['next_review','completed','emergency_day','last_material']:
        if set(a[field])!=ids: errors.append('adapter faction registry mismatch')
    if a['mode']=='classic' and a['pending']: errors.append('classic mode retains pending request')
    if sum(a['totals'][key] for key in ['accepted','fallback','cancelled'])+len(a['pending'])!=a['request_seq'] or a['totals']['dispatched']>a['request_seq']: errors.append('adapter request accounting mismatch')
    if a['budget']['day']>tick//96 or a['budget']['calls']>a['rules']['calls_per_day'] or a['budget']['tokens']>a['rules']['tokens_per_day']: errors.append('adapter budget mismatch')
    numbers=set()
    for actor,pending in a['pending'].items():
        q=pending['request'];errors.extend(request_errors(q))
        if actor not in ids or q['faction_id']!=actor or q['generation']!=a['generation'] or q['number']<=a['completed'].get(actor,-1) or q['number']>a['request_seq'] or q['number'] in numbers or q['observation_tick']>tick or q['apply_by_tick']<=tick: errors.append('pending context/watermark mismatch')
        numbers.add(q['number'])
        if pending['status']=='replied': errors.extend(reply_errors(q,pending['reply']))
        elif pending['reply']: errors.append('unreplied request contains a reply')
        if (pending['status']=='fault')!=bool(pending['fault']): errors.append('pending fault/status mismatch')
    seen=set()
    for record in a['journal']:
        n=record['number'];actor=record['faction_id']
        if n in seen or n>a['request_seq'] or actor not in ids or n>a['completed'].get(actor,-1) or record['generation']>a['generation'] or record['tick']>tick or record['request_id']!=f'request_{int(n):08d}' or record['decision_id']!=f'decision_{int(n):08d}': errors.append('journal identity/watermark mismatch')
        seen.add(n)
        if record['outcome']=='accepted' and (not record['reply'] or record['reason']!='accepted'): errors.append('accepted decision lacks reply')
        if any(e['actor']!=actor for e in record['executions']): errors.append('journal operator actor mismatch')
    if any(n>a['request_seq'] for n in a['completed'].values()): errors.append('completion watermark exceeds requests')
    return errors
def replay_errors(case):
    errors=shape('replay',case)
    if errors: return errors
    path=ROOT/case['checkpoint'].removeprefix('res://')
    if not path.is_file(): return ['replay checkpoint missing']
    checkpoint=json.loads(path.read_text());errors.extend(reference_errors(checkpoint))
    for index,cmd in enumerate(case['commands'],int(checkpoint['request_seq'])+1):
        if cmd['sequence']!=index or cmd['id']!=f'region_{index:08d}': errors.append('replay tail sequence mismatch')
    return errors
