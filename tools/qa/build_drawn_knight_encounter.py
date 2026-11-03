"""An isolated knight-animation encounter using existing combat rules/items."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]

def replace_id(value):
    if isinstance(value,dict):return {replace_id(k):replace_id(v) for k,v in value.items()}
    if isinstance(value,list):return [replace_id(x) for x in value]
    return 'unit_knight_pilot' if value=='unit_player_001' else value

def main():
    source=ROOT/'resources/data/combat_encounters/debug_full_combat_showcase.json'
    encounter=replace_id(json.loads(source.read_text(encoding='utf-8-sig')))
    encounter['id']='drawn_knight_sandbox'
    hero=next(u for u in encounter['units'] if u['id']=='unit_knight_pilot')
    hero['visual']={'faction':'heroes','character':'knight'}
    hero['loadout']['off_hand']=None
    destination=ROOT/'resources/data/combat_encounters/drawn_knight_sandbox.json'
    destination.write_text(json.dumps(encounter,indent=2)+'\n')
    path=ROOT/'resources/data/combat_scenarios/catalogue.json'
    catalogue=json.loads(path.read_text(encoding='utf-8'))
    if not any(s['id']=='drawn_knight_sandbox' for s in catalogue['scenarios']):
        catalogue['scenarios'].insert(1,{'id':'drawn_knight_sandbox','label':'Rycerz — próba animacji',
            'path':'res://resources/data/combat_encounters/drawn_knight_sandbox.json'})
        path.write_text(json.dumps(catalogue,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('DRAWN_KNIGHT_ENCOUNTER_PASS')

if __name__=='__main__':main()
