"""Independent, static anatomical character studies. Never writes runtime art.

Blender --background --factory-startup --python this_file -- --style a
The CC0 scaffold download is documented in the accompanying research notes.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import random
import sys

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'assets_src/characters/style_studies/2026-11-02'
CACHE = Path.home() / '.codex/tools/character-art/base-meshes/unpacked'
LIB = next(CACHE.rglob('human_base_meshes_bundle.blend'))
STYLES = {
    'a': dict(id='a_painterly_veteran', title='A / Malarski weteran', base='realistic',
              width=1.04, head=1.06, blue=(.045,.13,.19), leather=(.13,.057,.027),
              steel=(.28,.34,.36), trim=(.48,.31,.12), skin=(.44,.25,.15), rough=.63),
    'b': dict(id='b_ink_warden', title='B / Mroczny komiks', base='realistic',
              width=.97, head=1.16, blue=(.027,.085,.115), leather=(.085,.039,.023),
              steel=(.28,.34,.34), trim=(.59,.42,.18), skin=(.54,.33,.19), rough=.85),
    'c': dict(id='c_heroic_miniature', title='C / Malowana figurka', base='stylized',
              width=1.16, head=1.0, blue=(.025,.16,.24), leather=(.19,.072,.027),
              steel=(.24,.37,.42), trim=(.60,.36,.09), skin=(.53,.28,.145), rough=.78),
}
P = None
PARTS = []
MATS = {}


def mesh(name, vertices, faces, mat, smooth=True):
    data=bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    obj=bpy.data.objects.new(name,data)
    bpy.context.collection.objects.link(obj)
    if mat: data.materials.append(mat)
    for poly in data.polygons: poly.use_smooth=smooth
    PARTS.append(obj)
    return obj


def activate(obj):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active=obj


def finish(obj, bevel=0, sub=0):
    activate(obj)
    if bevel:
        mod=obj.modifiers.new('Rounded handmade edges','BEVEL')
        mod.width=bevel; mod.segments=2
        bpy.ops.object.modifier_apply(modifier=mod.name)
    if sub:
        mod=obj.modifiers.new('Form smoothing','SUBSURF');mod.levels=sub
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def material(name, color, kind='cloth', metallic=0):
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    ns,ls=mat.node_tree.nodes,mat.node_tree.links
    bs=next(n for n in ns if n.type=='BSDF_PRINCIPLED')
    bs.inputs['Base Color'].default_value=(*color,1)
    bs.inputs['Roughness'].default_value=P['rough'] if kind=='steel' else .86
    bs.inputs['Metallic'].default_value=metallic
    tex=ns.new('ShaderNodeTexCoord')
    noise=ns.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=24 if kind=='steel' else 11
    noise.inputs['Detail'].default_value=2
    mapping=ns.new('ShaderNodeVectorMath');mapping.operation='MULTIPLY'
    mapping.inputs[1].default_value=(4,4,.65) if kind=='steel' else (1,2,5)
    ls.new(tex.outputs['Generated'],mapping.inputs[0]);ls.new(mapping.outputs[0],noise.inputs['Vector'])
    ramp=ns.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].position=.18;ramp.color_ramp.elements[1].position=.82
    low,high=(.96,1.04) if kind in ('skin','hair') else (.85,1.12)
    ramp.color_ramp.elements[0].color=(*[v*low for v in color],1)
    ramp.color_ramp.elements[1].color=(*[min(1,v*high+.005) for v in color],1)
    ls.new(noise.outputs['Fac'],ramp.inputs[0]);ls.new(ramp.outputs[0],bs.inputs['Base Color'])
    if kind in ('cloth','leather'):
        bump=ns.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.11;bump.inputs['Distance'].default_value=.007
        ls.new(noise.outputs['Fac'],bump.inputs['Height']);ls.new(bump.outputs[0],bs.inputs['Normal'])
    if P['key']=='b':
        # Explicit graphic shadow shapes in object space. Bakeable base colour;
        # render-only hulls add contours without contaminating portable meshes.
        geo=ns.new('ShaderNodeTexCoord');sep=ns.new('ShaderNodeVectorMath');sep.operation='DOT_PRODUCT'
        sep.inputs[1].default_value=(-.4,-.7,.6);ls.new(geo.outputs['Normal'],sep.inputs[0])
        steps=ns.new('ShaderNodeValToRGB');steps.color_ramp.interpolation='CONSTANT'
        steps.color_ramp.elements[0].position=.10;steps.color_ramp.elements[0].color=(.16,.20,.25,1)
        steps.color_ramp.elements[1].position=.28;steps.color_ramp.elements[1].color=(.65,.70,.72,1)
        steps.color_ramp.elements.new(.65).color=(1.1,1.05,.95,1)
        mix=ns.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=.94
        ls.new(ramp.outputs[0],mix.inputs[1]);ls.new(steps.outputs[0],mix.inputs[2]);ls.new(sep.outputs['Value'],steps.inputs[0])
        ls.new(mix.outputs[0],bs.inputs['Base Color'])
        wave=ns.new('ShaderNodeTexWave');wave.wave_type='BANDS';wave.bands_direction='DIAGONAL'
        wave.inputs['Scale'].default_value=36;wave.inputs['Distortion'].default_value=0
        ls.new(tex.outputs['Generated'],wave.inputs['Vector'])
        line=ns.new('ShaderNodeMath');line.operation='GREATER_THAN';line.inputs[1].default_value=.10
        ls.new(wave.outputs['Fac'],line.inputs[0])
        hatch=ns.new('ShaderNodeMixRGB');hatch.blend_type='MULTIPLY';hatch.inputs[0].default_value=.16
        ls.new(mix.outputs[0],hatch.inputs[1]);ls.new(line.outputs[0],hatch.inputs[2]);ls.new(hatch.outputs[0],bs.inputs['Base Color'])
        cel=ns.new('ShaderNodeEmission');ls.new(hatch.outputs[0],cel.inputs[0])
        out=next(n for n in ns if n.type=='OUTPUT_MATERIAL');ls.new(cel.outputs[0],out.inputs['Surface'])
    MATS[name]=mat
    return mat


def sphere(name, center, radius, mat, segments=24, rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=center)
    obj=bpy.context.object;obj.name=name;obj.scale=radius
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    obj.data.materials.append(mat)
    for f in obj.data.polygons:f.use_smooth=True
    PARTS.append(obj)
    return obj


def sweep(name, centers, radii, mat, segments=10, flatten=1, sub=1):
    verts=[];faces=[]
    for i,(pt,r) in enumerate(zip(centers,radii)):
        tangent=Vector(centers[min(i+1,len(centers)-1)])-Vector(centers[max(0,i-1)])
        tangent.normalize();ref=Vector((0,1,0))
        if abs(tangent.dot(ref))>.9:ref=Vector((1,0,0))
        u=tangent.cross(ref).normalized();v=tangent.cross(u).normalized()
        for j in range(segments):
            t=j*math.tau/segments
            verts.append(Vector(pt)+r*(math.cos(t)*u+math.sin(t)*v*flatten))
    for i in range(len(centers)-1):
        for j in range(segments):
            a=i*segments+j;b=i*segments+(j+1)%segments
            faces.append((a,b,b+segments,a+segments))
    faces.append(tuple(reversed(range(segments))))
    faces.append(tuple((len(centers)-1)*segments+j for j in range(segments)))
    return finish(mesh(name,verts,faces,mat),sub=sub)


def tube(name, points, radius, mat):
    # Seam/trim geometry, attached along modelled cloth/metal surfaces.
    return sweep(name,points,[radius]*len(points),mat,6,sub=0)


def loft(name, rings, mat, n=32, folds=0, sub=1, phase=0):
    verts=[];faces=[]
    for z,rx,ry,cx,cy in rings:
        for j in range(n):
            t=math.tau*j/n
            wave=1+folds*(math.cos(t*9+z*6+phase)+.3*math.sin(t*15-z*9))
            verts.append((cx+rx*math.cos(t)*wave,cy+ry*math.sin(t)*wave,z))
    for i in range(len(rings)-1):
        for j in range(n):
            a=i*n+j;b=i*n+(j+1)%n
            faces.append((a,b,b+n,a+n))
    obj=mesh(name,verts,faces,mat)
    finish(obj,sub=sub)
    mod=obj.modifiers.new('Real cloth thickness','SOLIDIFY');mod.thickness=.008
    activate(obj);bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def plate(name, outline, center, mat, thickness=.018, bevel=.007):
    # Raised centre with a rolled perimeter, rather than stacked flat cubes.
    vs=[tuple(p) for p in outline]+[tuple(center)]
    fs=[(i,(i+1)%len(outline),len(outline)) for i in range(len(outline))]
    ob=mesh(name,vs,fs,mat,smooth=False)
    mod=ob.modifiers.new('Forged plate thickness','SOLIDIFY');mod.thickness=thickness
    activate(ob);bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(ob,bevel=bevel)


def load_body():
    name='GEO-body_male_'+P['base']
    with bpy.data.libraries.load(str(LIB),link=False) as (src,dst):
        dst.objects=[n for n in src.objects if n==name or n.startswith(name+'.eye.')]
    objects=[o for o in dst.objects if o]
    for ob in objects:bpy.context.collection.objects.link(ob)
    bpy.context.view_layer.update()
    body=next(o for o in objects if o.name==name)
    factor=1.8/max(v.co.z for v in body.data.vertices)
    neck=1.48 if P['base']=='realistic' else 1.39
    def transform(p):
        p=Vector(p)*factor
        z=p.z
        if z>neck:
            p.x*=P['head'];p.y*=P['head']
        else:
            p.x*=P['width']
        # Weight on rear left leg; spread boots without breaking knee continuity.
        if z<.87 and abs(p.x)<.28:
            p.x+=math.copysign(.036*max(0,1-z/.87),p.x)
            p.y+=math.copysign(.022*max(0,1-z/.87),p.x)
        p.z+=.0059
        return p
    # The asset library displays models on a grid. Remove that presentation
    # translation, including it only relatively for parented eyeballs.
    inverse_body=body.matrix_world.inverted()
    matrices={ob:inverse_body@ob.matrix_world for ob in objects}
    for ob in objects:
        world=matrices[ob]
        ob.parent=None;ob.matrix_world.identity()
        for mod in list(ob.modifiers):ob.modifiers.remove(mod)
        for v in ob.data.vertices:v.co=transform(world@v.co)
        ob.data.materials.clear()
    body.name='CC0_AnatomicalScaffold_'+P['base']
    body.data.materials.append(MATS['Skin'])
    # Only expose face/neck; all covered torso/legs are removed from render/export.
    vs=[v.co.copy() for v in body.data.vertices]
    faces=[]
    for f in body.data.polygons:
        p=sum((vs[i] for i in f.vertices),Vector())/len(f.vertices)
        if p.z>neck+.050 and (p.z>neck+.09 or abs(p.x)<.112*P['head']):
            faces.append(list(f.vertices))
    head=mesh('Face_and_neck_CC0_derived',vs,faces,MATS['Skin'])
    finish(head,sub=1)
    for ob in objects:
        if ob==body:continue
        ob.name='Anatomical_eye_'+ob.name[-1];ob.data.materials.append(MATS['Eye'])
        # Existing concave cornea/iris topology; colour central front iris.
        ob.data.materials.append(MATS['Iris']);ob.data.materials.append(MATS['Pupil'])
        coords=[v.co for v in ob.data.vertices];center=sum(coords,Vector())/len(coords)
        rad=max(v.z for v in coords)-min(v.z for v in coords)
        for f in ob.data.polygons:
            p=sum((coords[i] for i in f.vertices),Vector())/len(f.vertices)
            r=math.hypot(p.x-center.x,p.z-center.z)
            if p.y<center.y-rad*.28 and r<rad*.25:f.material_index=1
            if p.y<center.y-rad*.32 and r<rad*.12:f.material_index=2
        for f in ob.data.polygons:f.use_smooth=True
        PARTS.append(ob)
    bpy.data.objects.remove(body,do_unlink=True)
    return vs,neck


def shell(name, coords, predicate, offset, mat, fold=0):
    # Rebuild from the actual scaffold surface, retaining anatomical joint forms.
    # Original topology is loaded separately to keep selection stable.
    base='GEO-body_male_'+P['base']
    with bpy.data.libraries.load(str(LIB),link=False) as (src,dst):dst.meshes=[base]
    # Object mesh datablock names differ; derive indexed faces from object append.
    if not dst.meshes or dst.meshes[0] is None:
        with bpy.data.libraries.load(str(LIB),link=False) as (src,dst):dst.objects=[base]
        source=dst.objects[0];polys=[tuple(f.vertices) for f in source.data.polygons]
        bpy.data.objects.remove(source,do_unlink=True)
    else:polys=[tuple(f.vertices) for f in dst.meshes[0].polygons]
    selected=[]
    for face in polys:
        c=sum((coords[i] for i in face),Vector())/len(face)
        if predicate(c):selected.append(face)
    obj=mesh(name,coords,selected,mat)
    # Remove loose vertices before normal offsets, exporting only the real piece.
    activate(obj);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.delete_loose();bpy.ops.object.mode_set(mode='OBJECT')
    normals=[v.normal.copy() for v in obj.data.vertices]
    for v,normal in zip(obj.data.vertices,normals):
        p=v.co;v.co+=normal*offset
        if fold:
            p.x+=fold*math.sin(p.z*55+p.y*13)*abs(normal.x)
            p.y+=fold*math.sin(p.z*39+p.x*31)*abs(normal.y)
    finish(obj,sub=1)
    mod=obj.modifiers.new('Tailored thickness','SOLIDIFY');mod.thickness=.006
    activate(obj);bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def costume(coords, neck):
    w=P['width'];c=P['key'];hero=c=='c'
    shell('Loose wool trousers',coords,lambda p:.40<p.z<.75 and abs(p.x)<.31,.018,MATS['DarkCloth'],.003)
    shell('Quilted undercoat sleeves',coords,lambda p:1.035<p.z<1.60 and abs(p.x)>.20*w,.018,MATS['Linen'],.002)
    loft('Folded shoulder mantle and fitted neckline',[(1.36,.245*w,.145,0,0),(1.40,.26*w,.15,0,0),
         (min(1.44,neck+.015),.205*w,.132,0,0),(neck+.04,.11,.095,0,0),(neck+.065,.09,.085,0,0)],MATS['Blue'],folds=.018)
    for s in [-1,1]:
        x=s*(.17*w+.023)
        loft('Turned leather boot',[(.014,.082,.16,x,-.025),(.030,.086,.162,x,-.025),(.065,.087,.16,x,-.025),
             (.105,.085,.14,x,-.005),(.16,.080,.105,x,.045),(.23,.086,.105,x,.05),
             (.34,.092,.105,x,.05),(.41,.088,.103,x,.045)],MATS['Leather'],n=32,sub=1)
        loft('Stitched leather sole',[(.014,.085,.163,x,-.025),(.022,.089,.165,x,-.025),(.038,.089,.165,x,-.025)],MATS['DarkCloth'],n=32)
    # Tall tailored, panelled gambeson; chest tapers into a gathered waist.
    loft('Quilted gambeson skirt',[(.72,.23*w,.155,0,0),(.75,.23*w,.155,0,0),(.90,.195*w,.15,0,0),
         (.99,.17*w,.145,0,0),(1.10,.19*w,.16,0,0),(1.26,.23*w,.18,0,0),
         (1.38,.24*w,.165,0,0),(1.42,.22*w,.13,0,0)],MATS['Blue'],folds=.018,n=48)
    # Vertical quilt seams follow the curved front instead of independent tubes.
    for x in [-.165,-.11,-.055,0,.055,.11,.165]:
        pts=[]
        for j in range(14):
            z=.75+j*.047;r=.23 if z<.9 else .19 if z<1.17 else .23
            ry=.155 if z<.99 else .16 if z<1.17 else .18
            y=-ry*math.sqrt(max(.05,1-(x/(r*w))**2))-.005
            pts.append((x*w,y,z))
        tube('Gambeson stitched channel',pts,.0019,MATS['BlueLight'])
    # Front leather/steel lamellar corslet and upper chest, three distinct designs.
    if c=='a':
        for row in range(4):
            z=1.025+row*.085
            for col in range(7):
                x=(col-3)*.047*w;y=-.187*math.sqrt(max(.1,1-(x/(.235*w))**2))-.012
                plate('Overlapping brigandine scale',[(x-.024,y,z),(x+.024,y,z),(x+.024,y-.006,z+.073),(x-.024,y-.006,z+.073)],
                      (x,y-.003,z+.038),MATS['Leather'],.01,.004)
                sphere('Brigandine brass rivet',(x,y-.009,z+.058),(.0035,.0025,.0035),MATS['Trim'],12,6)
    else:
        chest=[(-.21*w,-.13,1.35),(-.14*w,-.18,1.40),(0,-.19,1.35),(.14*w,-.18,1.40),(.21*w,-.13,1.35),
               (.16*w,-.17,1.04),(0,-.19,1.005),(-.16*w,-.17,1.04)]
        plate('Peaked heraldic breastplate',chest,(0,-.225,1.23),MATS['Steel'],.022,.009)
        tube('Breastplate rolled brass edge',chest+[chest[0]],.006 if hero else .004,MATS['Trim'])
        for s in [-1,1]:
            tube('Raised cuirass ridge',[(s*.14*w,-.15,1.34),(s*.08*w,-.205,1.22),(0,-.217,1.16)],.004,MATS['SteelLight'])
    # Leather waist belt, buckle, attached pouches, sword scabbard.
    loft('Waist belt',[(.968,.194*w,.153,0,0),(.973,.194*w,.153,0,0),(1.02,.19*w,.15,0,0),(1.026,.19*w,.15,0,0)],MATS['Leather'],sub=1)
    tube('Forged rectangular buckle',[(-.033,-.168,.975),(.033,-.168,.975),(.033,-.168,1.022),(-.033,-.168,1.022),(-.033,-.168,.975)],.005,MATS['Trim'])
    tube('Buckle tongue',[(0,-.174,.98),(0,-.174,1.018)],.003,MATS['Trim'])
    for i in range(4):sphere('Belt punched hole',(.055+i*.022,-.15,1),(.0023,.0015,.0023),MATS['Ink'],8,4)
    for s in [-1,1]:
        x=s*.19*w
        pouch=sphere('Belt utility pouch',(x,-.08,.92),(.055,.061,.072),MATS['Leather'])
        tube('Pouch flap seam',[(x-.044,-.129,.95),(x,-.15,.926),(x+.044,-.129,.95)],.003,MATS['Trim'])
        sphere('Pouch fastening',(x,-.145,.922),(.006,.004,.006),MATS['Trim'],12,6)
    # Boots get opening cuffs, straps and knees with legible material transitions.
    for s in [-1,1]:
        x=s*(.17*w+.023)
        for z in [.27,.39]:
            loft('Boot collar and strap',[(z-.012,.095,.110,x,.05),(z-.006,.101,.117,x,.05),(z+.013,.098,.113,x,.05)],MATS['LeatherLight'],n=24)
        tube('Boot front stitching',[(x,-.058,.39),(x,-.063,.29),(x,-.063,.19),(x,-.14,.095)],.0018,MATS['LeatherLight'])
        knee=(s*.135*w,-.078,.54)
        plate('Knee guard',[(knee[0]-.06,-.08,.57),(knee[0],-.12,.62),(knee[0]+.06,-.08,.57),(knee[0]+.045,-.10,.50),(knee[0],-.125,.48),(knee[0]-.045,-.10,.50)],
              (knee[0],-.15,.55),MATS['Steel'],.012,.005)
    # Individual shoulder plates: laminated/round for A,C, serrated for B.
    for s in [-1,1]:
        if c=='a' and s==-1:continue
        for layer in range(3):
            x=s*(.23*w+layer*.021);z=1.405-layer*.043
            outline=[(x-s*.10,-.10,z+.04),(x+s*.04,-.12,z+.042),(x+s*.105,-.045,z-.018),
                     (x+s*.09,.07,z-.045),(x-s*.08,.075,z+.012)]
            plate('Articulated shoulder lame',outline,(x+s*.025,-.018,z+.072),MATS['Steel'],.013,.008)
            tube('Shoulder brass hem',outline+[outline[0]],.0035 if c!='c' else .006,MATS['Trim'])
    # Cape is an actual pleated, flowing surface, split asymmetrically at hem.
    verts=[];faces=[];nu,nv=32,30
    for i in range(nv+1):
        t=i/nv;z=1.43-.98*t
        width=(.20+.14*math.sin(t*2))*w
        for j in range(nu+1):
            u=j/nu*2-1
            x=u*width+.055*t*t
            y=.102+.065*math.sin(t*2)+.06*t+.033*math.cos(u*math.pi*4)*math.sin(t*math.pi/2)
            zz=z+.045*abs(u)**2*t-.06*math.sin(u*math.pi*2+.4)*t**8
            if c=='b':zz-=.13*(1-abs(u))*t**8
            verts.append((x,y,zz))
    for i in range(nv):
        for j in range(nu):
            a=i*(nu+1)+j;faces.append((a,a+1,a+nu+2,a+nu+1))
    cape=mesh('Weighted wool cape with sculpted folds',verts,faces,MATS['Blue'])
    mod=cape.modifiers.new('Wool thickness','SOLIDIFY');mod.thickness=.012
    activate(cape);bpy.ops.object.modifier_apply(modifier=mod.name)
    # Strong diagonal cloak lapel keeps the head free rather than hiding it.
    scarf=[(-.235*w,-.025,1.45),(-.08,-.13,1.46),(.105,-.14,1.44),(.22*w,-.01,1.39)]
    sweep('Folded cloak collar',scarf,[.045,.045,.033,.022],MATS['BlueLight'],12,flatten=.55)
    sphere('Cloak brooch',(.14,-.148,1.425),(.024,.010,.024),MATS['Trim'])
    sphere('Brooch inset stone',(.14,-.159,1.425),(.012,.004,.012),MATS['Blue'],16,8)


def hair_face(neck):
    head=next(o for o in PARTS if o.name.startswith('Face_and_neck'))
    maxz=max(v.co.z for v in head.data.vertices)
    # Anatomically fitted scalp cap preserves the sculpted forehead/ears.
    coords=[v.co.copy() for v in head.data.vertices];faces=[]
    for f in head.data.polygons:
        p=sum((coords[i] for i in f.vertices),Vector())/len(f.vertices)
        if p.z>maxz-.058 or (p.y>.025 and p.z>maxz-.19) or (abs(p.x)>.082*P['head'] and p.z>maxz-.11 and p.y>-.055):
            faces.append(tuple(f.vertices))
    scalp=mesh('Fitted swept hair cap',coords,faces,MATS['Hair'])
    normals=[v.normal.copy() for v in scalp.data.vertices]
    for v,normal in zip(scalp.data.vertices,normals):v.co+=normal*.010
    mod=scalp.modifiers.new('Hair cap thickness','SOLIDIFY');mod.thickness=.006
    activate(scalp);bpy.ops.object.modifier_apply(modifier=mod.name)
    # Carved chunky locks overlap the cap and taper naturally, not spiky spheres.
    c=P['key'];top=maxz+.013;hs=P['head']*(1.22 if P['base']=='stylized' else 1)
    for i in range(6):
        x=(i-2.5)*.030*hs;z=top-.025*(x/(.10*hs))**2
        sweep('Swept sculpted hair lock',[(x-.025,.012,z-.025),(x-.012,-.055,z+.013),(x+.025,-.113,z-.033),(x+.044,-.140,z-.078)],
              [.025,.030,.028,.0025],MATS['HairLight'] if i%3==0 else MATS['Hair'],10,flatten=.25)
    # Chin/beard follows jaw silhouette and has visible directional clumps.
    eyes=[o for o in PARTS if o.name.startswith('Anatomical_eye')]
    eyez=sum(sum(v.co.z for v in o.data.vertices)/len(o.data.vertices) for o in eyes)/len(eyes)
    lip=eyez-(.064 if P['base']=='realistic' else .10)
    # Beard is sculpted from the anatomical jaw itself. A planar beard mask
    # incorrectly bridges the lips/chin in profile, even when the front is neat.
    beard_vs=[v.co.copy() for v in head.data.vertices];beard_fs=[]
    head_normals=[v.normal.copy() for v in head.data.vertices]
    for f in head.data.polygons:
        p=sum((beard_vs[i] for i in f.vertices),Vector())/len(f.vertices)
        upper=lip-.005+.055*min(1,abs(p.x)/(.085*hs))**1.4
        if lip-.060<p.z<upper and p.y<-.055 and abs(p.x)<.11*hs:
            beard_fs.append(tuple(f.vertices))
    for i,p in enumerate(beard_vs):
        length=.006+.010*max(0,min(1,(lip-p.z)/.08))
        beard_vs[i]=p+head_normals[i]*length
    beard=mesh('Sculpted beard fitted to anatomical jaw',beard_vs,beard_fs,MATS['Hair'])
    mod=beard.modifiers.new('Beard volume','SOLIDIFY');mod.thickness=.005
    activate(beard);bpy.ops.object.modifier_apply(modifier=mod.name)
    def project_front(x,z,offset=.005):
        hit,loc,normal,_=head.ray_cast(Vector((x,-1,z)),Vector((0,1,0)))
        return loc+normal*offset if hit else Vector((x,-.16*hs,z))
    # Moustache and brows; locate eyes from appended anatomical objects.
    for eye in eyes:
        center=sum((v.co for v in eye.data.vertices),Vector())/len(eye.data.vertices)
        front=min(v.co.y for v in eye.data.vertices)
        s=1 if center.x>0 else -1
        ir=.016 if c=='c' else .0065
        sphere('Clearly defined iris',(center.x,front-.001,center.z),(ir,.0022,ir),MATS['Iris'],24,12)
        sphere('Dark pupil',(center.x,front-.003,center.z),(ir*.47,.0015,ir*.47),MATS['Pupil'],20,10)
        sphere('Small eye catchlight',(center.x-ir*.25,front-.004,center.z+ir*.28),(ir*.15,.0008,ir*.15),MATS['Eye'],12,6)
        tube('Defined expressive brow',[project_front(center.x-s*.029,center.z+.031),
              project_front(center.x,center.z+.043),project_front(center.x+s*.027,center.z+.036)],.008 if c=='c' else .005,MATS['Hair'])
    # Short brushed moustache uses the face's real lip position, not a painted smile.
    for s in [-1,1]:
        sweep('Moustache',[project_front(s*.004,lip+.020),project_front(s*.026,lip+.012),project_front(s*.047,lip-.003)],
              [.006,.008,.002],MATS['Hair'],8,flatten=.6)


def hands_weapons():
    w=P['width'];hero=P['key']=='c'
    # Anatomical scaffold arms stop at the cuffs. Sculpted gloves close around
    # separate handles; four articulated fingers and a visible opposing thumb.
    for s in [-1,1]:
        wrist=Vector((s*.385*w,-.025,1.020));palm=wrist+Vector((s*.006,-.035,-.061))
        sphere('Leather glove palm',palm,(.040,.034,.056),MATS['Leather'])
        loft('Rolled glove cuff',[(1.02,.052,.049,wrist.x,wrist.y),(1.026,.055,.052,wrist.x,wrist.y),(1.075,.061,.055,wrist.x,wrist.y)],MATS['LeatherLight'],n=24)
        for i in range(4):
            z=.992-i*.017
            sweep('Curled articulated glove finger',[(palm.x-s*.024,-.072,z),(palm.x+s*.014,-.086,z-.003),
                 (palm.x+s*.037,-.059,z-.007),(palm.x+s*.022,-.035,z-.010)],
                 [.009,.010,.009,.006],MATS['LeatherLight'],8,sub=1)
        sweep('Opposing glove thumb',[(palm.x-s*.032,-.038,1.015),(palm.x-s*.045,-.067,.993),(palm.x-s*.014,-.088,.977)],
              [.014,.012,.008],MATS['Leather'],8)
        # Fitted layered forearm vambrace above the opening.
        plate('Forearm fitted vambrace',[(s*.36*w,-.067,1.12),(s*.433*w,-.046,1.10),
              (s*.46*w,-.039,.99),(s*.385*w,-.075,.985)],(s*.411*w,-.095,1.052),MATS['Steel'],.012,.006)
    # Right hand sword: hilt below guard, blade points diagonally down/out.
    grip=Vector((-.391*w,-.055,.968));axis=Vector((-.31,-.025,-.95)).normalized()
    # Make blade on the upper-hand continuation away from the pommel.
    start=grip-axis*.058;tip=start+axis*.70
    u=Vector((axis.z,0,-axis.x)).normalized();v=Vector((0,1,0))
    sweep('Wrapped sword handle',[grip-axis*.07,grip+axis*.07],[.014,.014],MATS['Leather'],12,sub=0)
    for j in range(8):
        at=grip+axis*(-.06+j*.016)
        tube('Spiral handle binding',[at+u*.014,at+v*.014,at-u*.014,at-v*.014,at+u*.014],.0015,MATS['LeatherLight'])
    guard=grip+axis*.086
    sweep('Curved forged crossguard',[guard-u*.10+axis*.014,guard-u*.06,guard,guard+u*.06,guard+u*.10+axis*.014],
          [.009,.011,.012,.011,.009],MATS['Trim'],8,sub=1)
    sphere('Faceted sword pommel',grip-axis*.09,(.023,.018,.023),MATS['Trim'],12,6)
    root=guard+axis*.012;tip=root+axis*(.66 if not hero else .72)
    width=.026 if not hero else .037
    mid=root+axis*.50
    verts=[root-u*width,root+u*width,root-v*.008,root+v*.008,
           mid-u*width*.75,mid+u*width*.75,mid-v*.007,mid+v*.007,tip]
    fs=[(0,4,6,2),(2,6,5,1),(1,5,7,3),(3,7,4,0),(4,8,6),(6,8,5),(5,8,7),(7,8,4),(0,2,1,3)]
    mesh('Diamond cross section steel sword',verts,fs,MATS['SteelLight'],False)
    # Round shield hangs from the opposite fist with a real rear grip/brace.
    center=Vector((.41*w,-.12,.97));radius=.235 if not hero else .28
    normal=Vector((.20,-.98,.035)).normalized();ux=Vector((.98,.2,0)).normalized();uz=normal.cross(ux).normalized()
    def sp(x,z,depth=0):return center+ux*x+uz*z+normal*depth
    verts=[sp(0,0,.038)];n=64
    for dep,r in [(.012,radius),(0,radius),(-.036,radius*.98)]:
        for j in range(n):verts.append(sp(math.cos(j*math.tau/n)*r,math.sin(j*math.tau/n)*r,dep))
    fs=[]
    for j in range(n):
        k=(j+1)%n;fs.extend([(0,1+j,1+k),(1+j,1+n+j,1+n+k,1+k),(1+n+j,1+2*n+j,1+2*n+k,1+n+k)])
    shield=mesh('Curved wooden round shield',verts,fs,MATS['ShieldBlue'])
    for frac,rr in [(1,.011),(.90,.004)]:
        tube('Rolled shield rim',[sp(math.cos(j*math.tau/n)*radius*frac,math.sin(j*math.tau/n)*radius*frac,.017) for j in range(n+1)],rr,MATS['Trim'])
    boss=sphere('Forged shield boss',sp(0,0,.039),(.065,.023,.065),MATS['Steel'])
    for j in range(12):
        t=j*math.tau/12
        sphere('Shield rim rivet',sp(math.cos(t)*radius*.95,math.sin(t)*radius*.95,.027),(.0045,.004,.0045),MATS['SteelLight'],10,5)
    for x in [-.14,-.07,.07,.14]:
        hh=math.sqrt(max(0,(radius*.88)**2-x*x))
        tube('Shield plank seam',[sp(x,-hh,.019),sp(x,hh,.019)],.0017,MATS['Blue'])
    # Own simple heraldic northern-star emblem, physical relief for readable views.
    for sign in [-1,1]:
        plate('Shield heraldic ray',[sp(-.026,sign*.068,.032),sp(0,sign*(radius*.79),.023),sp(.026,sign*.068,.032)],sp(0,sign*.10,.037),MATS['Trim'],.002,.001)
    sweep('Rear shield handgrip',[sp(-.065,0,-.08),sp(0,0,-.09),sp(.065,0,-.08)],[.011,.012,.011],MATS['Leather'],10,sub=1)


def camera(yaw, ortho=2.8, size=768, elevation=18, target=(0,0,.94)):
    sc=bpy.context.scene;cam=sc.camera;t=Vector(target)
    a=math.radians(yaw);e=math.radians(elevation)
    cam.location=t+Vector((math.sin(a)*math.cos(e),-math.cos(a)*math.cos(e),math.sin(e)))*7
    cam.rotation_euler=(t-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.type='ORTHO';cam.data.ortho_scale=ortho
    sc.render.resolution_x=size;sc.render.resolution_y=size;sc.render.resolution_percentage=100


def setup_scene():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=24;sc.cycles.use_denoising=True;sc.render.threads_mode='FIXED';sc.render.threads=8
    sc.render.film_transparent=True;sc.render.image_settings.file_format='PNG';sc.render.image_settings.color_mode='RGBA'
    sc.view_settings.view_transform='Khronos PBR Neutral';sc.view_settings.exposure=0;sc.view_settings.gamma=1
    sc.world.color=(.18,.18,.18)
    for name,loc,power,size,col in [('Key',(-3,-4,6),450,4,(1,.87,.74)),('Fill',(3,-2,3),220,3,(.70,.82,1)),('Rim',(1,3,4),500,3,(.80,.89,1))]:
        data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size;data.color=col
        ob=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(ob);ob.location=loc
        ob.rotation_euler=(Vector((0,0,1))-ob.location).to_track_quat('-Z','Y').to_euler()
    data=bpy.data.cameras.new('Matched orthographic study camera');ob=bpy.data.objects.new('Study camera',data);bpy.context.collection.objects.link(ob);sc.camera=ob


def uv_and_bake(folder):
    # UV and emission-only colour bake: portable FBX colour without fake highlights.
    for ob in PARTS:
        activate(ob)
        if not ob.data.uv_layers:
            bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
            bpy.ops.uv.smart_project(angle_limit=1.15,island_margin=.008);bpy.ops.object.mode_set(mode='OBJECT')
    source_collection=bpy.data.collections.new('AUTHORING - separate costume, face, hair and gear')
    bpy.context.scene.collection.children.link(source_collection)
    source_collection.hide_render=True;source_collection.hide_viewport=True
    for ob in PARTS:
        copy=ob.copy();copy.data=ob.data.copy();copy.name='SOURCE_'+ob.name
        source_collection.objects.link(copy)
    bpy.ops.object.select_all(action='DESELECT')
    for ob in PARTS:ob.select_set(True)
    bpy.context.view_layer.objects.active=PARTS[0]
    bpy.ops.object.join();actor=bpy.context.object;actor.name=P['id']+'_static_study'
    # Pack a fresh atlas across all pieces rather than overlapping retained UVs.
    activate(actor);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=1.05,island_margin=.003);bpy.ops.object.mode_set(mode='OBJECT')
    image=bpy.data.images.new(P['id']+'_albedo',2048,2048,alpha=True)
    outputs=[]
    for mat in actor.data.materials:
        if not mat:continue
        ns,ls=mat.node_tree.nodes,mat.node_tree.links
        bs=next(n for n in ns if n.type=='BSDF_PRINCIPLED');out=next(n for n in ns if n.type=='OUTPUT_MATERIAL')
        source=bs.inputs['Base Color'].links[0].from_socket if bs.inputs['Base Color'].is_linked else None
        emission=ns.new('ShaderNodeEmission')
        if source:ls.new(source,emission.inputs[0])
        else:emission.inputs[0].default_value=bs.inputs['Base Color'].default_value
        ls.new(emission.outputs[0],out.inputs['Surface'])
        tex=ns.new('ShaderNodeTexImage');tex.image=image;ns.active=tex
        # The temporary bake emission was linked above. Retain the authored
        # shader explicitly: B has its own graphic emission, A/C principled.
        authored=next((n.outputs[0] for n in ns if n.type=='EMISSION' and n!=emission),bs.outputs[0])
        outputs.append((mat,out,authored,emission))
    sc=bpy.context.scene;sc.cycles.samples=1;sc.render.bake.margin=12
    bpy.ops.object.bake(type='EMIT')
    image.filepath_raw=str(folder/'textures'/f"{P['id']}_albedo.png");image.file_format='PNG';image.save()
    for mat,out,authored,emission in outputs:
        mat.node_tree.links.new(authored,out.inputs['Surface']);mat.node_tree.nodes.remove(emission)
    sc.cycles.samples=24
    # Preserve rich .blend authoring materials; create an export-only portable copy.
    portable=actor.copy();portable.data=actor.data.copy();bpy.context.collection.objects.link(portable)
    portable.name=P['id']+'_portable'
    for i,source in enumerate(list(portable.data.materials)):
        mat=bpy.data.materials.new('Portable_'+source.name);mat.use_nodes=True
        bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
        tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
        mat.node_tree.links.new(tex.outputs[0],bs.inputs['Base Color'])
        old=next(n for n in source.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
        bs.inputs['Roughness'].default_value=old.inputs['Roughness'].default_value
        bs.inputs['Metallic'].default_value=old.inputs['Metallic'].default_value
        portable.data.materials[i]=mat
    activate(portable)
    bpy.ops.export_scene.fbx(filepath=str(folder/f"{P['id']}.fbx"),use_selection=True,object_types={'MESH'},
                             bake_anim=False,add_leaf_bones=False,path_mode='RELATIVE',axis_forward='-Z',axis_up='Y')
    bpy.data.objects.remove(portable,do_unlink=True)
    return actor,image


def add_ink_hull(actor):
    mat=bpy.data.materials.new('RENDER_ONLY_Backface_Ink');mat.use_nodes=True
    ns,ls=mat.node_tree.nodes,mat.node_tree.links;ns.clear()
    out=ns.new('ShaderNodeOutputMaterial');geo=ns.new('ShaderNodeNewGeometry')
    ink=ns.new('ShaderNodeEmission');ink.inputs[0].default_value=(.008,.012,.016,1)
    trans=ns.new('ShaderNodeBsdfTransparent');mix=ns.new('ShaderNodeMixShader')
    ls.new(geo.outputs['Backfacing'],mix.inputs[0]);ls.new(trans.outputs[0],mix.inputs[1]);ls.new(ink.outputs[0],mix.inputs[2]);ls.new(mix.outputs[0],out.inputs[0])
    hull=actor.copy();hull.data=actor.data.copy();bpy.context.collection.objects.link(hull);hull.name='RENDER_ONLY_ink_contours'
    hull.visible_shadow=False;hull.visible_diffuse=False;hull.visible_glossy=False
    hull.visible_transmission=False;hull.visible_volume_scatter=False
    hull.data.materials.clear();hull.data.materials.append(mat)
    for p in hull.data.polygons:p.material_index=0
    normals=[v.normal.copy() for v in hull.data.vertices]
    for v,normal in zip(hull.data.vertices,normals):v.co+=normal*.0022
    return hull


def main():
    global P
    args=argparse.ArgumentParser();args.add_argument('--style',choices=STYLES,required=True);args.add_argument('--quick',action='store_true')
    opts=args.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    P=dict(STYLES[opts.style],key=opts.style)
    folder=DEST/P['id'];(folder/'textures').mkdir(parents=True,exist_ok=True);(folder/'renders').mkdir(exist_ok=True)
    setup_scene()
    for name,color,kind,metal in [('Skin',P['skin'],'skin',0),('Blue',P['blue'],'cloth',0),
        ('BlueLight',tuple(v*1.35 for v in P['blue']),'cloth',0),('DarkCloth',(.04,.048,.047),'cloth',0),
        ('Linen',(.19,.20,.18),'cloth',0),('Leather',P['leather'],'leather',0),
        ('LeatherLight',tuple(v*1.4 for v in P['leather']),'leather',0),('Steel',P['steel'],'steel',.62),
        ('SteelLight',tuple(min(.9,v*1.55) for v in P['steel']),'steel',.66),('Trim',P['trim'],'steel',.55),
        ('Hair',(.068,.025,.014),'hair',0),('HairLight',(.13,.048,.020),'hair',0),
        ('Eye',(.38,.34,.25),'skin',0),('Iris',(.10,.13,.09),'skin',0),('Pupil',(.006,.008,.008),'skin',0),
        ('Ink',(.008,.011,.014),'cloth',0),('ShieldBlue',tuple(v*.8 for v in P['blue']),'leather',0)]:
        material(name,color,kind,metal)
    coords,neck=load_body();costume(coords,neck);hair_face(neck);hands_weapons()
    # Remove loose scaffold points retained by a head-only polygon selection.
    for ob in PARTS:
        activate(ob);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.delete_loose();bpy.ops.object.mode_set(mode='OBJECT')
    if opts.quick:
        camera(330,size=768);bpy.context.scene.render.filepath=str(folder/'renders/quick.png');bpy.ops.render.render(write_still=True)
        camera(0,ortho=.73,size=768,elevation=5,target=(0,-.015,1.57));bpy.context.scene.render.filepath=str(folder/'renders/quick_face.png');bpy.ops.render.render(write_still=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(folder/f"{P['id']}_work.blend"))
        return
    actor,albedo=uv_and_bake(folder)
    hull=add_ink_hull(actor) if opts.style=='b' else None
    views={'front':0,'three_quarter':330,'side':90,'rear':180}
    for name,yaw in views.items():
        camera(yaw,size=900);bpy.context.scene.render.filepath=str(folder/'renders'/f'{name}.png');bpy.ops.render.render(write_still=True)
    camera(340,ortho=.70,size=900,elevation=5,target=(0,-.015,1.59));bpy.context.scene.render.filepath=str(folder/'renders/face.png');bpy.ops.render.render(write_still=True)
    camera(330,ortho=3.84,size=384,elevation=18,target=(0,0,.94));bpy.context.scene.render.filepath=str(folder/'renders/tactical_100ppm.png');bpy.ops.render.render(write_still=True)
    camera(330,size=900)
    albedo.pack();bpy.ops.wm.save_as_mainfile(filepath=str(folder/f"{P['id']}.blend"))
    points=[actor.matrix_world@v.co for v in actor.data.vertices]
    result=dict(id=P['id'],title=P['title'],scaffold=P['base'],base_library_sha256=hashlib.sha256(LIB.read_bytes()).hexdigest(),
                static=True,rigged=False,animated=False,integrated=False,vertices=len(actor.data.vertices),triangles=sum(len(f.vertices)-2 for f in actor.data.polygons),
                bounds=[[min(p[i] for p in points),max(p[i] for p in points)] for i in range(3)],
                camera=dict(elevation=18,three_quarter_yaw=330,close_ortho=2.8,tactical_ortho=3.84,tactical_pixels=384,pixels_per_meter=100),
                render_only_ink_hull=bool(hull),authoring_materials='procedural directional brush variation; baked albedo in portable FBX',
                files={str(p.relative_to(folder)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(folder.rglob('*')) if p.is_file() and p.suffix in ('.blend','.fbx','.png') and 'quick' not in p.name and '_work' not in p.name})
    (folder/'model.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print('STYLE_STUDY='+json.dumps(result))


if __name__=='__main__':main()
