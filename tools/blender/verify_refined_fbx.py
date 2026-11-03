"""Reimport the actual refined FBX deliveries; never infer validity from .blend."""
import hashlib,json,math
from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[2]

def load_fbx(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(path),use_anim=True)
    meshes=[obj for obj in bpy.data.objects if obj.type=='MESH']
    assert meshes and all(obj.data.uv_layers and obj.material_slots for obj in meshes),str(path)+' mesh/UV/materials'
    return meshes

catalogue=json.loads((ROOT/'resources/data/presentation/modular_actors.json').read_text());models=[]
for key,row in catalogue.items():
    if key!=row['id']:continue
    folder=ROOT/'assets_src/characters/modular'/key;path=folder/(key+'.fbx')
    if not path.exists():path=ROOT/row['original_source']/(key+'.fbx')
    meshes=load_fbx(path)
    rig=next(obj for obj in bpy.data.objects if obj.type=='ARMATURE')
    bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT')
    for bone in rig.data.edit_bones:bone.use_connect=False
    bpy.ops.object.mode_set(mode='OBJECT')
    assert len(rig.data.bones)==row['bones'] and all(all(v.groups for v in obj.data.vertices) for obj in meshes),key+' skin'
    clips={};clearance={}
    for kind,name in row['actions'][row['default_weapon']].items():
        clip=next(action for action in bpy.data.actions if action.name==name or action.name.endswith('|'+name))
        clips[kind]=clip.name
        rig.animation_data.action=clip;start,end=clip.frame_range
        if row['default_weapon'] in ['bow','spear','crossbow']:
            mesh=next(obj for obj in meshes if obj.name.startswith('part_weapon_'))
            minimum=100
            for index in range(17):
                frame=start+(end-start)*index/16;bpy.context.scene.frame_set(math.floor(frame),subframe=frame%1);bpy.context.view_layer.update()
                evaluated=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
                minimum=min(minimum,min((evaluated.matrix_world @ vertex.co).z for vertex in evaluated.data.vertices))
            clearance[kind]=round(minimum,5)
            assert minimum>=-.025,(key,kind,minimum)
    models.append({'id':key,'status':'PASS','source':path.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'bones':len(rig.data.bones),'clips':clips,'long_weapon_min_z':clearance})
(ROOT/'assets_src/characters/modular/fbx-check.json').write_text(json.dumps({'status':'PASS','models':models},indent=2)+'\n')
props=[]
for folder in sorted((ROOT/'assets_src/environment/props').iterdir()):
    path=folder/(folder.name+'.fbx');meshes=load_fbx(path)
    props.append({'id':folder.name,'status':'PASS','sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'meshes':len(meshes),'triangles':sum(len(p.vertices)-2 for obj in meshes for p in obj.data.polygons)})
(ROOT/'assets_src/environment/fbx-check.json').write_text(json.dumps({'status':'PASS','props':props},indent=2)+'\n')
print('REFINED_FBX_PASS',len(models),'actors',len(props),'props')
