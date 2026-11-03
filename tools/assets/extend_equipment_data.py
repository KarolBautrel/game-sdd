"""Idempotent authored catalogue/schema extension for the five visual gear slots."""
import copy,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def read(path):return json.loads((ROOT/path).read_text())
def save(path,data):(ROOT/path).write_text(json.dumps(data,indent=2)+'\n')
catalogue=read('resources/data/items/catalogue.json')
looks={'hero_sword':{'weapon':'sword'},'hero_bow':{'weapon':'bow'},'salvaged_blade':{'weapon':'sword'},'salvaged_shield':{'offhand':'shield'},'patched_leather':{'armor':'leather'}}
for row in catalogue['items']:
    if row['id'] in looks:row['appearance']=looks[row['id']]
new=[('leather_boots','Ranger boots','boots','leather',6),('steel_boots','Iron greaves','boots','steel',10),('leather_cap','Leather cap','helmet','cap',8),('closed_helm','Closed iron helm','helmet','closed',14),('weathered_cuirass','Weathered cuirass','armor','plate',18)]
for ident,name,slot,look,price in new:
    if any(row['id']==ident for row in catalogue['items']):continue
    profile={'id':ident,'slot':slot,'grants_actions':[]}
    if slot=='armor':profile['armor_reduction']=1
    catalogue['items'].append({'id':ident,'name':name,'description':('Worn steel armour. Reduces incoming damage by 1, like patched leather.' if slot=='armor' else 'Changes the visible '+slot+'. Cosmetic equipment; no combat bonus.'),'category':'equipment','value':price//2,'combat_profile':profile,'appearance':{slot:look}})
save('resources/data/items/catalogue.json',catalogue)
trade=read('resources/data/town_trade/ravenford.json')
for ident,name,slot,look,price in new:
    if not any(row['item_id']==ident for row in trade['offers']):trade['offers'].append({'item_id':ident,'buy_price':price})
save('resources/data/town_trade/ravenford.json',trade)
profile=read('resources/data/campaign/new_game.json')
for loadout in profile['equipment'].values():loadout.update(boots=None,helmet=None)
save('resources/data/campaign/new_game.json',profile)
item_schema=read('resources/schemas/campaign_item_catalogue.schema.json')
item_schema['properties']['items']['items']['properties']['appearance']={'type':'object','additionalProperties':False,'properties':{key:{'enum':values} for key,values in {'weapon':['sword','bow','axe','mace','dagger','cleaver','spear','crossbow'],'offhand':['shield'],'armor':['leather','plate'],'boots':['leather','steel'],'helmet':['cap','closed']}.items()}}
save('resources/schemas/campaign_item_catalogue.schema.json',item_schema)
def extend(value,pair=False):
    if isinstance(value,dict):
        props=value.get('properties',{})
        if {'main_hand','off_hand','armor'}<=props.keys():
            for key in ('boots','helmet'):props[key]=copy.deepcopy(props['armor'])
            if pair:value['dependentRequired']={'boots':['helmet'],'helmet':['boots']}
        if props.get('slot',{}).get('enum')==['main_hand','off_hand','armor']:props['slot']['enum']+=['boots','helmet']
        for child in list(value.values()):extend(child,pair)
    elif isinstance(value,list):
        for child in value:extend(child,pair)
for path in ['resources/schemas/combat_encounter.schema.json','resources/schemas/campaign_profile.schema.json']:
    schema=read(path);extend(schema,'campaign_profile' in path);save(path,schema)
print('Extended catalogue, smith offers, new game and schemas to five visual slots')
