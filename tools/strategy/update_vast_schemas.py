"""Extend existing immutable geography formats; never rewrite source fixtures."""
from pathlib import Path
import copy
import json
ROOT=Path(__file__).resolve().parents[2]
def read(name): return json.loads((ROOT/'resources/schemas'/f'{name}.schema.json').read_text())
def write(name,s): (ROOT/'resources/schemas'/f'{name}.schema.json').write_text(json.dumps(s,indent=2)+'\n')
def main():
    generated=read('generated_region')
    generated['properties']['version']['enum']=[1,2,3]
    terrain=generated['properties']['terrain']['properties']
    terrain['width']['enum']=[192,384,768];terrain['height']['enum']=[108,216,432]
    terrain['rows']['maxItems']=432;terrain['rows']['items']['maxLength']=768
    for key in ['land_cells','connected_cells']: generated['properties']['diagnostics']['properties'][key]['maximum']=768*432
    generated['allOf']=[clause for clause in generated['allOf'] if clause.get('if',{}).get('properties',{}).get('version',{}).get('const')!=3]
    branch=copy.deepcopy(next(clause for clause in generated['allOf'] if clause['if']['properties']['version']['const']==2))
    branch['if']['properties']['version']['const']=3
    p=branch['then']['properties']['terrain']['properties'];p['width']['const']=768;p['height']['const']=432;p['rows'].update(minItems=432,maxItems=432);p['rows']['items'].update(minLength=768,maxLength=768)
    generated['allOf'].append(branch)
    for clause in generated['allOf']:
        version=clause['if']['properties']['version']['const'];factor={1:1,2:2,3:4}[version]
        clause['then'].setdefault('properties',{})['diagnostics']={'properties':{key:{'maximum':192*108*factor*factor} for key in ['land_cells','connected_cells']}}
    write('generated_region',generated)
    inline=copy.deepcopy(generated);inline.pop('$schema',None)
    def patch(node):
        if isinstance(node,list): return [patch(v) for v in node]
        if not isinstance(node,dict): return node
        props=node.get('properties',{})
        if {'attempt','preset','checksum','terrain','road_paths','climates'}<=set(props): return copy.deepcopy(inline)
        result={k:patch(v) for k,v in node.items()}
        props=result.get('properties',{})
        if {'width','height','rows','region'}<=set(props) and props['width'].get('maximum')==512 and props['height'].get('maximum')==288:
            props['width']['maximum']=768;props['height']['maximum']=432
        return result
    for name in ['living_region','living_world_state','campaign_profile','strategic_region']:write(name,patch(read(name)))
    print('Updated generated geography and embedded snapshot schemas; authored mask schema preserved')
if __name__=='__main__': main()
