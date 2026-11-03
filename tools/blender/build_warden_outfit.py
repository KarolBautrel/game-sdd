"""Presentation016: real armor/leather construction on a coherent MPFB stance."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import shutil
import sys

import bpy
import bmesh
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).resolve().parent))
from mpfb_runtime import enable_mpfb
import build_style_studies as G
from build_surface_refinement import curved_rings
sys.path.insert(0,str(Path.home()/'.codex/skills/scenario-blender-hard-surface/scripts'))
import bx_hardsurface as HS
sys.path.insert(0,str(Path.home()/'.codex/skills/scenario-blender-expert/scripts'))
import bx_audit as AUDIT

BEFORE=ROOT/'assets_src/characters/mpfb_warden/2026-11-02'
OLD=ROOT/'assets_src/characters/surface_refinement/2026-11-02/02_warden'
OUT=ROOT/'assets_src/characters/mpfb_warden_outfit/2026-11-02'
PARTS=[]
HEAD=[]
MATS={}
JOINTS={}
METRICS={}
TORSO_TREE=None
PANTS_TREE=None
CLOAK=None
CLOAK_HEM=[]


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def active(obj):
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True)
    bpy.context.view_layer.objects.active=obj


def mesh(name,vertices,faces,mat,smooth=True):
    data=bpy.data.meshes.new(name);data.from_pydata(vertices,[],faces);data.update()
    obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj)
    data.materials.append(mat)
    for face in data.polygons:face.use_smooth=smooth
    PARTS.append(obj);return obj


def finish(obj,thickness=0,bevel=0):
    active(obj)
    if thickness:
        mod=obj.modifiers.new('Real material thickness','SOLIDIFY');mod.thickness=thickness;mod.offset=-1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    if bevel:
        mod=obj.modifiers.new('Rounded manufactured edge','BEVEL');mod.width=bevel;mod.segments=3
        mod.limit_method='ANGLE';mod.angle_limit=.65
        bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.data.update();return obj


def tube(name,points,radius,mat):
    points=list(points);closed=(Vector(points[0])-Vector(points[-1])).length<.000001
    if closed:points=points[:-1]
    curve=bpy.data.curves.new(name,'CURVE');curve.dimensions='3D'
    curve.resolution_u=2;curve.bevel_depth=radius;curve.bevel_resolution=2
    spline=curve.splines.new('POLY');spline.points.add(len(points)-1)
    spline.use_cyclic_u=closed
    for p,co in zip(spline.points,points):p.co=(*co,1)
    obj=bpy.data.objects.new(name,curve);bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat);active(obj);bpy.ops.object.convert(target='MESH')
    PARTS.append(obj);return obj


def ball(name,center,radius,mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=radius,location=center)
    obj=bpy.context.object;obj.name=name;obj.data.materials.append(mat)
    bpy.ops.object.transform_apply(location=True,rotation=False,scale=True)
    for face in obj.data.polygons:face.use_smooth=True
    PARTS.append(obj);return obj


def box(name,center,half,mat,frame=None):
    bpy.ops.mesh.primitive_cube_add(size=2,location=center)
    obj=bpy.context.object;obj.name=name;obj.scale=half
    if frame:obj.rotation_euler=frame.to_euler()
    HS.apply_scale(obj);obj.data.materials.append(mat);finish(obj,bevel=.001)
    PARTS.append(obj);return obj


def material(name,color,rough=.6,metal=0,variation=.12):
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    ns,ls=mat.node_tree.nodes,mat.node_tree.links
    bs=next(n for n in ns if n.type=='BSDF_PRINCIPLED')
    bs.inputs['Metallic'].default_value=metal;bs.inputs['Roughness'].default_value=rough
    bs.inputs['Specular IOR Level'].default_value=.35
    coord=ns.new('ShaderNodeTexCoord');noise=ns.new('ShaderNodeTexNoise')
    noise.inputs['Scale'].default_value=48 if metal else 100;noise.inputs['Detail'].default_value=2
    ls.new(coord.outputs['Object'],noise.inputs['Vector'])
    ramp=ns.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].color=tuple(v*(1-variation) for v in color)+(1,)
    ramp.color_ramp.elements[1].color=tuple(v*(1+variation) for v in color)+(1,)
    ls.new(noise.outputs['Fac'],ramp.inputs[0]);ls.new(ramp.outputs[0],bs.inputs['Base Color'])
    r=ns.new('ShaderNodeMapRange');r.inputs['To Min'].default_value=max(.1,rough-.07)
    r.inputs['To Max'].default_value=min(1,rough+.07)
    ls.new(noise.outputs['Fac'],r.inputs[0]);ls.new(r.outputs[0],bs.inputs['Roughness'])
    if metal>.5:
        fine=ns.new('ShaderNodeTexNoise');fine.inputs['Scale'].default_value=380;fine.inputs['Detail'].default_value=2
        ls.new(coord.outputs['Object'],fine.inputs['Vector'])
        blend=ns.new('ShaderNodeMixRGB');blend.blend_type='MULTIPLY';blend.inputs[0].default_value=.28
        ls.new(r.outputs[0],blend.inputs[1]);ls.new(fine.outputs['Fac'],blend.inputs[2]);ls.new(blend.outputs[0],bs.inputs['Roughness'])
    MATS[name]=mat;return mat


def interpolate(z,points):
    if z<=points[0][0]:return points[0][1]
    for (a,x),(b,y) in zip(points,points[1:]):
        if z<=b:return x+(y-x)*(z-a)/(b-a)
    return points[-1][1]


def warp(p):
    p=p.copy();side=1 if p.x>=0 else -1
    if p.z<1.02 and abs(p.x)<.29:
        old=interpolate(p.z,[(.075,.20044556),(.5384,.15994145),(.9851,.11720002),(1.02,.1172)])
        target=interpolate(p.z,[(.075,.14),(.5384,.14),(.9851,.11720002),(1.02,.1172)])
        p.x-=side*(old-target)
    elif (p.z>1.18 and abs(p.x)>.17) or (p.z>.75 and abs(p.x)>.30):
        shoulder=Vector((side*.19467624,.00115007,1.47924864))
        weight=max(0,min(1,(abs(p.x)-.14)/.12));weight=weight*weight*(3-2*weight)
        rotated=shoulder+Matrix.Rotation(side*math.radians(20),3,'Y')@(p-shoulder)
        p=p.lerp(rotated,weight)
    return p


def load_body():
    enable_mpfb()
    names=['MPFB_coherent_head_and_neck','MPFB_eyes','MPFB_hair','MPFB_eyebrows','MPFB_editable_human_master']
    with bpy.data.libraries.load(str(BEFORE/'mpfb_warden.blend'),link=False) as (src,dst):dst.objects=names[:]
    objects={o.name:o for o in dst.objects}
    for obj in objects.values():bpy.context.collection.objects.link(obj)
    for name in names[:-1]:HEAD.append(objects[name])
    for obj in HEAD:
        for mat in obj.data.materials:
            for node in mat.node_tree.nodes:
                if node.type=='TEX_IMAGE' and node.image:
                    path=BEFORE/'textures'/Path(node.image.filepath).name
                    dest=OUT/'textures'/path.name;shutil.copyfile(path,dest);node.image.filepath=str(dest)
    body=objects[names[-1]]
    masks=[m for m in body.modifiers if m.type=='MASK']
    for mod in masks:mod.show_viewport=False;mod.show_render=False
    bpy.context.view_layer.update();ev=body.evaluated_get(bpy.context.evaluated_depsgraph_get())
    body_group=body.vertex_groups['body'].index
    skin_ids=[v.index for v in body.data.vertices if any(g.group==body_group for g in v.groups)]
    top=max((body.matrix_world@ev.data.vertices[i].co).z for i in skin_ids)
    transform=Matrix.Translation((0,.020,0))@Matrix.Scale(1.84/top,4)
    world=transform@body.matrix_world;inverse=world.inverted()
    METRICS['anatomy_source_to_costume_matrix']=[list(row) for row in world]
    before={}
    for group in body.vertex_groups:
        if not group.name.startswith('joint-'):continue
        ids=[v.index for v in body.data.vertices if any(g.group==group.index for g in v.groups)]
        if ids:before[group.name]=sum((world@ev.data.vertices[i].co for i in ids),Vector())/len(ids)
    coordinates=[v.co.copy() for v in ev.data.vertices]
    target=body.shape_key_add(name='WARDEN_rest_stance_and_arm_fit')
    basis=body.data.shape_keys.key_blocks[0]
    for index,co in enumerate(coordinates):
        delta=inverse@warp(world@co)-co
        target.data[index].co=basis.data[index].co+delta
    target.value=1
    for name,co in before.items():JOINTS[name]=warp(co)
    METRICS['leg_axes_before']={k:list(v) for k,v in before.items() if 'ankle' in k or 'knee' in k or 'upper-leg' in k}
    METRICS['leg_axes_after']={k:list(v) for k,v in JOINTS.items() if 'ankle' in k or 'knee' in k or 'upper-leg' in k}
    for mod in masks:mod.show_viewport=True;mod.show_render=True
    bpy.context.view_layer.update();ev=body.evaluated_get(bpy.context.evaluated_depsgraph_get())
    data=bpy.data.meshes.new_from_object(ev);data.transform(world);data.update()
    scaffold=bpy.data.objects.new('Posed_MPFB_surface_scaffold',data);bpy.context.collection.objects.link(scaffold)
    hidden=bpy.data.collections.new('SOURCE - coherent posed MPFB anatomy')
    bpy.context.scene.collection.children.link(hidden)
    for obj in (body,scaffold):
        for c in list(obj.users_collection):c.objects.unlink(obj)
        hidden.objects.link(obj)
    hidden.hide_render=True;hidden.hide_viewport=True
    return scaffold


def extract(scaffold,name,predicate,mat,offset=.008):
    vertices=[v.co.copy() for v in scaffold.data.vertices]
    faces=[tuple(f.vertices) for f in scaffold.data.polygons if predicate(f.center)]
    obj=mesh(name,vertices,faces,mat)
    bm=bmesh.new();bm.from_mesh(obj.data)
    bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
    bm.normal_update()
    for v in bm.verts:v.co+=v.normal*offset
    bm.to_mesh(obj.data);bm.free();obj.data.update();return obj


def fit_radial(obj,tree,clearance=.009):
    if tree is None:return
    for vertex in obj.data.vertices:
        center=Vector((0,.012,vertex.co.z));delta=vertex.co-center;delta.z=0
        if delta.length<.001:continue
        outward=delta.normalized()
        hit=tree.ray_cast(center+outward*.75,-outward,1.5)[0]
        if hit is not None:
            required=(hit-center).dot(outward)+clearance
            if delta.length<required:vertex.co+=outward*(required-delta.length)
    obj.data.update()


def tree_from(objects,predicate=lambda p:True):
    vertices=[];faces=[]
    for obj in objects:
        offset=len(vertices);vertices.extend(v.co.copy() for v in obj.data.vertices)
        faces.extend(tuple(offset+i for i in face.vertices) for face in obj.data.polygons if predicate(face.center))
    return BVHTree.FromPolygons(vertices,faces)


def ring_surface(name,rings,mat,n=64,theta=(-math.pi,math.pi),power=2,thickness=.003,bevel=.001,ridge=False,caps=False,fit=None):
    rings=curved_rings(rings,steps=3);vs=[];fs=[]
    closed=abs(theta[1]-theta[0]-math.tau)<.00001;cols=n if closed else n+1
    for z,rx,ry,cx,cy in rings:
        for j in range(cols):
            a=theta[0]+(theta[1]-theta[0])*j/n
            xx=math.copysign(abs(math.sin(a))**(2/power),math.sin(a))
            yy=math.copysign(abs(math.cos(a))**(2/power),math.cos(a))
            y=cy-ry*yy
            if ridge:y-=.006*max(0,math.cos(a))**10
            vs.append((cx+rx*xx,y,z))
    for i in range(len(rings)-1):
        for j in range(n):
            a=i*cols+j;b=i*cols+(j+1)%cols;fs.append((a,b,b+cols,a+cols))
    if caps:
        assert closed
        fs.append(tuple(reversed(range(cols))))
        fs.append(tuple((len(rings)-1)*cols+j for j in range(cols)))
    obj=mesh(name,vs,fs,mat)
    if fit:fit_radial(obj,fit)
    finish(obj,thickness,bevel)
    return obj


def band(name,center,axis,length,r0,r1,mat,sector=(-math.pi,math.pi),thick=.004):
    axis=Vector(axis).normalized();center=Vector(center)
    outward=Vector((1 if center.x>=0 else -1,0,0));outward=(outward-outward.dot(axis)*axis).normalized()
    across=axis.cross(outward).normalized();vs=[];fs=[];n=48
    closed=abs(sector[1]-sector[0]-math.tau)<.00001;cols=n if closed else n+1
    for t,r in [(0,r0),(length,r1)]:
        for j in range(cols):
            a=sector[0]+(sector[1]-sector[0])*j/n
            vs.append(tuple(center+axis*t+r*(outward*math.cos(a)+across*math.sin(a))))
    for j in range(n):fs.append((j,(j+1)%cols,(j+1)%cols+cols,j+cols))
    obj=mesh(name,vs,fs,mat);finish(obj,thick,.001)
    for which in (0,1):
        points=[vs[which*cols+i] for i in range(cols)]
        if closed:points.append(points[0])
        tube(name+'_rolled_edge_'+str(which),points,.0015,MATS['Steel_edge'] if mat==MATS['Steel'] else mat)
    return obj


def shoulder_crown(name,shoulder,axis):
    axis=Vector(axis).normalized();shoulder=Vector(shoulder)
    outward=Vector((1 if shoulder.x>0 else -1,0,0));outward=(outward-outward.dot(axis)*axis).normalized()
    across=axis.cross(outward).normalized();n,nr=48,6;radius=.094
    vs=[tuple(shoulder-axis*.051)];fs=[]
    for row in range(1,nr+1):
        r=radius*row/nr;depth=-.025-.026*(1-(r/radius)**2)
        for j in range(n):
            a=math.tau*j/n;vs.append(tuple(shoulder+axis*depth+r*(outward*math.cos(a)+across*math.sin(a))))
    for j in range(n):fs.append((0,1+(j+1)%n,1+j))
    for row in range(nr-1):
        for j in range(n):
            a=1+row*n+j;b=1+row*n+(j+1)%n;fs.append((a,b,b+n,a+n))
    finish(mesh(name,vs,fs,MATS['Steel']),.003,.001)


def build_cloth(scaffold):
    global TORSO_TREE,PANTS_TREE,CLOAK,CLOAK_HEM
    wrists={s:JOINTS['joint-'+('l' if s>0 else 'r')+'-hand'] for s in (-1,1)}
    dirs={s:(JOINTS['joint-'+('l' if s>0 else 'r')+'-hand-2']-wrists[s]).normalized() for s in (-1,1)}
    def top(p):
        if p.z<1.005 or p.z>1.57:return False
        # Cloth under the rigid gorget is omitted, like a normal game-outfit mask.
        if abs(p.x)<.205 and p.z>1.455:return False
        s=1 if p.x>0 else -1
        key='l' if s>0 else 'r';shoulder=JOINTS['joint-'+key+'-shoulder']
        axis=(JOINTS['joint-'+key+'-elbow']-shoulder).normalized()
        q=p-shoulder;t=q.dot(axis);radial=q-axis*t
        outward=Vector((s,0,0));outward=(outward-outward.dot(axis)*axis).normalized()
        if -.10<t<.14 and radial.length<.13 and (t<.015 or radial.dot(outward)>-.03):return False
        return abs(p.x)<.26 or (p-wrists[s]).dot(dirs[s])<-.012
    gambeson=finish(extract(scaffold,'Tailored_navy_gambeson_and_sleeves',top,MATS['Navy_cloth'],.012),.003)
    pants=extract(scaffold,'Anatomical_dark_trousers',lambda p:.345<p.z<1.065 and abs(p.x)<.28,MATS['Charcoal_cloth'],.009)
    for vertex in pants.data.vertices:
        p=vertex.co
        if p.z<.415:
            center=Vector((math.copysign(.14,p.x),.019,p.z));d=p-center
            radius=math.hypot(d.x/.047,d.y/.050)
            if radius>1:
                t=max(0,min(1,(.415-p.z)/.04));p.x=center.x+d.x*(1-t+t/radius);p.y=center.y+d.y*(1-t+t/radius)
    finish(pants,.003)
    collar=ring_surface('Standing_padded_collar',[(1.49,.087,.072,0,.007),(1.525,.078,.064,0,.007),(1.58,.072,.059,0,.007)],MATS['Navy_cloth'],n=48,thickness=.005)
    TORSO_TREE=tree_from([gambeson,pants,collar],lambda p:abs(p.x)<.25)
    PANTS_TREE=tree_from([pants])
    # Sewn skirt panels and actual hanging folds.
    for side in (-1,1):
        vs=[];fs=[];nu,nv=22,24
        for j in range(nv+1):
            t=j/nv;z=1.105-.47*t
            for i in range(nu+1):
                u=i/nu;a=side*(.12+u*(math.pi-.24))
                rx=.198+.055*t;ry=.14+.025*t
                fold=.010*math.sin(u*math.pi*5+.4)*(t**.7)
                vs.append(((rx+fold)*math.sin(a),.015-(ry+fold)*math.cos(a),z-.012*math.sin(u*math.pi)*t))
        for j in range(nv):
            for i in range(nu):
                a=j*(nu+1)+i;f=(a,a+1,a+nu+2,a+nu+1);fs.append(tuple(reversed(f)) if side>0 else f)
        skirt=mesh('Sewn_coat_skirt_'+str(side),vs,fs,MATS['Navy_cloth'])
        fit_radial(skirt,PANTS_TREE,.013)
        hem=[tuple(v.co) for v in list(skirt.data.vertices)[-(nu+1):]]
        finish(skirt,.004,.001)
        tube('Coat_hem_'+str(side),hem,.002,MATS['Cloth_seam'])
    # Gravity-led cloth drape behind the backplate.
    vs=[];fs=[];nu,nv=28,30
    for j in range(nv+1):
        t=j/nv
        for i in range(nu+1):
            u=i/nu;x=(u-.5)*2*(.19+.055*t)
            y=.17+.06*t+.020*math.sin(u*math.pi*7+.3)*t
            z=1.49-.64*t-.025*math.cos(u*math.pi*2)*t
            vs.append((x,y,z))
    for j in range(nv):
        for i in range(nu):
            a=j*(nu+1)+i;fs.append((a,a+1,a+nu+2,a+nu+1))
    CLOAK=mesh('Woven_half_cloak_with_real_folds',vs,fs,MATS['Cloak'])
    CLOAK_HEM=list(range(len(vs)-(nu+1),len(vs)))


def finish_cloak():
    tree=tree_from([o for o in PARTS if o.name.startswith(('Forged_curved_backplate','Raised_steel_gorget'))])
    for vertex in CLOAK.data.vertices:
        p=vertex.co
        if p.z>1.25:
            hit=tree.ray_cast(Vector((p.x,.8,p.z)),Vector((0,-1,0)))[0]
            if hit is not None:
                t=max(0,min(1,(p.z-1.25)/.24));t=t*t*(3-2*t)
                p.y=p.y*(1-t)+(hit.y+.007)*t
    hem=[tuple(CLOAK.data.vertices[i].co) for i in CLOAK_HEM]
    anchors=[CLOAK.data.vertices[i].co.copy() for i in (0,28)]
    finish(CLOAK,.003,.001)
    tube('Cloak_sewn_hem',hem,.002,MATS['Cloth_seam'])
    for i,point in enumerate(anchors):ball('Cloak_attachment_stud_'+str(i),point+Vector((0,.002,0)),.006,MATS['Brass'])


def build_armor():
    rings=[(1.145,.195,.164,0,.009),(1.22,.214,.176,0,.006),(1.34,.238,.18,0,.004),
           (1.415,.244,.174,0,.007),(1.47,.226,.159,0,.009)]
    front=ring_surface('Forged_curved_breastplate',rings,MATS['Steel'],theta=(-1.48,1.48),ridge=True,power=2.6)
    back=[(z,rx,ry*.80,cx,cy) for z,rx,ry,cx,cy in rings]
    ring_surface('Forged_curved_backplate',back,MATS['Steel'],theta=(math.pi-1.48,math.pi+1.48),power=2.6)
    ring_surface('Raised_steel_gorget',[(1.463,.227,.160,0,.009),(1.50,.184,.135,0,.009),(1.535,.115,.094,0,.009),(1.565,.084,.071,0,.009)],MATS['Steel'],n=56,power=2.6)
    for z,rx,ry in [(1.148,.196,.166),(1.082,.205,.174),(1.015,.216,.181)]:
        ring_surface('Articulated_fauld_'+str(z),[(z-.045,rx+.008,ry+.004,0,.012),(z+.018,rx,ry,0,.012)],MATS['Steel'],n=56,power=2.6)
    # Rolled lower/neck edges catch actual light, not a painted outline.
    front_tree=tree_from([front])
    for z,rx,ry in [(1.145,.195,.164),(1.47,.226,.159)]:
        pts=[]
        for j in range(65):
            a=-1.48+2.96*j/64;x=rx*math.copysign(abs(math.sin(a))**(2/2.6),math.sin(a))
            hit=front_tree.ray_cast(Vector((x,-.8,z+(.0001 if z<1.2 else -.0001))),Vector((0,1,0)))[0]
            pts.append((x,(hit.y-.001) if hit else .009-ry*math.copysign(abs(math.cos(a))**(2/2.6),math.cos(a)),z))
        tube('Cuirass_rolled_edge_'+str(z),pts,.002,MATS['Steel_edge'])
    for side in (-1,1):
        key='l' if side>0 else 'r';shoulder=JOINTS['joint-'+key+'-shoulder'];elbow=JOINTS['joint-'+key+'-elbow'];wrist=JOINTS['joint-'+key+'-hand']
        axis=(elbow-shoulder).normalized()
        shoulder_crown('Domed_shoulder_crown_'+key,shoulder,axis)
        for i in range(3):
            band('Shoulder_lame_'+key+'_'+str(i),shoulder+axis*(-.025+i*.052),axis,.091,.094-i*.004,.092-i*.005,MATS['Steel'],sector=(-1.7,1.7))
        fore=(wrist-elbow);length=fore.length;axis=fore.normalized()
        band('Fitted_forearm_bracer_'+key,elbow+fore*.44,axis,length*.53,.061,.046,MATS['Steel'])
        band('Leather_wrist_seal_'+key,wrist-axis*.025,axis,.046,.047,.040,MATS['Boot_leather'])
        for t in (.53,.88):band('Bracer_leather_closure_'+key+str(t),elbow+fore*t,axis,.016,.062-(t-.44)*.031,.062-(t-.44)*.031,MATS['Leather'])
    return front


def buckle(name,center,along,normal,width=.05,length=.055):
    normal=Vector(normal).normalized();along=Vector(along).normalized()
    across=along.cross(normal).normalized();along=normal.cross(across).normalized()
    center=Vector(center);frame=Matrix((across,along,normal)).transposed()
    for s in (-1,1):
        box(name+'_side_'+str(s),center+across*(s*width/2),(.003,length/2,.003),MATS['Brass'],frame)
        box(name+'_end_'+str(s),center+along*(s*length/2),(width/2,.003,.003),MATS['Brass'],frame)
    box(name+'_tongue',center+normal*.001,(.0015,length*.40,.002),MATS['Brass'],frame)


def build_leather(front):
    armor=[o for o in PARTS if o.name.startswith(('Forged_curved_breastplate','Articulated_fauld','Raised_steel_gorget'))]
    tree=tree_from(armor)
    start,end=Vector((-.130,0,1.447)),Vector((.169,0,1.113))
    direction=(end-start).normalized();across=Vector((-direction.z,0,direction.x))
    vs=[];fs=[];centers=[]
    for i in range(49):
        center=start.lerp(end,i/48);pair=[]
        for sign in (-1,1):
            point=center+across*sign*.020
            hit=tree.ray_cast(Vector((point.x,-.8,point.z)),Vector((0,1,0)))[0]
            assert hit is not None,'harness point outside breastplate: '+str(tuple(point))
            point.y=hit.y-.006;pair.append(point);vs.append(tuple(point))
        centers.append((pair[0]+pair[1])/2)
    for i in range(48):a=i*2;fs.append((a,a+2,a+3,a+1))
    finish(mesh('Physical_diagonal_leather_harness',vs,fs,MATS['Leather']),.004,.0007)
    for side in (0,1):tube('Harness_sewn_edge_'+str(side),[vs[i*2+side] for i in range(49)],.0008,MATS['Leather_edge'])
    buckle('Harness_buckle',centers[21]+Vector((0,-.007,0)),direction,(0,-1,0))
    # Belt wraps the actual lower cuirass/upper fauld.
    belt=ring_surface('Thick_waist_leather_belt',[(1.075,.201,.165,0,.012),(1.117,.199,.161,0,.012)],MATS['Leather'],n=80,thickness=.006,bevel=.001,fit=tree)
    belt_hit=tree_from([belt]).ray_cast(Vector((0,-.8,1.096)),Vector((0,1,0)))[0]
    assert belt_hit is not None
    buckle('Waist_buckle',belt_hit+Vector((0,-.006,0)),(1,0,0),(0,-1,0),width=.047,length=.060)
    # Rivets and leather suspension are real geometry.
    for side in (-1,1):
        for z in (1.22,1.35,1.42):
            x=side*(.18 if z<1.4 else .15);hit=tree.ray_cast(Vector((x,-.8,z)),Vector((0,1,0)))[0]
            if hit:ball('Steel_fastener_'+str(side)+'_'+str(z),hit+Vector((0,-.002,0)),.0035,MATS['Brass'])
    return belt


def build_boots_and_gloves():
    with bpy.data.libraries.load(str(OLD/'02_warden.blend'),link=False) as (src,dst):
        dst.objects=[n for n in src.objects if n.startswith('SOURCE_') and ('Closed_anatomical_glove' in n or 'Fitted_boot' in n)]
    old_objects=[o for o in dst.objects if o]
    old_boots=[o for o in old_objects if 'Fitted_boot' in o.name]
    METRICS['boots_before']={o.name:[[min(v.co[k] for v in o.data.vertices),max(v.co[k] for v in o.data.vertices)] for k in range(3)] for o in old_boots}
    for side in (-1,1):
        key='l' if side>0 else 'r';x=side*.14;y=.00764
        rings=[(.012,.057,.121,x,y-.045),(.027,.058,.124,x,y-.045),(.055,.057,.121,x,y-.045),
               (.085,.054,.111,x,y-.038),(.123,.048,.078,x,y-.020),(.18,.046,.052,x,y),
               (.27,.052,.057,x,y+.009),(.375,.058,.060,x,y+.012)]
        boot=ring_surface('Smaller_fitted_boot_'+key,rings,MATS['Boot_leather'],n=64,power=2.4,thickness=.005,bevel=.001)
        # Close toe/sole from an actual lower outsole volume.
        sole=ring_surface('Layered_boot_sole_'+key,[(.008,.058,.124,x,y-.045),(.028,.059,.125,x,y-.045)],MATS['Sole'],n=64,power=2.4,thickness=0,bevel=.001,caps=True)
        ring_surface('Boot_top_cuff_'+key,[(.35,.064,.066,x,y+.011),(.379,.064,.066,x,y+.012)],MATS['Leather_edge'],n=48,power=2.4,thickness=.004)
        dense=curved_rings(rings,steps=3);strap_rings=[]
        for z in (.137,.155):
            vals=[interpolate(z,[(r[0],r[column]) for r in dense]) for column in range(1,5)]
            vals[0]+=.006;vals[1]+=.006;strap_rings.append((z,*vals))
        ring_surface('Boot_ankle_strap_'+key,strap_rings,MATS['Leather'],n=48,power=2.4,thickness=.003)
        boot_tree=tree_from([boot]);toe=[]
        for a in [-1.35+2.7*i/40 for i in range(41)]:
            point=Vector((x+.056*math.sin(a),y-.04-.117*math.cos(a),.073))
            center=Vector((x,y-.04,.073));outward=(point-center).normalized()
            location,normal,_,_=boot_tree.ray_cast(center+outward*.5,-outward)
            assert location is not None
            toe.append(tuple(location+normal*.0014))
        tube('Boot_toe_stitch_'+key,toe,.001,MATS['Leather_edge'])
        buckle('Boot_buckle_'+key,(x+side*.052,y-.025,.148),(0,0,1),(side,0,0),width=.020,length=.025)
        METRICS.setdefault('boots_after',{})[boot.name]=[[min(v.co[k] for v in boot.data.vertices),max(v.co[k] for v in boot.data.vertices)] for k in range(3)]
        source=min([o for o in old_objects if 'Closed_anatomical_glove' in o.name],key=lambda o:abs(sum(v.co.x for v in o.data.vertices)/len(o.data.vertices)-side*.4))
        data=source.data.copy();glove=bpy.data.objects.new('Leather_closed_glove_'+key,data);bpy.context.collection.objects.link(glove)
        coords=[v.co for v in data.vertices];center=Vector([(min(v[k] for v in coords)+max(v[k] for v in coords))/2 for k in range(3)])
        wrist=JOINTS['joint-'+key+'-hand'];direction=(JOINTS['joint-'+key+'-hand-2']-wrist).normalized()
        rotation=Vector((0,0,-1)).rotation_difference(direction)
        for vertex in data.vertices:vertex.co=wrist+direction*.047+rotation@((vertex.co-center)*.88)
        data.materials.clear();data.materials.append(MATS['Boot_leather'])
        for face in data.polygons:face.material_index=0
        PARTS.append(glove)
    for obj in old_objects:bpy.data.objects.remove(obj,do_unlink=True)


def render(name,yaw=330,ortho=2.7,size=800,target=(0,0,.94),elevation=18):
    G.camera(yaw,ortho=ortho,size=size,target=target,elevation=elevation)
    bpy.context.scene.render.filepath=str(OUT/'renders'/(name+'.png'));bpy.ops.render.render(write_still=True)


def bake_costume():
    source=bpy.data.collections.new('SOURCE - separate modelled outfit parts');bpy.context.scene.collection.children.link(source)
    for obj in PARTS:
        copy=obj.copy();copy.data=obj.data.copy();copy.name='SOURCE_'+obj.name;source.objects.link(copy)
    source.hide_render=True;source.hide_viewport=True
    active(PARTS[0])
    for obj in PARTS:obj.select_set(True)
    bpy.ops.object.join();actor=bpy.context.object;actor.name='Warden_modelled_outfit'
    for layer in list(actor.data.uv_layers):actor.data.uv_layers.remove(layer)
    actor.data.uv_layers.new(name='OutfitAtlas')
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=1.1,island_margin=.003);bpy.ops.object.mode_set(mode='OBJECT')
    maps={};scene=bpy.context.scene;scene.cycles.samples=1;scene.render.bake.margin=12
    for role,socket in [('albedo','Base Color'),('roughness','Roughness'),('metallic','Metallic')]:
        image=bpy.data.images.new('Warden_outfit_'+role,2048,2048,alpha=False)
        if role!='albedo':image.colorspace_settings.name='Non-Color'
        restore=[]
        for mat in actor.data.materials:
            ns,ls=mat.node_tree.nodes,mat.node_tree.links
            bs=next(n for n in ns if n.type=='BSDF_PRINCIPLED');out=next(n for n in ns if n.type=='OUTPUT_MATERIAL')
            old=out.inputs['Surface'].links[0].from_socket;emit=ns.new('ShaderNodeEmission')
            if bs.inputs[socket].is_linked:ls.new(bs.inputs[socket].links[0].from_socket,emit.inputs[0])
            else:
                value=bs.inputs[socket].default_value
                emit.inputs[0].default_value=tuple(value) if socket=='Base Color' else (value,value,value,1)
            ls.new(emit.outputs[0],out.inputs[0]);node=ns.new('ShaderNodeTexImage');node.image=image;ns.active=node
            restore.append((mat,out,old,emit,node))
        bpy.ops.object.bake(type='EMIT')
        path=OUT/'textures'/('warden_outfit_'+role+'.png');image.filepath_raw=str(path);image.file_format='PNG';image.save()
        for mat,out,old,emit,node in restore:
            mat.node_tree.links.new(old,out.inputs[0]);mat.node_tree.nodes.remove(emit);mat.node_tree.nodes.remove(node)
        maps[role]=image
    mat=bpy.data.materials.new('Portable_true_volume_outfit_PBR');mat.use_nodes=True
    bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    for role,socket in [('albedo','Base Color'),('roughness','Roughness'),('metallic','Metallic')]:
        node=mat.node_tree.nodes.new('ShaderNodeTexImage');node.image=maps[role];mat.node_tree.links.new(node.outputs[0],bs.inputs[socket])
    actor.data.materials.clear();actor.data.materials.append(mat)
    for face in actor.data.polygons:face.material_index=0
    scene.cycles.samples=24
    return actor,source


def main():
    args=argparse.ArgumentParser();args.add_argument('--quick',action='store_true')
    options=args.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    ref=json.loads((OUT/'reference.json').read_text())
    assert ref['status']=='READY_FOR_STATIC_PILOT' and sha(BEFORE/'delivery.json')==ref['baseline_delivery_sha256']
    for directory in ('textures','renders'):(OUT/directory).mkdir(exist_ok=True)
    G.setup_scene();bpy.context.scene.render.threads=6
    material('Steel',(.17,.205,.245),.65,.88,.22);material('Steel_edge',(.22,.25,.29),.50,.9,.08)
    material('Navy_cloth',(.025,.036,.063),.88,0,.14);material('Charcoal_cloth',(.027,.024,.023),.9,0,.13)
    material('Cloak',(.022,.032,.057),.91,0,.15);material('Cloth_seam',(.033,.043,.067),.85,0,.06)
    material('Leather',(.055,.026,.013),.72,0,.20);material('Boot_leather',(.045,.025,.016),.77,0,.18)
    material('Leather_edge',(.09,.045,.024),.72,0,.08);material('Sole',(.018,.012,.009),.9,0,.10)
    material('Brass',(.27,.17,.065),.45,.8,.06)
    scaffold=load_body();build_cloth(scaffold);front=build_armor();finish_cloak();build_leather(front);build_boots_and_gloves()
    gate=AUDIT.deliverable(PARTS+HEAD,profile='render')
    (OUT/'source-audit.json').write_text(json.dumps(gate,indent=2)+'\n')
    assert gate['pass'],gate['errors']
    render('quick_body' if options.quick else 'source_body',size=800)
    render('quick_front' if options.quick else 'source_front',yaw=0,size=800)
    if options.quick:
        bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'artifacts/warden-outfit-work.blend'))
        (ROOT/'artifacts/warden-outfit-metrics.json').write_text(json.dumps(METRICS,indent=2)+'\n')
        print('WARDEN_OUTFIT_QUICK_PASS '+str(len(PARTS))+' actual outfit parts');return
    actor,source=bake_costume()
    for name,yaw in [('front',0),('three_quarter',330),('side',90),('rear',180)]:render(name,yaw=yaw,size=900)
    render('face',ortho=.64,size=900,target=(0,-.01,1.65),elevation=5)
    render('belt',ortho=.63,size=900,target=(0,-.05,1.29),elevation=8)
    render('boots',ortho=.83,size=900,target=(0,-.02,.29),elevation=12)
    render('tactical',ortho=3.84,size=384)
    lights=[(o,o.location.copy(),o.data.color[:]) for o in bpy.context.scene.objects if o.type=='LIGHT']
    for obj,_,_ in lights:obj.location.x*=-1;obj.data.color=(1,1,1)
    render('changed_light',ortho=.8,size=900,target=(0,-.03,1.42),elevation=8)
    for obj,loc,col in lights:obj.location=loc;obj.data.color=col
    original=list(actor.data.materials);gray=bpy.data.materials.new('DIAGNOSTIC_neutral_geometry');gray.use_nodes=True
    bs=next(n for n in gray.node_tree.nodes if n.type=='BSDF_PRINCIPLED');bs.inputs['Base Color'].default_value=(.3,.3,.3,1);bs.inputs['Roughness'].default_value=.6
    actor.data.materials[0]=gray
    render('geometry_body',size=900);render('geometry_belt',ortho=.63,size=900,target=(0,-.05,1.29),elevation=8)
    actor.data.materials[0]=original[0]
    G.camera(330,ortho=2.7,size=900,target=(0,0,.94))
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [actor]+HEAD:obj.select_set(True)
    bpy.context.view_layer.objects.active=actor
    bpy.ops.export_scene.fbx(filepath=str(OUT/'warden_outfit.fbx'),use_selection=True,object_types={'MESH'},bake_anim=False,path_mode='RELATIVE',axis_forward='-Z',axis_up='Y',add_leaf_bones=False)
    for image in bpy.data.images:
        if image.name not in ('Render Result','Viewer Node') and image.size[0]>0:image.pack()
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'warden_outfit.blend'))
    (OUT/'measurements.json').write_text(json.dumps(METRICS,indent=2)+'\n')
    result=dict(schema='sdd.warden-modelled-outfit-v1',static=True,rigged=False,animated=False,integrated=False,
        parts=[dict(name=o.name,triangles=sum(len(f.vertices)-2 for f in o.data.polygons)) for o in [actor]+HEAD],
        source_parts=len(source.objects),head_source=str(BEFORE.relative_to(ROOT)),head_source_sha256=sha(BEFORE/'mpfb_warden.blend'),
        method='coherent MPFB rest stance; authored physical armor/harness/cloth; three portable PBR maps; exact retained face meshes/UV',
        camera=dict(elevation=18,yaw=330,ortho=2.7,tactical_pixels_per_metre=100),
        limits=['static outfit prototype, no deformation proof','source procedural materials baked to portable UV maps','future cast needs distinct head recipes'],
        files={p.relative_to(OUT).as_posix():sha(p) for p in OUT.rglob('*') if p.is_file() and (p.name in ('warden_outfit.blend','warden_outfit.fbx') or p.parent==OUT/'textures' or (p.parent==OUT/'renders' and not p.name.startswith(('quick','fbx_','before_'))))})
    (OUT/'model.json').write_text(json.dumps(result,indent=2)+'\n')
    print('WARDEN_OUTFIT_BUILD_PASS '+str(sum(p['triangles'] for p in result['parts']))+' triangles')


if __name__=='__main__':main()
