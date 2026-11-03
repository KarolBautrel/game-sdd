"""Presentation018: preserve stage43 meshes; fitted FK rig and measured motion.

Background-only. -- --phase bind|animate|render [--view three_quarter]
The chain solver authors ordinary exportable FK keys, not live IK constraints.
"""
import argparse
import array
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
import shutil
import sys

import bpy
from mathutils import Euler, Matrix, Quaternion, Vector
from mathutils.kdtree import KDTree

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'assets_src/characters/mpfb_warden_boots_only/2026-11-02'
OUT=ROOT/'assets_src/characters/warden_motion_pilot/2026-11-03'
OLD=ROOT/'assets_src/characters/surface_refinement/2026-11-02/02_warden/02_warden.blend'
NAMES=['Retained_authored_warden_costume','MPFB_coherent_head_and_neck','MPFB_eyes','MPFB_hair','MPFB_eyebrows']
VIEWS={'three_quarter':330,'front':0,'side':90,'rear':180}
CLIPS={'Idle':48,'Walk':32,'Sword':40}
SIDES={'L':1,'R':-1}
IDENTITY=Quaternion((1,0,0,0))
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_style_studies as G
from restore_warden_boots_only import structure


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(name,data):(OUT/name).write_text(json.dumps(data,indent=2)+'\n')
def ease(t):
    t=max(0.,min(1.,t));return t*t*(3-2*t)
def mix(a,b,t):return a*(1-t)+b*t
def rot(x=0,y=0,z=0):return Euler((x,y,z),'XYZ').to_quaternion()
def meshes():return [bpy.data.objects[n] for n in NAMES]
def geometry_signature(o):
    coords=array.array('f',[0.])*(len(o.data.vertices)*3)
    o.data.vertices.foreach_get('co',coords)
    return dict(vertices=len(o.data.vertices),coordinates_sha256=hashlib.sha256(coords.tobytes()).hexdigest(),structure=structure(o))


def semantic_source():
    bpy.ops.wm.open_mainfile(filepath=str(OLD))
    excluded=('face','hair','eye')
    points=[];labels=[]
    for o in bpy.data.objects:
        if o.type!='MESH' or not o.name.startswith('SOURCE_') or any(x in o.name.lower() for x in excluded):continue
        index=len(labels);labels.append(o.name.removeprefix('SOURCE_'))
        points.extend((o.matrix_world@v.co,index) for v in o.data.vertices)
    tree=KDTree(len(points))
    for i,(co,label) in enumerate(points):tree.insert(co,i)
    tree.balance()
    return tree,points,labels


def make_rig():
    data=bpy.data.armatures.new('Warden_fitted_deform_skeleton')
    rig=bpy.data.objects.new('Warden_Rig',data);bpy.context.scene.collection.objects.link(rig)
    rig.show_in_front=True;data.display_type='OCTAHEDRAL'
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
    bpy.ops.object.mode_set(mode='EDIT')
    def bone(name,head,tail,parent=None):
        b=data.edit_bones.new(name);b.head=head;b.tail=tail
        if parent:b.parent=data.edit_bones[parent]
        b.use_connect=False
        return b
    bone('root',(0,0,0),(0,0,.15))
    bone('pelvis',(0,0,.895),(0,0,1.13),'root')
    bone('spine',(0,0,1.13),(0,0,1.34),'pelvis')
    bone('chest',(0,0,1.34),(0,0,1.53),'spine')
    bone('neck',(0,0,1.53),(0,-.015,1.64),'chest')
    bone('head',(0,-.015,1.64),(0,-.015,1.84),'neck')
    bone('cape',(0,.16,1.47),(0,.20,1.00),'chest')
    for side,s in SIDES.items():
        shoulder=(s*.210,0,1.49);elbow=(s*.315,.028,1.205);wrist=(s*.398,-.006,.970)
        bone('clavicle.'+side,(s*.06,0,1.47),shoulder,'chest')
        bone('upper_arm.'+side,shoulder,elbow,'clavicle.'+side)
        bone('forearm.'+side,elbow,wrist,'upper_arm.'+side)
        bone('hand.'+side,wrist,(s*.413,-.045,.901),'forearm.'+side)
        hip=(s*.137,0,.875);knee=(s*.18,-.027,.520);ankle=(s*.18758,.018,.140)
        bone('thigh.'+side,hip,knee,'pelvis')
        bone('shin.'+side,knee,ankle,'thigh.'+side)
        bone('foot.'+side,ankle,(s*.18758,-.12,.085),'shin.'+side)
        bone('coat.'+side,(s*.12,0,1.12),(s*.17,0,.65),'pelvis')
        for i in range(3):bone('pauldron.'+side+'.'+str(i),shoulder,(s*.235,0,1.43),'clavicle.'+side)
    bpy.ops.object.mode_set(mode='OBJECT')
    for b in rig.pose.bones:b.rotation_mode='QUATERNION'
    rig['pipeline']='presentation018 / exact stage43 appearance / analytic FK authoring'
    rig['limits']='No facial/finger rig; pilot range only; no live IK controls or physics cloth.'
    return rig


def normalized(w):
    w={n:v for n,v in w.items() if v>1e-6};total=sum(w.values())
    return {n:v/total for n,v in w.items()}


def weights(label,p):
    x,y,z=p;side='L' if x>0 else 'R'
    if label.startswith('Fitted_boot'):
        # Rigid sole/foot, rigid shaft; only the leather ankle band flexes.
        shaft=ease((z-.20)/.10)
        return normalized({'foot.'+side:1-shaft,'shin.'+side:shaft})
    if 'glove' in label:return {'hand.'+side:1.}
    if 'wrist_cuff' in label:return {'forearm.'+side:1.}
    if 'shoulder_lame' in label:
        suffix=label.rsplit('.',1)[-1];index=int(suffix) if suffix.isdigit() else 0
        return {'pauldron.'+side+'.'+str(index%3):1.}
    if 'cuirass' in label:return {'chest':1.}
    if 'neckline' in label:return {'neck':1.}
    if 'belt' in label.lower() or 'pouch' in label:return {'pelvis':1.}
    if 'half_cloak' in label:
        t=ease((1.47-z)/.25);return normalized({'chest':1-t,'cape':t})
    if 'sleeves' in label:
        t=ease((1.28-z)/.15)
        if z>1.43:
            c=.25*ease((z-1.43)/.09)
            return normalized({'chest':c,'upper_arm.'+side:1-c})
        return normalized({'upper_arm.'+side:1-t,'forearm.'+side:t})
    if 'Trouser' in label:
        knee=ease((.59-z)/.14);hip=.32*ease((z-.76)/.14)
        return normalized({'thigh.'+side:(1-knee)*(1-hip),'shin.'+side:knee*(1-hip),'pelvis':hip})
    if 'Split_tailored_coat' in label:
        side='R' if label.endswith('-1') else 'L'
        t=ease((1.10-z)/.32)
        return normalized({'pelvis':1-t,'coat.'+side:t})
    if 'gambeson' in label:
        if z<1.10:
            t=.65*ease((1.10-z)/.32)
            return normalized({'pelvis':1-t,'thigh.'+side:t})
        chest=ease((z-1.13)/.20)
        return normalized({'spine':1-chest,'chest':chest})
    raise AssertionError('Unassigned semantic part '+label)


def bind(rig,tree,points,labels):
    counts=Counter();max_distance=0.;by_label={};boot_ids={}
    for o in meshes():
        o.hide_set(False);o.hide_render=False
        o.parent=rig;o.matrix_parent_inverse=Matrix.Identity(4)
        for g in list(o.vertex_groups):o.vertex_groups.remove(g)
        groups={b.name:o.vertex_groups.new(name=b.name) for b in rig.data.bones}
        for v in o.data.vertices:
            if o.name==NAMES[0]:
                _,i,distance=tree.find(o.matrix_world@v.co);label=labels[points[i][1]]
                assert distance<.013,(label,distance,tuple(v.co))
                max_distance=max(max_distance,distance)
                w=weights(label,v.co);counts[label]+=1
                by_label.setdefault(label,[]).append(v.index)
                if 'Fitted_boot' in label:boot_ids.setdefault('L' if v.co.x>0 else 'R',[]).append(v.index)
            elif o.name==NAMES[1]:
                t=ease((v.co.z-1.565)/.075);w=normalized({'neck':1-t,'head':t})
            else:w={'head':1.}
            for n,value in w.items():groups[n].add([v.index],value,'REPLACE')
        mod=o.modifiers.new('Fitted warden deformation','ARMATURE');mod.object=rig;mod.use_deform_preserve_volume=False
    return dict(semantic_counts=dict(counts),maximum_reference_distance_m=max_distance,
                semantic_vertex_indices=by_label,boot_vertex_indices=boot_ids)


def reset(rig):
    if rig.animation_data:rig.animation_data.action=None
    rig.location=(0,0,0);rig.rotation_euler=(0,0,0)
    for b in rig.pose.bones:b.matrix_basis=Matrix.Identity(4)
    bpy.context.view_layer.update()


def delta(rig,name,q,translation=None):
    """Apply a world-axis rest delta after the evaluated parent transform."""
    b=rig.pose.bones[name];rest=rig.data.bones[name]
    parent=(b.parent.matrix@b.parent.bone.matrix_local.inverted()) if b.parent else Matrix.Identity(4)
    mat=Matrix.Translation(rest.head_local)@q.to_matrix().to_4x4()@rest.matrix_local.to_quaternion().to_matrix().to_4x4()
    if translation is not None:mat.translation+=Vector(translation)
    b.matrix=parent@mat
    bpy.context.view_layer.update()


def world_bone(rig,name,start,end):
    b=rig.pose.bones[name];rest=rig.data.bones[name]
    q=(rest.tail_local-rest.head_local).rotation_difference(Vector(end)-Vector(start))@rest.matrix_local.to_quaternion()
    b.matrix=Matrix.Translation(start)@q.to_matrix().to_4x4();bpy.context.view_layer.update()


def solve_chain(rig,upper_name,lower_name,target,pole):
    upper=rig.pose.bones[upper_name];lower=rig.pose.bones[lower_name]
    start=upper.head.copy();target=Vector(target);direction=target-start
    distance=min(direction.length,(upper.length+lower.length)*.998)
    direction.normalize();bend=Vector(pole)-direction*Vector(pole).dot(direction);bend.normalize()
    a=(upper.length**2-lower.length**2+distance**2)/(2*distance)
    joint=start+direction*a+bend*math.sqrt(max(0.,upper.length**2-a*a))
    goal=start+direction*distance
    world_bone(rig,upper_name,start,joint);world_bone(rig,lower_name,joint,goal)
    return goal


def planted_legs(rig,goals,pitches=None):
    for side in SIDES:
        goal=solve_chain(rig,'thigh.'+side,'shin.'+side,goals[side],(0,-1,.03))
        q=rot(x=(pitches or {}).get(side,0))@rig.data.bones['foot.'+side].matrix_local.to_quaternion()
        rig.pose.bones['foot.'+side].matrix=Matrix.Translation(goal)@q.to_matrix().to_4x4()
        bpy.context.view_layer.update()


def arms(rig,right=(-.34,-.25,1.15),left=(.395,-.065,.98),twist=0,blade_aim=None):
    for side,target in [('R',right),('L',left)]:
        s=SIDES[side]
        wrist=solve_chain(rig,'upper_arm.'+side,'forearm.'+side,target,(s*.45,.35,-.8))
        lower=rig.pose.bones['forearm.'+side];rest=rig.data.bones['forearm.'+side]
        d=lower.matrix.to_quaternion()@rest.matrix_local.to_quaternion().inverted()
        wrist_bend=IDENTITY.copy()
        if side=='R' and blade_aim is not None:
            direction=(lower.tail-lower.head).normalized()
            current=d@Vector((0,-1,0));wanted=Vector(blade_aim).normalized()
            a=(current-direction*current.dot(direction)).normalized()
            z=(wanted-direction*wanted.dot(direction)).normalized()
            roll=math.atan2(direction.dot(a.cross(z)),a.dot(z))
            correction=Quaternion(direction,roll)
            # Pronation belongs to the forearm/cuff, not a disconnected wrist.
            d=correction@d
            lower.matrix=Matrix.Translation(lower.head)@(d@rest.matrix_local.to_quaternion()).to_matrix().to_4x4()
            bpy.context.view_layer.update()
            correction=(d@Vector((0,-1,0))).rotation_difference(wanted)
            wrist_bend=IDENTITY.slerp(correction,min(1.,math.radians(20)/max(.00001,correction.angle)))
        if side=='R':d=Quaternion((lower.tail-lower.head).normalized(),twist)@d
        q=wrist_bend@d@rig.data.bones['hand.'+side].matrix_local.to_quaternion()
        rig.pose.bones['hand.'+side].matrix=Matrix.Translation(wrist)@q.to_matrix().to_4x4()
        bpy.context.view_layer.update()
        upper=rig.pose.bones['upper_arm.'+side];ur=rig.data.bones['upper_arm.'+side]
        arm_delta=upper.matrix.to_quaternion()@ur.matrix_local.to_quaternion().inverted()
        for i,factor in enumerate((.48,.72,.92)):
            plate=rig.pose.bones['pauldron.'+side+'.'+str(i)]
            pr=plate.bone
            q=IDENTITY.slerp(arm_delta,factor)@pr.matrix_local.to_quaternion()
            plate.matrix=Matrix.Translation(upper.head)@q.to_matrix().to_4x4();bpy.context.view_layer.update()


def tails(rig,phase=0,attack=0):
    pelvis_delta=rig.pose.bones['pelvis'].matrix.to_quaternion()@rig.data.bones['pelvis'].matrix_local.to_quaternion().inverted()
    for side in SIDES:
        thigh=rig.pose.bones['thigh.'+side]
        leg_delta=pelvis_delta.inverted()@thigh.matrix.to_quaternion()@thigh.bone.matrix_local.to_quaternion().inverted()
        delta(rig,'coat.'+side,IDENTITY.slerp(leg_delta,.66)@rot(x=.018*math.sin(phase-1)))
    delta(rig,'cape',rot(x=.02*math.sin(phase-.9)+.04*attack,y=.012*math.sin(phase-.5)))


def camera(name,yaw=330,ortho=2.9,size=640,target=(0,-.04,1.03),elevation=18):
    G.camera(yaw,ortho=ortho,size=size,elevation=elevation,target=target)
    bpy.context.scene.render.filepath=str(OUT/'rig_review'/(name+'.png'))
    bpy.ops.render.render(write_still=True)


def joint_guides(rig,view='front'):
    col=bpy.data.collections.new('REVIEW - joint placement guides');bpy.context.scene.collection.children.link(col)
    mat=bpy.data.materials.new('Joint guide gold');mat.diffuse_color=(.95,.4,.04,1);mat.use_nodes=True
    bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED');bs.inputs['Base Color'].default_value=(1,.2,.01,1)
    bs.inputs['Emission Color'].default_value=(1,.25,.02,1);bs.inputs['Emission Strength'].default_value=.8
    for n in ('pelvis','chest','neck','head','upper_arm.L','upper_arm.R','forearm.L','forearm.R','hand.L','hand.R','thigh.L','thigh.R','shin.L','shin.R','foot.L','foot.R'):
        b=rig.data.bones[n];a=b.head_local.copy();z=b.tail_local.copy()
        # Thin overlay bones are intentionally in front of the body for fitting review.
        axis={'front':1,'side':0,'top':2}[view]
        plane={'front':-.285,'side':.51,'top':2.05}[view]
        a[axis]=plane;z[axis]=plane
        if (z-a).length<.002:continue
        bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=.007,depth=(z-a).length,location=(a+z)/2)
        o=bpy.context.object;o.name='GUIDE_'+n;o.rotation_euler=(z-a).to_track_quat('Z','Y').to_euler();o.data.materials.append(mat)
        for c in list(o.users_collection):c.objects.unlink(o)
        col.objects.link(o)
    return col


def bind_phase():
    for folder in ('textures','licenses','rig_review','renders','aseprite'):(OUT/folder).mkdir(parents=True,exist_ok=True)
    tree,points,labels=semantic_source()
    bpy.ops.wm.open_mainfile(filepath=str(BASE/'warden_restored.blend'))
    scene=bpy.context.scene;scene.render.threads=6;scene.cycles.samples=12;scene.render.use_persistent_data=True
    original={o.name:geometry_signature(o) for o in meshes()}
    for name in ('textures','licenses'):shutil.copytree(BASE/name,OUT/name,dirs_exist_ok=True)
    # Keep the original material graph; only locate its same byte-identical maps locally.
    for im in bpy.data.images:
        filename=Path(bpy.path.abspath(im.filepath)).name
        if (OUT/'textures'/filename).exists():im.filepath=str(OUT/'textures'/filename)
    rig=make_rig();semantic=bind(rig,tree,points,labels)
    for o in meshes():
        current=geometry_signature(o)
        assert current==original[o.name],('Rest appearance changed',o.name)
    write('rest_signatures.json',original);write('binding.json',semantic)
    reset(rig);guides=joint_guides(rig)
    camera('placement_front',yaw=0,ortho=2.5,size=720,target=(0,0,.94),elevation=0)
    guides.hide_render=True;guides.hide_viewport=True
    for view,yaw,elevation,target,ortho in [('side',90,0,(0,0,.94),2.5),('top',0,90,(0,0,.94),1.15)]:
        g=joint_guides(rig,view)
        camera('placement_'+view,yaw=yaw,elevation=elevation,target=target,ortho=ortho,size=720)
        g.hide_render=True;g.hide_viewport=True
    camera('rest_three_quarter')
    feet={side:rig.data.bones['foot.'+side].head_local.copy() for side in SIDES}
    reset(rig);delta(rig,'pelvis',rot(),(0,0,-.015));planted_legs(rig,feet);arms(rig)
    camera('ready_three_quarter')
    camera('ready_elbow',yaw=330,ortho=1.25,size=640,target=(-.28,-.09,1.28))
    reset(rig);delta(rig,'pelvis',rot(x=.08),(0,.015,-.115));planted_legs(rig,feet)
    arms(rig,right=(-.46,-.10,1.43),left=(.42,-.15,1.24));tails(rig)
    camera('squat_arm_raise',yaw=330)
    camera('squat_knee_side',yaw=90,ortho=1.35,size=640,target=(.1,0,.53))
    reset(rig);delta(rig,'head',rot(x=.10,z=.27))
    camera('head_turn',yaw=330,ortho=.64,size=640,target=(0,-.025,1.68))
    reset(rig)
    for im in bpy.data.images:
        if im.name not in ('Render Result','Viewer Node') and im.size[0]>0 and not im.packed_file:im.pack()
    G.camera(330,ortho=2.8,size=720,target=(0,0,.94))
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'warden_bound.blend'))
    print('WARDEN_BIND_BUILT',len(rig.data.bones),'bones',sum(len(o.data.vertices) for o in meshes()),'weighted vertices')


def sword(rig):
    """Original rigid prop. Grip centre crosses the closed fist, not its forearm."""
    center=Vector((-.414,-.045,.908));axis=Vector((0,-1,0));u=Vector((1,0,0));v=Vector((0,0,1))
    objects=[]
    def material(name,color,metal,rough):
        m=bpy.data.materials.new(name);m.use_nodes=True;b=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
        b.inputs['Base Color'].default_value=(*color,1);b.inputs['Metallic'].default_value=metal;b.inputs['Roughness'].default_value=rough;return m
    steel=material('Sword - forged grey steel',(.32,.39,.42),.78,.45)
    edge=material('Sword - honed edges',(.5,.56,.57),.8,.37)
    brass=material('Sword - aged brass',(.26,.17,.065),.7,.52)
    leather=material('Sword - dark wrapped grip',(.045,.025,.016),0,.82)
    def cylinder(name,at,radius,length,mat,vec=axis):
        bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=radius,depth=length,location=at)
        o=bpy.context.object;o.name=name;o.rotation_euler=Vector(vec).to_track_quat('Z','Y').to_euler();o.data.materials.append(mat);objects.append(o);return o
    cylinder('Wrapped leather grip',center,.012,.144,leather)
    for i in range(9):cylinder('Grip wrap',center+axis*(-.064+i*.016),.013,.003,brass)
    guard=center+axis*.092
    cylinder('Forged crossguard',guard,.010,.170,brass,vec=u)
    cylinder('Pommel',center-axis*.09,.024,.024,brass)
    root=guard+axis*.012;tip=root+axis*.67
    verts=[]
    for at,width in ((root,.025),(root+axis*.49,.020)):
        verts.extend([at-u*width,at+v*.0045,at+u*width,at-v*.0045])
    verts.append(tip)
    faces=[(j,(j+1)%4,4+(j+1)%4,4+j) for j in range(4)]+[(4+j,4+(j+1)%4,8) for j in range(4)]+[(3,2,1,0)]
    d=bpy.data.meshes.new('Diamond-section blade');d.from_pydata(verts,[],faces);d.update()
    o=bpy.data.objects.new('Forged blade',d);bpy.context.scene.collection.objects.link(o);o.data.materials.append(steel);o.data.materials.append(edge)
    for p in o.data.polygons:p.material_index=1 if p.index%2 else 0
    objects.append(o)
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=o;bpy.ops.object.join();o=bpy.context.object;o.name='Warden_Sword'
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(island_margin=.015);bpy.ops.object.mode_set(mode='OBJECT')
    o.parent=rig;o.matrix_parent_inverse=Matrix.Identity(4)
    g=o.vertex_groups.new(name='hand.R');g.add(list(range(len(o.data.vertices))),1,'REPLACE')
    mod=o.modifiers.new('Rigid sword follows hand grip','ARMATURE');mod.object=rig
    write('sword.json',dict(grip_rest=list(center),axis_rest=list(axis),blade_root=list(root),blade_tip=list(tip),grip_length_m=.144,crossguard_width_m=.170))
    return o


def sample_curve(knots,t):
    for a,b in zip(knots,knots[1:]):
        if a[0]<=t<=b[0]:
            s=ease((t-a[0])/(b[0]-a[0]));return tuple(mix(x,y,s) for x,y in zip(a[1],b[1]))
    return knots[-1][1]


def pose(rig,clip,f,boot_points):
    reset(rig);duration=CLIPS[clip];t=f/duration;phase=t*math.tau
    feet={side:rig.data.bones['foot.'+side].head_local.copy() for side in SIDES};pitches={side:0. for side in SIDES}
    attack=0.;twist=0.;blade_aim=(-.60,-.25,.76)
    if clip=='Idle':
        delta(rig,'pelvis',rot(y=.006*math.sin(phase),z=.008*math.sin(phase)),(.004*math.sin(phase),0,-.016+.002*math.sin(phase)))
        delta(rig,'chest',rot(x=.008*math.sin(phase),z=-.009*math.sin(phase)))
        delta(rig,'head',rot(x=.006*math.sin(phase-.5),z=.018*math.sin(phase-.35)))
        right=(-.34,-.25+.003*math.sin(phase),1.15+.003*math.sin(phase))
        left=(.395,-.065+.004*math.sin(phase),.98)
    elif clip=='Walk':
        rig.location.y=-.64*t
        delta(rig,'pelvis',rot(x=.025,y=.012*math.cos(phase),z=.025*math.cos(phase)),(.018*math.cos(phase),0,-.046+.010*math.cos(2*phase)))
        delta(rig,'chest',rot(z=-.045*math.cos(phase),x=.012))
        delta(rig,'head',rot(x=-.012,z=.024*math.cos(phase)))
        for side,offset in [('L',0),('R',.5)]:
            p=(t+offset)%1.
            if p<=.60:y=-.192+.64*p;lift=0.
            else:
                s=(p-.60)/.40;y=mix(.192,-.192,ease(s));lift=.075*math.sin(math.pi*s)**2;pitches[side]=.09*math.sin(math.tau*s)
            feet[side].y+=y
            # Compensate the actual rotated rigid boot sole so it never crosses ground.
            R=rot(x=pitches[side]);rest=rig.data.bones['foot.'+side].head_local
            minimum=min((R@(v-rest)).z for v in boot_points[side])
            feet[side].z=.008-minimum+lift
        right=(-.34,-.25+.018*math.cos(phase),1.15+.006*math.cos(2*phase))
        left=(.395,-.065-.095*math.cos(phase),.985+.012*math.sin(phase))
    else:
        knots=[(0,(-.34,-.25,1.15,0.,0.)),(8,(-.48,.045,1.43,0.,-.30)),
               (12,(-.46,-.045,1.48,0.,-.20)),(17,(-.23,-.43,1.28,0.,.25)),
               (22,(-.04,-.32,1.25,0.,.22)),(29,(-.25,-.29,1.12,0.,.05)),(40,(-.34,-.25,1.15,0.,0.))]
        x,y,z,twist,turn=sample_curve(knots,f);attack=math.sin(math.pi*t)**2
        blade_aim=sample_curve([(0,(-.60,-.25,.76)),(8,(-.60,.78,.15)),(12,(-.4,-.9,.05)),
            (17,(-.25,-.50,-.82)),(22,(.60,-.10,-.80)),(25,(-.10,-.98,-.15)),
            (27,(-.80,-.40,.45)),(29,(-.4,-.35,.85)),(40,(-.60,-.25,.76))],f)
        delta(rig,'pelvis',rot(x=.025*attack,z=turn*.45),(.10*turn,-.035*attack,-.016-.012*attack))
        delta(rig,'chest',rot(x=.035*attack,z=turn))
        delta(rig,'head',rot(x=-.02*attack,z=-turn*.65))
        right=(x,y,z);left=(.35,-.15-.04*attack,1.10+.05*attack)
    planted_legs(rig,feet,pitches);arms(rig,right,left,twist,blade_aim);tails(rig,phase,attack)


def action_curves(action):
    return [fc for layer in action.layers for strip in layer.strips for bag in strip.channelbags for fc in bag.fcurves]


def smooth_weapon_roll(rig,action,frames):
    """Five-frame periodic quaternion filter on forearm/wrist only.

    This removes an aim-projection pronation spike without filtering planted legs
    or changing the rigid hilt-to-fist relationship. Recheck collisions afterward.
    """
    scene=bpy.context.scene;rig.animation_data.action=action;rig.animation_data.action_slot=action.slots[0]
    names=('forearm.R','hand.R');cache={n:[] for n in names}
    for f in range(frames):
        scene.frame_set(f)
        for n in names:cache[n].append(rig.pose.bones[n].rotation_quaternion.copy())
    for n in names:
        result=[]
        for f in range(frames):
            ref=cache[n][f];components=[0.,0.,0.,0.]
            for offset,weight in zip(range(-2,3),(.06,.24,.4,.24,.06)):
                q=cache[n][(f+offset)%frames].copy()
                if q.dot(ref)<0:q.negate()
                for i in range(4):components[i]+=q[i]*weight
            q=Quaternion(components).normalized()
            if result and result[-1].dot(q)<0:q.negate()
            result.append(q)
        for f in range(frames+1):
            q=result[f%frames].copy()
            if f==frames and result[-1].dot(q)<0:q.negate()
            rig.pose.bones[n].rotation_quaternion=q
            rig.pose.bones[n].keyframe_insert(data_path='rotation_quaternion',frame=f)


def animate_phase():
    bpy.ops.wm.open_mainfile(filepath=str(OUT/'warden_bound.blend'))
    rig=bpy.data.objects['Warden_Rig'];sword(rig)
    binding=json.loads((OUT/'binding.json').read_text());costume=meshes()[0]
    boot_points={side:[costume.data.vertices[i].co.copy() for i in ids] for side,ids in binding['boot_vertex_indices'].items()}
    scene=bpy.context.scene;scene.render.fps=24;scene.frame_start=0
    for name,frames in CLIPS.items():
        reset(rig);rig.animation_data_create();action=bpy.data.actions.new(name);action.use_fake_user=True
        # Bake the analytic controls to standard pose channels: deterministic FK/FBX.
        previous={}
        for frame in range(frames+1):
            pose(rig,name,frame,boot_points)
            rig.animation_data.action=action
            rig.keyframe_insert(data_path='location',frame=frame)
            for b in rig.pose.bones:
                q=b.rotation_quaternion
                if b.name in previous and q.dot(previous[b.name])<0:q.negate()
                previous[b.name]=q.copy()
                b.keyframe_insert(data_path='location',frame=frame)
                b.keyframe_insert(data_path='rotation_quaternion',frame=frame)
            # reset() detaches the previous action while computing the next FK pose.
        smooth_weapon_roll(rig,action,frames)
        for fc in action_curves(action):
            for k in fc.keyframe_points:k.interpolation='LINEAR'
        assert len(action.slots)==1,(name,'missing or duplicate action slot')
    rig.animation_data.action=bpy.data.actions['Idle'];rig.animation_data.action_slot=rig.animation_data.action.slots[0]
    scene.frame_end=47;scene.frame_set(0);bpy.context.view_layer.update()
    write('timing.json',dict(fps=24,clips={n:dict(render_frames=f,closure_frame=f,seconds=f/24) for n,f in CLIPS.items()},
        walk=dict(root_travel_m=.64,stance_fraction=.60,lift_m=.075),
        sword_beats=[dict(frame=f,beat=b) for f,b in [(0,'ready'),(8,'anticipation'),(12,'raised blade'),(17,'strike'),(22,'follow through'),(29,'recovery'),(40,'ready closure')]]))
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes()+[bpy.data.objects['Warden_Sword'],rig]:o.select_set(True)
    bpy.context.view_layer.objects.active=rig
    bpy.ops.export_scene.fbx(filepath=str(OUT/'warden_motion.fbx'),use_selection=True,object_types={'MESH','ARMATURE'},
        bake_anim=True,bake_anim_use_all_actions=True,bake_anim_use_nla_strips=False,bake_anim_force_startend_keying=True,
        bake_anim_step=1.,bake_anim_simplify_factor=0.,add_leaf_bones=False,armature_nodetype='NULL',
        path_mode='RELATIVE',axis_forward='-Z',axis_up='Y')
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'warden_motion.blend'))
    print('WARDEN_MOTION_BUILT',list(CLIPS))


def render_phase(view,review=False):
    bpy.ops.wm.open_mainfile(filepath=str(OUT/'warden_motion.blend'))
    rig=bpy.data.objects['Warden_Rig'];scene=bpy.context.scene
    scene.cycles.samples=8;scene.render.threads=6;scene.render.use_persistent_data=True
    for name,frames in CLIPS.items():
        rig.animation_data.action=bpy.data.actions[name];rig.animation_data.action_slot=rig.animation_data.action.slots[0]
        folder=OUT/'renders'/name/view;folder.mkdir(parents=True,exist_ok=True)
        selected=({'Idle':[0,12,24,36],'Walk':[0,4,8,12,16,20,24,28],'Sword':[0,8,12,17,22,29,36]}[name] if review else range(frames))
        for f in selected:
            scene.frame_set(f);bpy.context.view_layer.update()
            travel=rig.location.y
            G.camera(VIEWS[view],ortho=3.84,size=384,elevation=18,target=(0,travel,1.00))
            # Keep studio lighting world-fixed; translate it with the walking source.
            for o in scene.objects:
                if o.type=='LIGHT':o.location.y=float(o.get('rest_y',o.location.y));o['rest_y']=o.location.y;o.location.y+=travel
            scene.render.filepath=str(folder/(str(f).zfill(3)+'.png'));bpy.ops.render.render(write_still=True)
        print('WARDEN_RENDERED',name,view,len(list(selected)))


def detail_phase():
    bpy.ops.wm.open_mainfile(filepath=str(OUT/'warden_motion.blend'))
    rig=bpy.data.objects['Warden_Rig'];scene=bpy.context.scene;scene.cycles.samples=20;scene.render.threads=6;scene.render.use_persistent_data=True
    for name,frame in [('Idle',0),('Walk',8),('Sword',8),('Sword',17),('Sword',22)]:
        rig.animation_data.action=bpy.data.actions[name];rig.animation_data.action_slot=rig.animation_data.action.slots[0]
        scene.frame_set(frame);bpy.context.view_layer.update()
        camera('motion_'+name+'_'+str(frame).zfill(2),ortho=2.8,size=900,target=(0,rig.location.y,1.00))


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--phase',choices=['bind','animate','render','detail'],required=True)
    parser.add_argument('--view',choices=list(VIEWS)+['all'],default='three_quarter');parser.add_argument('--review',action='store_true')
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    if args.phase=='bind':bind_phase()
    elif args.phase=='animate':animate_phase()
    elif args.phase=='detail':detail_phase()
    else:
        for view in (list(VIEWS) if args.view=='all' else [args.view]):render_phase(view,args.review)


if __name__=='__main__':main()
