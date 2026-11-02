"""Inspect saved modular geometry, skin weights and sampled long-weapon clearance."""
import json,sys,math,hashlib
from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).parent))
import build_roster as base

def inspect(row):
    ident=row['id'];folder=ROOT/'assets_src/characters/modular'/ident
    bpy.ops.wm.open_mainfile(filepath=str(folder/(ident+'.blend')))
    rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
    meshes=[o for o in bpy.data.objects if o.type=='MESH']
    assert all(o.data.uv_layers and all(v.groups for v in o.data.vertices) for o in meshes),ident+' UV/weights'
    assert all(o.name.startswith('part_') for o in meshes),ident+' named parts'
    meta=json.loads((folder/'model.json').read_text());clearance={}
    for weapon,actions in meta['actions'].items():
        for kind,name in actions.items():
            assert name in bpy.data.actions,(ident,name)
            if weapon not in ('bow','spear','crossbow'):continue
            weapon_mesh=next(o for o in meshes if o.name=='part_weapon_'+weapon)
            minimum=100
            clip=bpy.data.actions[name];start,end=clip.frame_range
            for frame in range(17):
                base.reset_pose(rig);rig.animation_data.action=clip
                value=start+(end-start)*frame/16
                bpy.context.scene.frame_set(math.floor(value),subframe=value%1);bpy.context.view_layer.update()
                evaluated=weapon_mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
                minimum=min(minimum,min((evaluated.matrix_world @ v.co).z for v in evaluated.data.vertices))
            clearance[weapon+'/'+kind]=round(minimum,5)
            assert minimum>=-.025,(ident,weapon,kind,minimum)
    return {'id':ident,'parts':len(meshes),'bones':len(rig.data.bones),'long_weapon_min_z':clearance,'status':'PASS','glb_sha256':hashlib.sha256((ROOT/row['resource'].removeprefix('res://')).read_bytes()).hexdigest()}

data=json.loads((ROOT/'resources/data/presentation/modular_actors.json').read_text())
rows=[inspect(row) for key,row in data.items() if key==row['id']]
report={'status':'PASS','models':rows}
(ROOT/'assets_src/characters/modular/verification.json').write_text(json.dumps(report,indent=2)+'\n')
print('MODULAR_SOURCE_PASS',len(rows),flush=True)
