"""Actual-file rig/motion/FBX acceptance gates for presentation018."""
import argparse
from collections import Counter
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree
from bpy_extras.object_utils import world_to_camera_view

sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_warden_motion as M

checks=0
def require(ok,label):
    global checks
    assert ok,label
    checks+=1


def preservation():
    receipts=[M.BASE/'delivery.json',M.ROOT/'assets_src/characters/roster/manifest.json',M.ROOT/'assets_src/environment/manifest.json']
    result=[]
    for path in receipts:
        doc=json.loads(path.read_text());base=path.parent if path.name=='delivery.json' else M.ROOT
        for f in doc['files']:require(M.sha(base/f['path'])==f['sha256'],'preserved '+f['path'])
        result.append(dict(manifest=path.relative_to(M.ROOT).as_posix(),files=len(doc['files']),manifest_sha256=M.sha(path)))
    return result


def rest_proof():
    bpy.ops.wm.open_mainfile(filepath=str(M.BASE/'warden_restored.blend'))
    original={o.name:M.geometry_signature(o) for o in M.meshes()}
    bpy.ops.wm.open_mainfile(filepath=str(M.OUT/'warden_bound.blend'))
    rig=bpy.data.objects['Warden_Rig'];M.reset(rig)
    require(len(rig.data.bones)==29,'29 fitted deform bones')
    max_rest_drift=0.;maximum_influences=0;maximum_sum_error=0.;vertices=0
    deps=bpy.context.evaluated_depsgraph_get()
    for o in M.meshes():
        require(M.geometry_signature(o)==original[o.name],'exact rest geometry/topology/UV/materials '+o.name)
        require(o.parent==rig,'root motion inherited '+o.name)
        groupnames={g.index:g.name for g in o.vertex_groups}
        for v in o.data.vertices:
            w={groupnames[g.group]:g.weight for g in v.groups if g.weight>1e-6}
            require(bool(w),'weighted '+o.name+str(v.index))
            error=abs(sum(w.values())-1);maximum_sum_error=max(error,maximum_sum_error);require(error<1e-5,'normalized '+o.name+str(v.index))
            maximum_influences=max(maximum_influences,len(w));require(len(w)<=4,'max4 influences')
            if o.name==M.NAMES[0] and abs(v.co.x)>.012:
                wrong='.R' if v.co.x>0 else '.L'
                require(not any(n.endswith(wrong) or wrong+'.' in n for n in w),'opposite-side leak '+str(v.index))
            vertices+=1
        evaluated=o.evaluated_get(deps);mesh=evaluated.to_mesh()
        drift=max((v.co-o.data.vertices[v.index].co).length for v in mesh.vertices)
        max_rest_drift=max(max_rest_drift,drift);evaluated.to_mesh_clear()
    require(max_rest_drift<1e-6,'rest skinning no visible deformation')
    maps={}
    for p in (M.BASE/'textures').glob('*'):
        require(M.sha(p)==M.sha(M.OUT/'textures'/p.name),'unchanged texture '+p.name);maps[p.name]=M.sha(p)
    binding=json.loads((M.OUT/'binding.json').read_text());costume=M.meshes()[0]
    rigid=Counter()
    for label,ids in binding['semantic_vertex_indices'].items():
        if any(s in label for s in ('cuirass','shoulder_lame','glove','wrist_cuff','belt','pouch')):
            for i in ids:require(len([g for g in costume.data.vertices[i].groups if g.weight>1e-6])==1,'rigid '+label)
            rigid[label]=len(ids)
    return dict(weighted_vertices=vertices,bones=len(rig.data.bones),max_influences=maximum_influences,
        max_weight_sum_error=maximum_sum_error,unweighted_vertices=0,opposite_side_leaks=0,
        rest_skinning_drift_m=max_rest_drift,exact_rest_appearance=True,texture_sha256=maps,rigid_parts=dict(rigid))


def evaluated_points(o,ids):
    e=o.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=e.to_mesh()
    points=[o.matrix_world@mesh.vertices[i].co for i in ids];e.to_mesh_clear();return points


def bind_gate():
    preserved=preservation();proof=rest_proof()
    result=dict(status='TECHNICAL_PASS_VISUAL_REVIEW_REQUIRED',checks=checks,proof=proof,preserved=preserved,
        route='Manual fitted29-bone FK rig, explicit semantic weights. No auto-heat binding.',
        tested_pose_images=['placement_front','placement_side','placement_top','rest_three_quarter','ready_three_quarter','ready_elbow','squat_arm_raise','squat_knee_side','head_turn'],
        limitations=['No finger/face controls','Pilot joint range only; no extreme120degree deform claim','Continuous playback and native game not tested'],os_input_used=False)
    M.write('rig_verification.json',result)
    print('WARDEN_RIG_PASS',checks,'assertions',proof)


def mesh_sample():
    result={}
    for o in M.meshes()+[bpy.data.objects['Warden_Sword']]:
        ids=list(range(len(o.data.vertices)))
        result[o.name]=[list(p) for p in evaluated_points(o,ids)]
    return result


def triangle_count(objects):
    total=0
    for o in objects:o.data.calc_loop_triangles();total+=len(o.data.loop_triangles)
    return total


def motion_gate():
    require(json.loads((M.OUT/'rig_verification.json').read_text())['status'].startswith('TECHNICAL_PASS'),'rig gate before motion')
    preserved=preservation()
    bpy.ops.wm.open_mainfile(filepath=str(M.OUT/'warden_motion.blend'))
    rig=bpy.data.objects['Warden_Rig'];scene=bpy.context.scene;costume=M.meshes()[0]
    binding=json.loads((M.OUT/'binding.json').read_text());sword=json.loads((M.OUT/'sword.json').read_text())
    sole={side:[i for i in ids if costume.data.vertices[i].co.z<.012] for side,ids in binding['boot_vertex_indices'].items()}
    require(all(len(ids)>5 for ids in sole.values()),'actual sole vertices found')
    # Closest original glove vertex to the real handle centre remains a stable attachment witness.
    hand_ids=binding['semantic_vertex_indices']['Closed_anatomical_glove_-1'];grip=Vector(sword['grip_rest'])
    witness=min(hand_ids,key=lambda i:(costume.data.vertices[i].co-grip).length)
    expected_grip_distance=(costume.data.vertices[witness].co-grip).length
    reports={};source_samples={};total_frames=0
    triangles=triangle_count(M.meshes()+[bpy.data.objects['Warden_Sword']])
    for name,count in M.CLIPS.items():
        action=bpy.data.actions[name];rig.animation_data.action=action;rig.animation_data.action_slot=action.slots[0]
        require(len(action.slots)==1,'action slot '+name)
        contacts={side:[] for side in M.SIDES};min_floor=100.;grip_error=0.;previous={};rotation_step=0.;rotation_peak=None;extensions=[];blade_hits=[]
        tips=[];sampled={};endpoint={};foot_tracks={side:[] for side in M.SIDES};minimum_margin=1.
        for frame in range(count+1):
            scene.frame_set(frame);bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get()
            foot_points={side:evaluated_points(costume,ids) for side,ids in sole.items()}
            min_floor=min(min_floor,min(p.z for pts in foot_points.values() for p in pts))
            for side,s in M.SIDES.items():
                pts=foot_points[side]
                foot_tracks[side].append(dict(center=list(sum(pts,Vector())/len(pts)),minimum_z=min(p.z for p in pts)))
                p=(frame/count+(0 if side=='L' else .5))%1.
                stance=name!='Walk' or p<=.60+1e-8
                if stance:contacts[side].append((frame,foot_points[side]))
                hip=rig.pose.bones['thigh.'+side].head;ankle=rig.pose.bones['foot.'+side].head
                length=rig.pose.bones['thigh.'+side].length+rig.pose.bones['shin.'+side].length
                extensions.append((ankle-hip).length/length)
            for b in rig.pose.bones:
                q=b.rotation_quaternion
                if b.name in previous:
                    angle=previous[b.name].rotation_difference(q).angle
                    if angle>rotation_step:rotation_step=angle;rotation_peak=dict(bone=b.name,frame=frame,degrees=math.degrees(angle))
                previous[b.name]=q.copy()
            transform=rig.matrix_world@rig.pose.bones['hand.R'].matrix@rig.data.bones['hand.R'].matrix_local.inverted()
            actual_grip=transform@grip;point=evaluated_points(costume,[witness])[0]
            grip_error=max(grip_error,abs((point-actual_grip).length-expected_grip_distance))
            root=transform@Vector(sword['blade_root']);tip=transform@Vector(sword['blade_tip']);tips.append(list(tip))
            # Segment tests through evaluated costume/head; exclude the intentional hilt/fist contact.
            for o in [costume,bpy.data.objects[M.NAMES[1]]]:
                e=o.evaluated_get(deps);mesh=e.to_mesh();verts=[o.matrix_world@v.co for v in mesh.vertices]
                tree=BVHTree.FromPolygons(verts,[list(p.vertices) for p in mesh.polygons],all_triangles=False)
                mid=transform@(Vector(sword['blade_root'])+Vector(sword['axis_rest'])*.49)
                u=transform.to_3x3()@Vector((1,0,0));v=transform.to_3x3()@Vector((0,0,1))
                paths=[(root,mid,tip),(root+u*.025,mid+u*.020,tip),(root-u*.025,mid-u*.020,tip),
                    (root+v*.0045,mid+v*.0045,tip),(root-v*.0045,mid-v*.0045,tip)]
                for path_index,path in enumerate(paths):
                    for start,end in zip(path,path[1:]):
                        direction=end-start;hit=tree.ray_cast(start+direction.normalized()*.001,direction.normalized(),direction.length-.001)
                        if hit[0] is not None:blade_hits.append(dict(frame=frame,mesh=o.name,path=path_index,point=list(hit[0])))
                e.to_mesh_clear()
            if frame in (0,count//2,count):sampled[str(frame)]=mesh_sample()
            if frame in (0,count):
                endpoint[frame]={b.name:b.matrix.copy() for b in rig.pose.bones}
            for yaw in M.VIEWS.values():
                M.G.camera(yaw,ortho=3.84,size=384,elevation=18,target=(0,rig.location.y,1.00))
                bpy.context.view_layer.update()
                for o in M.meshes()+[bpy.data.objects['Warden_Sword']]:
                    evaluated=o.evaluated_get(deps)
                    for corner in evaluated.bound_box:
                        p=world_to_camera_view(scene,scene.camera,o.matrix_world@Vector(corner))
                        minimum_margin=min(minimum_margin,p.x,p.y,1-p.x,1-p.y)
            total_frames+=1
        slip=0.;contact_drift=0.
        for side,values in contacts.items():
            anchor=None;last_frame=None
            for frame,points in values:
                if last_frame is None or frame!=last_frame+1:anchor=points
                contact_drift=max(contact_drift,max((a-b).length for a,b in zip(anchor,points)))
                last_frame=frame
            for (fa,pa),(fb,pb) in zip(values,values[1:]):
                if fb-fa==1:slip=max(slip,max((a-b).length for a,b in zip(pa,pb)))
        closure=max(max(abs(endpoint[0][b][i][j]-endpoint[count][b][i][j]) for i in range(4) for j in range(4)) for b in endpoint[0])
        require(slip<.001,name+' world sole contact <1mm '+str(slip))
        require(contact_drift<.001,name+' entire planted interval drift <1mm '+str(contact_drift))
        require(min_floor>=.007,name+' no floor penetration '+str(min_floor))
        require(grip_error<.0001,name+' rigid grip')
        require(closure<.00001,name+' pose loop/return closure')
        (M.ROOT/'artifacts/warden-motion/last_motion_diagnostic.json').write_text(json.dumps(dict(clip=name,rotation_peak=rotation_peak,blade_hits=blade_hits,slip_m=slip,closure=closure),indent=2)+'\n')
        require(rotation_step<math.radians(45),name+' continuous rotation <45deg/frame '+str(rotation_peak))
        require(max(extensions)<.99,name+' bent knees, no extension clamp')
        require(not blade_hits,name+' blade intersects body '+str(blade_hits[:5]))
        require(minimum_margin>.02,name+' no view clips model/weapon')
        reports[name]=dict(frames_including_closure=count+1,sole_world_step_slip_m=slip,whole_stance_sole_world_drift_m=contact_drift,min_sole_z_m=min_floor,
            grip_attachment_error_m=grip_error,pose_closure_error=closure,max_frame_rotation_degrees=math.degrees(rotation_step),
            max_leg_extension_ratio=max(extensions),blade_body_hits=blade_hits,blade_paths_tested_per_frame=5,
            blade_tip_track=tips,foot_tracks=foot_tracks,minimum_four_view_bounds_margin_pixels=minimum_margin*384)
        source_samples[name]=sampled
    require(scene.render.fps==24,'24fps authoring')
    # Actual shipped FBX, including its real baked action slots.
    bpy.ops.wm.read_factory_settings(use_empty=False)
    M.G.setup_scene();bpy.context.scene.render.threads=6;bpy.context.scene.cycles.samples=12
    bpy.ops.import_scene.fbx(filepath=str(M.OUT/'warden_motion.fbx'),use_anim=True,anim_offset=0.)
    imported=[o for o in bpy.context.scene.objects if o.type=='MESH'];rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
    require(len(imported)==6 and len(rigs)==1,'FBX actual six meshes and one rig')
    require(triangle_count(imported)==triangles,'FBX triangles preserved')
    imported_rig=rigs[0];require(len(imported_rig.data.bones)==29,'FBX bones preserved')
    # FBX stores joints, not Blender tail/connect flags. Blender guesses a root
    # tail at its only child's head and auto-connects that child, suppressing
    # valid pelvis translation curves. Restore independent joints for evaluation.
    bpy.context.view_layer.objects.active=imported_rig;imported_rig.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT');auto_connected=[b.name for b in imported_rig.data.edit_bones if b.use_connect]
    for b in imported_rig.data.edit_bones:b.use_connect=False
    bpy.ops.object.mode_set(mode='OBJECT')
    imported_actions=[a for a in bpy.data.actions if any(len(s.channelbags) for l in a.layers for s in l.strips)]
    require(len(imported_actions)==3,'FBX three real actions '+str([a.name for a in imported_actions]))
    max_drift=0.;motion=0.;details=[]
    for name,count in M.CLIPS.items():
        action=next(a for a in imported_actions if a.name.endswith('|'+name) or a.name==name)
        imported_rig.animation_data.action=action;imported_rig.animation_data.action_slot=action.slots[0]
        for frame in (0,count//2,count):
            bpy.context.scene.frame_set(frame);bpy.context.view_layer.update()
            actual=mesh_sample();expected=source_samples[name][str(frame)]
            for obj in actual:
                # FBX may reorder joined geometry/material sections. Compare the
                # complete evaluated point clouds spatially in both directions.
                trees=[]
                for cloud in (actual[obj],expected[obj]):
                    tree=KDTree(len(cloud))
                    for i,p in enumerate(cloud):tree.insert(p,i)
                    tree.balance();trees.append(tree)
                distance=max(max(trees[1].find(p)[2] for p in actual[obj]),max(trees[0].find(p)[2] for p in expected[obj]))
                max_drift=max(max_drift,distance)
                details.append(dict(clip=name,frame=frame,mesh=obj,drift_m=distance,source_vertices=len(expected[obj]),fbx_vertices=len(actual[obj])))
            if frame==0:start=actual
            else:motion=max(motion,max((Vector(a)-Vector(b)).length for obj in actual for a,b in zip(actual[obj],start[obj])))
    M.write('fbx_comparison.json',details)
    require(max_drift<.001,'FBX actual evaluated pose-cloud drift <1mm '+str(max_drift))
    require(motion>.05,'FBX actually moves')
    maps=set()
    for o in imported:
        require(len(o.data.uv_layers)>=1,'FBX UV '+o.name)
        for mat in o.data.materials:
            for n in mat.node_tree.nodes:
                if n.type=='TEX_IMAGE' and n.image:
                    path=Path(bpy.path.abspath(n.image.filepath));require(path.exists(),'FBX texture resolves '+path.name);maps.add(path.name)
    require(maps=={p.name for p in (M.OUT/'textures').iterdir()},'FBX all five original maps')
    for name,frame in [('Idle',0),('Sword',17)]:
        action=next(a for a in imported_actions if a.name.endswith('|'+name))
        imported_rig.animation_data.action=action;imported_rig.animation_data.action_slot=action.slots[0]
        bpy.context.scene.frame_set(frame);bpy.context.view_layer.update()
        M.camera('fbx_'+name,yaw=330,ortho=2.8,size=640,target=(0,0,1.00))
    result=dict(status='TECHNICAL_PASS_AWAITING_USER_MOTION_REVIEW',checks=checks,frames_evaluated=total_frames,
        clips=reports,fbx=dict(actual_reimport=True,meshes=6,bones=29,triangles=triangles,actions=[a.name for a in imported_actions],
        maximum_sampled_pose_drift_m=max_drift,motion_amplitude_m=motion,blender_import_auto_connected_flags_cleared=auto_connected,import_animation_offset=0),preserved=preserved,os_input_used=False,gameplay_tested=False)
    M.write('motion_verification.json',result)
    print('WARDEN_MOTION_PASS',checks,'assertions',total_frames,'evaluated frames; FBX drift',max_drift)


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--phase',choices=['bind','motion'],required=True)
    a=p.parse_args(sys.argv[sys.argv.index('--')+1:])
    if a.phase=='bind':bind_gate()
    else:motion_gate()
