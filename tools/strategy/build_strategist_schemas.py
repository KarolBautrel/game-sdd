"""Rebuild self-contained schemas for the offline strategist protocol/campaign."""
from pathlib import Path
import copy
import json

ROOT=Path(__file__).resolve().parents[2]
def integer(low=0, high=1_000_000_000): return dict(type='integer',minimum=low,maximum=high)
def obj(properties): return dict(type='object',properties=properties,required=list(properties),additionalProperties=False)
def array(item, cap, unique=False): return dict(type='array',items=item,maxItems=cap,uniqueItems=unique)
def enum(*values): return dict(enum=list(values))
ID=dict(type='string',pattern='^[a-z][a-z0-9_]{0,63}$')
TEXT=dict(type='string',maxLength=128)
HASH=dict(type='string',pattern='^[a-f0-9]{64}$')
RESOURCE=enum('food','ore','timber')
GOAL=enum('hold','commerce','supplies','claim','defend','peace')
REASONS=enum('reserve_deficit','profitable_exports','actual_war','war_costs','contested_supply_claim','rebuild_reserves','honour_agreement','protect_trade')
PREDICATES=enum('food_below_target','at_war','trade_offer_waiting')
FAULTS=['missing','timeout','interrupted','transport','malformed','budget','late','stale','committed_plan','context_mismatch','unknown_capability','invented_event']
def registry(item, cap=32): return dict(type='object',propertyNames=ID,additionalProperties=item,maxProperties=cap)
def counts(high=1_000_000_000): return obj({key:integer(0,high) for key in ['coin','food','ore','timber']})
def save(name,value):
    (ROOT/'resources/schemas'/name).write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')

def main():
    rules=obj(dict(schema={'const':'sdd.strategist-rules'},version={'const':1},provider={'const':'recorded_fixtures'},calls_per_minute=integer(0,4),calls_per_day=integer(0,8),tokens_per_day=integer(0,65536),response_tokens=integer(1,512),timeout_ms=integer(1,10000),cost_micro_limit={'const':0}))
    save('strategist_rules.schema.json',rules)
    examples=obj(dict(schema={'const':'sdd.strategist-examples'},version={'const':1},provenance=dict(type='string',maxLength=180),preferred_goals=registry(GOAL),default_goal=GOAL))
    save('strategist_examples.schema.json',examples)
    intents=[]
    payloads={
        'propose_trade':obj(dict(id={'const':'pending'},seller=ID,buyer=ID,resource=RESOURCE,amount=integer(1,12),unit_price=integer(1,100),source=ID,target=ID)),
        'mobilize':obj(dict(party=ID,route=ID)), 'protect_route':obj(dict(party=ID,route=ID)),
        'declare_war':obj(dict(target=ID,route=ID)), 'propose_peace':obj(dict(id={'const':'pending'},target=ID)),
        'propose_pact':obj(dict(id={'const':'pending'},target=ID,kind=enum('nonaggression','defensive_pact'),duration_ticks=integer(96,2880),valid_for_ticks=integer(1,672))),
        'respond_aid':obj(dict(id=ID,accept=dict(type='boolean'))),
    }
    for action in ['accept_trade','reject_trade','accept_peace','reject_peace','accept_pact','reject_pact']: payloads[action]=obj(dict(id=ID))
    for action,payload in payloads.items(): intents.append(obj(dict(action={'const':action},payload=payload)))
    policy=obj(dict(home=ID,claim_route=dict(type='string',maxLength=64),production=counts(1000),consumption=counts(1000),targets=counts(1000),personality=obj({k:integer(0,100) for k in ['trade','security','aggression']})))
    own=obj(dict(name=TEXT,stocks=counts(),manpower=integer(),available=counts(),policy=policy,shortfalls=counts(),prices=obj({k:integer(1,100) for k in ['food','ore','timber']})))
    observation=obj(dict(tick=integer(),seed=integer(1),actor=ID,own=own,previous=dict(type='object'),claim=dict(type='object'),live_trade_resources=array(RESOURCE,32),own_trade_route=TEXT,**{k:array(dict(type='object'),16 if k in ['reports','relations'] else (12 if k=='markets' else 8)) for k in ['forces','relations','markets','incoming_trades','incoming_pacts','incoming_peace','aid','pending_trades','reports']}))
    goal=obj(dict(goal=GOAL,target=dict(type='string',maxLength=64),resource=enum('','food','ore','timber')))
    capabilities=obj(dict(goals=registry(goal,40),intents=registry({'oneOf':intents},80),predicates={'const':['food_below_target','at_war','trade_offer_waiting']},reason_codes={'const':REASONS['enum']}))
    context=dict(policy_version={'const':1},request_id=dict(type='string',pattern='^request_[0-9]{8,}$'),faction_id=ID,generation=integer(1),observation_tick=integer(),apply_by_tick=integer(),requested_review_tick=integer(),horizon_tick=integer(),observation_hash=HASH)
    request=obj(dict(schema={'const':'sdd.strategist-request'},version={'const':1},number=integer(1),observation=observation,capabilities=capabilities,**context))
    reply=obj(dict(schema={'const':'sdd.strategist-reply'},version={'const':1},decision_id=dict(type='string',pattern='^decision_[0-9]{8,}$'),goal_id=ID,intent_ids=array(ID,3,True),supporting=array(enum('trade','guard','rebuild'),2,True),contingencies=array(obj(dict(predicate=PREDICATES,intent_id=ID)),2,True),reason_code=REASONS,cited_events=array(ID,4,True),public_summary=dict(type='string',maxLength=180),**context))
    save('strategist_request.schema.json',request);save('strategist_reply.schema.json',reply)
    maybe_reply={'oneOf':[obj({}),reply]}
    pending=obj(dict(request=request,status=enum('ready','sent','replied','fault'),reply=maybe_reply,fault=enum('',*FAULTS)))
    record=obj(dict(number=integer(1),request_id=context['request_id'],decision_id=reply['properties']['decision_id'],faction_id=ID,generation=integer(1),tick=integer(),outcome=enum('accepted','fallback','cancelled'),reason=enum('accepted','mode_changed',*FAULTS),observation_hash=HASH,reply=maybe_reply,executions=array(obj(dict(actor=ID,action=enum(*payloads),reason=TEXT)),3)))
    adapter=obj(dict(schema={'const':'sdd.strategist-state'},version={'const':1},mode=enum('classic','recorded'),generation=integer(),request_seq=integer(),pending=registry(pending),next_review=registry(integer()),completed=registry(integer()),emergency_day=registry(integer(-1)),last_material=registry(integer()),journal=array(record,64),totals=obj({k:integer() for k in ['accepted','fallback','cancelled','dispatched']}),budget=obj(dict(day=integer(),calls=integer(0,8),tokens=integer(0,65536),cost_micros={'const':0})),rules=rules))
    campaign=json.loads((ROOT/'resources/schemas/strategic_region.schema.json').read_text())
    campaign['properties']['version']={'const':4};campaign['properties']['strategist']=adapter;campaign['required'].append('strategist')
    save('strategist_campaign.schema.json',campaign)
    replay=obj(dict(schema={'const':'sdd.strategist-replay'},version={'const':1},checkpoint=dict(type='string',pattern='^res://resources/data/strategist_campaigns/[a-z0-9_]+[.]json$'),commands=array(obj(dict(id=ID,sequence=integer(1),action=TEXT,payload=dict(type='object'))),2048),expected_digest=HASH))
    save('strategist_replay.schema.json',replay)
    print('Rebuilt 6 strategist schemas')

if __name__=='__main__': main()
