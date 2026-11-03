"""Validate native actor deliverables from GLB structure and persistent hashes."""
import argparse,hashlib,json,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]

def inspect():
    catalogue=json.loads((ROOT/'resources/data/presentation/modular_actors.json').read_text())
    roster=json.loads((ROOT/'resources/data/presentation/original_roster.json').read_text())
    ids={row['id'] for row in roster['characters']}
    assert set(catalogue)==ids|roster['aliases'].keys()
    proof=json.loads((ROOT/'assets_src/characters/modular/verification.json').read_text())
    assert proof['status']=='PASS' and {r['id'] for r in proof['models']}==ids
    checks={row['id']:row for row in proof['models']}
    fbx=json.loads((ROOT/'assets_src/characters/modular/fbx-check.json').read_text())
    assert fbx['status']=='PASS' and {row['id'] for row in fbx['models']}==ids
    for row in fbx['models']:
        assert hashlib.sha256((ROOT/row['source']).read_bytes()).hexdigest()==row['sha256']
        assert len(row['clips'])==5 and all(value>=-.025 for value in row['long_weapon_min_z'].values())
    for ident in sorted(ids):
        row=catalogue[ident];data=(ROOT/row['resource'].removeprefix('res://')).read_bytes()
        assert hashlib.sha256(data).hexdigest()==row['sha256']==checks[ident]['glb_sha256']
        assert data[:4]==b'glTF' and struct.unpack_from('<I',data,8)[0]==len(data)
        length=struct.unpack_from('<I',data,12)[0];gltf=json.loads(data[20:20+length])
        assert gltf['skins'] and gltf['images'] and gltf['textures']
        assert all('uri' not in image for image in gltf['images']),'Embedded textures required'
        assert all({'POSITION','NORMAL','TEXCOORD_0','JOINTS_0','WEIGHTS_0'}<=p['attributes'].keys() for mesh in gltf['meshes'] for p in mesh['primitives'])
        actions={animation['name'] for animation in gltf['animations']}
        assert all(name in actions for mapping in row['actions'].values() for name in mapping.values())
        nodes={n['name'] for n in gltf['nodes'] if n.get('name','').startswith('part_')}
        assert nodes=={'part_'+channel for channel in row['channels']}
        if row['hero']:assert {'armor_leather','armor_plate','boots_leather','boots_steel','helmet_cap','helmet_closed','weapon_bow','weapon_sword','offhand_shield'}<=set(row['channels'])
    for alias,target in roster['aliases'].items():assert catalogue[alias]['resource']==catalogue[target]['resource']
    for name in ('bran','torin'):
        data=(ROOT/'assets/ui/portraits'/f'{name}.png').read_bytes()
        assert struct.unpack('>II',data[16:24])==(128,128)
        assert (ROOT/'assets_src/aseprite/portraits'/f'{name}.aseprite').exists()
    print('Modular delivery PASS:',len(ids),'models, all aliases, skin/UV/actions/embedded textures and independent portraits')

if __name__=='__main__':inspect()
