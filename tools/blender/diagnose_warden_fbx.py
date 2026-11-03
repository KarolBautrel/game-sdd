"""Read-only source/import transforms when the motion FBX gate fails."""
import json
from pathlib import Path
import sys
import bpy
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_warden_motion as M

def take(rig,frame):
    bpy.context.scene.frame_set(frame);bpy.context.view_layer.update()
    o=bpy.data.objects['MPFB_eyes'];e=o.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=e.to_mesh();co=list(o.matrix_world@mesh.vertices[0].co);e.to_mesh_clear()
    h=rig.pose.bones['hand.R'];d=h.matrix@h.bone.matrix_local.inverted()
    return dict(frame=frame,world=[list(r) for r in rig.matrix_world],eye=co,
        blade_axis=list(d.to_quaternion()@Vector((0,-1,0))),
        bones={n:dict(location=list(rig.pose.bones[n].location),head=list(rig.pose.bones[n].head),matrix=[list(r) for r in rig.pose.bones[n].matrix],rest=[list(r) for r in rig.data.bones[n].matrix_local]) for n in ('root','pelvis','chest','forearm.R','hand.R')})

bpy.ops.wm.open_mainfile(filepath=str(M.OUT/'warden_motion.blend'))
rig=bpy.data.objects['Warden_Rig'];rig.animation_data.action=bpy.data.actions['Idle'];rig.animation_data.action_slot=rig.animation_data.action.slots[0]
source=[take(rig,f) for f in (0,1,24)]
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(M.OUT/'warden_motion.fbx'),use_anim=True,anim_offset=0.)
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE');action=next(a for a in bpy.data.actions if a.name.endswith('|Idle'))
rig.animation_data.action=action;rig.animation_data.action_slot=action.slots[0]
imported=[take(rig,f) for f in (0,1,24)]
for layer in action.layers:
    for strip in layer.strips:
        for bag in strip.channelbags:
            for fc in bag.fcurves:
                if 'pelvis' in fc.data_path and 'location' in fc.data_path:print('FBX_PELVIS_CURVE',fc.data_path,fc.array_index,[(k.co.x,k.co.y) for k in list(fc.keyframe_points)[:3]])
folder=M.ROOT/'artifacts/warden-motion';folder.mkdir(parents=True,exist_ok=True)
(folder/'fbx_diagnostic.json').write_text(json.dumps(dict(source=source,imported=imported,action_frame_range=list(action.frame_range)),indent=2)+'\n')
for a,b in zip(source,imported):
    print('FRAME',a['frame'],'EYE',a['eye'],b['eye'],'PELVIS',a['bones']['pelvis']['head'],b['bones']['pelvis']['head'])
