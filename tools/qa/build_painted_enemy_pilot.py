"""Four accepted allies against archer, sword/shield bandit and wolf; isolated."""
import copy
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
ID='painted_enemy_pilot'


def read(rel):return json.loads((ROOT/rel).read_text(encoding='utf-8'))


def main():
    base=read('resources/data/combat_encounters/drawn_roster_skirmish.json')
    roles=read('resources/data/combat_encounters/slice_81_enemy_archetype_roles_v2.json')
    encounter=copy.deepcopy(base);encounter['id']=ID;encounter['seed']=2065
    encounter['units']=encounter['units'][:4]
    encounter['item_profiles'].update(roles['item_profiles'])
    encounter['enemy_archetypes']={k:roles['enemy_archetypes'][k] for k in ['raider_archer','raider_shieldman']}
    wolf_role=copy.deepcopy(roles['enemy_archetypes']['beast_stalker'])
    wolf_role.update(id='grey_wolf',display_name='Grey wolf',visual_pool=[dict(faction='villains',character='wolf_atlas')])
    encounter['enemy_archetypes']['grey_wolf']=wolf_role
    samples=[('unit_bandit_archer_pilot','Bandit archer','raider_archer','bandit_archer',(10,2),9,3,0,8,3,'raider_bow',None),
             ('unit_bandit_guard_pilot','Bandit shield fighter','raider_shieldman','painted_bandit_guard',(10,6),14,4,1,7,3,'raider_sword','raider_shield'),
             ('unit_wolf_pilot','Grey wolf','grey_wolf','wolf_atlas',(10,9),10,4,0,9,5,'beast_fangs',None)]
    for id,name,role,visual,position,hp,strength,defense,initiative,move,weapon,shield in samples:
        encounter['units'].append(dict(id=id,team='enemy',archetype_id=role,visual=dict(faction='villains',character=visual),
            position=dict(x=position[0],y=position[1]),stats=dict(max_hp=hp,strength=strength,defense=defense,initiative=initiative,move_points=move,max_ap=1,accuracy=5 if role=='raider_archer' else 0,evasion=0),
            resources=dict(hp=hp,ap=1,mp=move),statuses=[],available_actions=['move','defend','end_turn'],loadout=dict(main_hand=weapon,off_hand=shield,armor=None)))
    # The wolf is the existing melee/fangs role; no new bite resolution mechanic.
    encounter['turn_state']=dict(active_unit_id=encounter['units'][0]['id'],round=1,turn_order=[u['id'] for u in encounter['units']])
    path=ROOT/'resources/data/combat_encounters'/f'{ID}.json';path.write_text(json.dumps(encounter,indent=2)+'\n')
    path=ROOT/'resources/data/combat_scenarios/catalogue.json';catalogue=read(path.relative_to(ROOT))
    if not any(row['id']==ID for row in catalogue['scenarios']):
        catalogue['scenarios'].insert(1,dict(id=ID,label='Painted bandits & wolf - Old Mine',path='res://resources/data/combat_encounters/'+ID+'.json'))
    path.write_text(json.dumps(catalogue,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print('PAINTED_ENEMY_PILOT_BUILD_PASS 4 allies / 3 new opponents; no settlement/player save')


if __name__=='__main__':main()
