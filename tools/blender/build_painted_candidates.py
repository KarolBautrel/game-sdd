"""Reference-guided static3D candidates. Original AI-painted design maps, CC0 anatomy.

No production character writes. A model render is never replaced by a concept.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
import bmesh
from mathutils import Vector, Matrix

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'assets_src/characters/painted_candidates/2026-11-02'
SKILLS=Path.home()/'.codex/skills'
for n in ['expert','sculpting','hard-surface','texturing-shading']:
    sys.path.insert(0,str(SKILLS/('scenario-blender-'+n)/'scripts'))
import bx_sculpt as S
import bx_audit as AUDIT
import bx_review as REVIEW
import bx_hardsurface as HS
import bx_materials as M
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_style_studies as G

LIB=next((Path.home()/'.codex/tools/character-art/base-meshes/unpacked').rglob('human_base_meshes_bundle.blend'))
PROFILES={
 '01_mercenary':dict(title='I / Najemnik',width=1.,baseline=997,ppm=530,front=279,side=746,back=1258,hem=.68,cape=.49,plate=False),
 '02_warden':dict(title='II / Straznik',width=1.025,baseline=1002,ppm=534,front=285,side=748,back=1249,hem=.64,cape=.93,plate=True),
 '03_wayfarer':dict(title='III / Wedrowiec',width=.99,baseline=994,ppm=532,front=290,side=746,back=1249,hem=.45,cape=.60,plate=False),
}
P={};PARTS=[];FOLDER=None;PAINT=None;SOLIDS={};PAINTS={}


def activate(ob):G.activate(ob)


def mesh(name,verts,faces,mat=None,smooth=True):
    ob=G.mesh(name,verts,faces,mat or PAINT,smooth)
    PARTS.append(ob)
    return ob


def closed_loft(name,rings,n=32,power=2.,fold=0.,mat=None):
    vs=[];fs=[]
    for z,rx,ry,cx,cy in rings:
        for j in range(n):
            t=j*math.tau/n
            x=math.copysign(abs(math.cos(t))**(2/power),math.cos(t))
            y=math.copysign(abs(math.sin(t))**(2/power),math.sin(t))
            d=fold*math.sin(7*t+z*9)*math.sin(math.pi*(z-rings[0][0])/max(.001,rings[-1][0]-rings[0][0]))
            vs.append((cx+(rx+d)*x,cy+(ry+d)*y,z))
    for i in range(len(rings)-1):
        for j in range(n):
            a=i*n+j;b=i*n+(j+1)%n;fs.append((a,b,b+n,a+n))
    fs.append(tuple(reversed(range(n))));fs.append(tuple((len(rings)-1)*n+j for j in range(n)))
    ob=mesh(name,vs,fs,mat)
    ob.data.polygons[-1].use_smooth=False;ob.data.polygons[-2].use_smooth=False
    return ob


def solid_material(name,color,rough=.8,metal=0,light_response=.25):
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    ns,ls=mat.node_tree.nodes,mat.node_tree.links
    bs=next(n for n in ns if n.type=='BSDF_PRINCIPLED')
    bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=rough;bs.inputs['Metallic'].default_value=metal
    col=M.painted_light(mat,top=1.09,bottom=.72,crevice=.10,highlight=.025)
    em=ns.new('ShaderNodeEmission');ls.new(col,em.inputs[0])
    dif=ns.new('ShaderNodeBsdfDiffuse');ls.new(col,dif.inputs[0])
    mix=ns.new('ShaderNodeMixShader');mix.inputs[0].default_value=light_response
    ls.new(em.outputs[0],mix.inputs[1]);ls.new(dif.outputs[0],mix.inputs[2])
    out=next(n for n in ns if n.type=='OUTPUT_MATERIAL');ls.new(mix.outputs[0],out.inputs[0])
    SOLIDS[name]=mat
    return mat


def forged_box(name,center,half,material):
    bpy.ops.mesh.primitive_cube_add(size=2,location=center)
    ob=bpy.context.object;ob.name=name;ob.scale=half
    HS.apply_scale(ob);ob.data.materials.append(material)
    HS.hard_surface_stack(ob,micro_width=.0015,micro_segments=2,angle=38)
    PARTS.append(ob)
    return ob


def projection_material(label='Body',fallback=(.055,.035,.025),use_side=False):
    mat=bpy.data.materials.new('Painted_reference_'+label);mat.use_nodes=True
    ns,ls=mat.node_tree.nodes,mat.node_tree.links;ns.clear()
    geo=ns.new('ShaderNodeNewGeometry');sep=ns.new('ShaderNodeSeparateXYZ');ls.new(geo.outputs['Normal'],sep.inputs[0])
    def mathnode(op,a,b=None):
        node=ns.new('ShaderNodeMath');node.operation=op
        if isinstance(a,(float,int)):node.inputs[0].default_value=a
        else:ls.new(a,node.inputs[0])
        if b is not None:
            if isinstance(b,(float,int)):node.inputs[1].default_value=b
            else:ls.new(b,node.inputs[1])
        return node.outputs[0]
    sy=sep.outputs['Y'];sx=sep.outputs['X']
    fw=mathnode('ADD',mathnode('POWER',mathnode('MAXIMUM',mathnode('MULTIPLY',sy,-1),0),6),.0001)
    bw=mathnode('ADD',mathnode('POWER',mathnode('MAXIMUM',sy,0),6),.0001)
    sw=mathnode('MULTIPLY',mathnode('POWER',mathnode('ABSOLUTE',sx),6),1 if use_side else 0)
    if label=='Cloak':
        fw=mathnode('MULTIPLY',fw,0);bw=mathnode('ADD',fw,1);sw=mathnode('MULTIPLY',sw,0)
    denom=mathnode('MAXIMUM',mathnode('ADD',mathnode('ADD',fw,bw),sw),.0001)
    outputs=[]
    image=bpy.data.images.load(str(FOLDER/'projection-padded.png'),check_existing=True)
    for key,weight in [('front',fw),('back',bw),('side',sw)]:
        uv=ns.new('ShaderNodeUVMap');uv.uv_map='Reference_'+key
        tex=ns.new('ShaderNodeTexImage');tex.image=image;tex.extension='EXTEND';tex.interpolation='Linear'
        ls.new(uv.outputs[0],tex.inputs[0])
        # Aseprite supplies a connected-background matte and 48px paint bleed.
        # Colour thresholds in the shader damaged highlights in the earlier pass.
        valid=ns.new('ShaderNodeMixRGB');ls.new(tex.outputs['Alpha'],valid.inputs[0]);valid.inputs[1].default_value=(*fallback,1);ls.new(tex.outputs[0],valid.inputs[2])
        mix=ns.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1
        ls.new(valid.outputs[0],mix.inputs[1]);ls.new(mathnode('DIVIDE',weight,denom),mix.inputs[2]);outputs.append(mix.outputs[0])
    a=ns.new('ShaderNodeMixRGB');a.blend_type='ADD';a.inputs[0].default_value=1;ls.new(outputs[0],a.inputs[1]);ls.new(outputs[1],a.inputs[2])
    b=ns.new('ShaderNodeMixRGB');b.blend_type='ADD';b.inputs[0].default_value=1;ls.new(a.outputs[0],b.inputs[1]);ls.new(outputs[2],b.inputs[2])
    paint_color=b.outputs[0]
    if label=='Cloak':
        lum=ns.new('ShaderNodeRGBToBW');ls.new(paint_color,lum.inputs[0])
        tone=ns.new('ShaderNodeMapRange');tone.clamp=True
        ls.new(lum.outputs[0],tone.inputs[0]);tone.inputs['From Max'].default_value=.22
        tone.inputs['To Min'].default_value=.42;tone.inputs['To Max'].default_value=1.32
        tint=ns.new('ShaderNodeMixRGB');tint.blend_type='MULTIPLY';tint.inputs[0].default_value=1
        tint.inputs[1].default_value=(.045,.072,.115,1);ls.new(tone.outputs[0],tint.inputs[2]);paint_color=tint.outputs[0]
    if label=='Head':
        pos=ns.new('ShaderNodeSeparateXYZ');ls.new(geo.outputs['Position'],pos.inputs[0])
        ramp=ns.new('ShaderNodeMapRange');ramp.clamp=True
        ls.new(pos.outputs['Z'],ramp.inputs['Value']);ramp.inputs['From Min'].default_value=1.550;ramp.inputs['From Max'].default_value=1.590
        neck=ns.new('ShaderNodeMixRGB');ls.new(ramp.outputs[0],neck.inputs[0]);neck.inputs[1].default_value=(.19,.12,.075,1);ls.new(paint_color,neck.inputs[2]);paint_color=neck.outputs[0]
    # Paint already carries designed highlights/shadows, like the selected diffuse
    # reference technique. Only a small additional light response describes depth.
    em=ns.new('ShaderNodeEmission');ls.new(paint_color,em.inputs[0])
    dif=ns.new('ShaderNodeBsdfDiffuse');ls.new(paint_color,dif.inputs[0]);dif.inputs['Roughness'].default_value=.8
    shader=ns.new('ShaderNodeMixShader');shader.inputs[0].default_value=.65 if label=='Cloak' else .12
    if label=='Head':
        response=ns.new('ShaderNodeMapRange');response.clamp=True
        ls.new(pos.outputs['Z'],response.inputs[0]);response.inputs['From Min'].default_value=1.56;response.inputs['From Max'].default_value=1.60
        response.inputs['To Min'].default_value=.65;response.inputs['To Max'].default_value=.12
        ls.new(response.outputs[0],shader.inputs[0])
    ls.new(em.outputs[0],shader.inputs[1]);ls.new(dif.outputs[0],shader.inputs[2])
    out=ns.new('ShaderNodeOutputMaterial');ls.new(shader.outputs[0],out.inputs[0])
    return mat


def load_scaffold():
    name='GEO-body_male_realistic'
    with bpy.data.libraries.load(str(LIB),link=False) as (src,dst):
        dst.objects=[n for n in src.objects if n==name or n.startswith(name+'.eye.')]
    obs=[o for o in dst.objects if o]
    for o in obs:bpy.context.collection.objects.link(o)
    bpy.context.view_layer.update()
    body=next(o for o in obs if o.name==name)
    inv=body.matrix_world.inverted();factor=1.84/max(v.co.z for v in body.data.vertices)
    matrices={o:inv@o.matrix_world for o in obs}
    for o in obs:
        world=matrices[o];o.parent=None;o.matrix_world=Matrix.Identity(4)
        for mod in list(o.modifiers):o.modifiers.remove(mod)
        for v in o.data.vertices:
            p=(world@v.co)*factor
            if p.z>1.58:p.x*=.90;p.y=p.y*.80+.025
            else:p.x*=P['width']
            v.co=p
        o.data.materials.clear();o.data.materials.append(PAINT)
    vs=[v.co.copy() for v in body.data.vertices];fs=[tuple(f.vertices) for f in body.data.polygons]
    for o in obs:
        if o!=body:
            o.name='CC0_Anatomical_eye_'+o.name[-1];o.data.materials[0]=PAINTS['Head'];PARTS.append(o)
            for f in o.data.polygons:f.use_smooth=True
    bpy.data.objects.remove(body,do_unlink=True)
    return vs,fs


def extract(name,vs,fs,predicate,offset=0,inflate=0):
    selected=[f for f in fs if predicate(sum((vs[i] for i in f),Vector())/len(f))]
    ob=mesh(name,vs,selected)
    activate(ob);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.delete_loose();bpy.ops.object.mode_set(mode='OBJECT')
    normals=[v.normal.copy() for v in ob.data.vertices]
    for v,n in zip(ob.data.vertices,normals):
        v.co+=n*offset
        if inflate and .43<v.co.z<.75:
            # Small compressed cloth folds above boot/knee; not uniform noise.
            v.co+=n*(inflate*math.sin((v.co.z-.43)*65)*math.sin((v.co.z-.43)/.32*math.pi)**2)
    return ob


def make_body():
    vs,fs=load_scaffold()
    head=extract('CC0_derived_anatomical_face_and_neck',vs,fs,lambda p:p.z>1.50 and (p.z>1.61 or abs(p.x)<.145))
    head.data.materials[0]=PAINTS['Head']
    # A continuous cut replaces the ragged centroid-selected neck edge.
    bm=bmesh.new();bm.from_mesh(head.data)
    bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,
                         plane_co=(0,0,1.540),plane_no=(0,0,1),clear_inner=True)
    bm.to_mesh(head.data);bm.free()
    # Fit the lower anatomical neck inside the existing shirt opening. The CC0
    # scaffold's trapezius must not stick through that collar as a jagged skirt.
    for v in head.data.vertices:
        if v.co.z<1.602:
            influence=min(1,max(0,(1.602-v.co.z)/.025))
            p=v.co.copy();r=math.sqrt((p.x/.057)**2+((p.y-.012)/.044)**2)
            if r>1:
                target=Vector((p.x/r,.012+(p.y-.012)/r,p.z))
                v.co=v.co.lerp(target,influence)
    sc=S.Sculptor(head,symmetry_x=True)
    sc.plane_cut((.067,-.073,1.67),(.7,-.6,.12),radius=.075,hardness=.25,max_move=.004,strength=.4)
    sc.commit()
    sleeves=extract('Tailored_sleeves_from_anatomy',vs,fs,lambda p:.997<p.z<1.61 and abs(p.x)>.19*P['width'],.018)
    for v in sleeves.data.vertices:
        if v.co.z<1.50:v.co.z=1.50+(v.co.z-1.50)*1.14
    pants=extract('Trouser_anatomy_and_compression_folds',vs,fs,lambda p:.34<p.z<.85 and abs(p.x)<.30,.013,.006)
    pants.data.materials[0]=PAINTS['Dark']
    for v in pants.data.vertices:
        cx=math.copysign(.17*P['width'],v.co.x)
        v.co.x=cx+(v.co.x-cx)*.86;v.co.y*=.82
        if v.co.z>.68:
            r=math.sqrt((v.co.x/(.19*P['width']))**2+(v.co.y/.13)**2)
            if r>1:
                blend=min(1,(v.co.z-.68)/.045)
                v.co.x*=1-blend+blend/r;v.co.y*=1-blend+blend/r
    w=P['width']
    core=closed_loft('Fitted_gambeson_core',[(.77,.20*w,.145,0,0),(1.02,.178*w,.13,0,0),(1.14,.183*w,.14,0,0),
        (1.30,.217*w,.16,0,0),(1.43,.235*w,.155,0,0),(1.49,.215*w,.13,0,0),(1.54,.098,.08,0,0),(1.58,.073,.065,0,0)],fold=.003)
    for v in core.data.vertices:
        factor=.92+.08*min(1,max(0,(v.co.z-1.43)/.06))
        v.co.x*=factor;v.co.y*=factor
    # The shirt collar is the fitted continuation of the core. An open neckline
    # avoids a full cap cutting through the anatomical neck.
    bm=bmesh.new();bm.from_mesh(core.data);bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm,geom=[bm.faces[-1]],context='FACES_ONLY');bm.to_mesh(core.data);bm.free()
    core.data.materials.append(SOLIDS['Collar'])
    for poly in core.data.polygons:
        if sum(core.data.vertices[i].co.z for i in poly.vertices)/len(poly.vertices)>1.55:poly.material_index=1
    # Split coat is made as two lapped hanging panels, with form-aware vertical
    # folds. The reference provides stitched/painted material detail.
    for s in [-1,1]:
        verts=[];faces=[];nu,nv=12,18
        for j in range(nv+1):
            t=j/nv;z=1.14-(1.14-P['hem'])*t
            for i in range(nu+1):
                u=i/nu
                opening=.055+t*(.28 if P['id']=='03_wayfarer' else .065)
                theta=-math.pi/2+s*opening+s*u*(math.pi-opening)
                radius=.183+.068*t
                radial=radius+.020*math.sin(u*math.pi*3+.8)*t
                verts.append((radial*math.cos(theta),radial*.78*math.sin(theta),z-.025*math.sin(u*math.pi)*t))
        for j in range(nv):
            for i in range(nu):
                a=j*(nu+1)+i;faces.append((a,a+1,a+nu+2,a+nu+1) if s>0 else (a+1,a,a+nu+1,a+nu+2))
        ob=mesh('Split_tailored_coat_'+str(s),verts,faces)
        mod=ob.modifiers.new('Wool panel thickness','SOLIDIFY');mod.thickness=.009
        activate(ob);bpy.ops.object.modifier_apply(modifier=mod.name)
    if P['plate']:
        ob=closed_loft('Convex_forged_cuirass',[(1.135,.185,.15,0,0),(1.22,.19,.164,0,-.006),(1.36,.23,.18,0,0),
            (1.47,.215,.15,0,0),(1.49,.17,.11,0,0)],n=24,power=2.1)
        HS.hard_surface_stack(ob,micro_width=.0012,micro_segments=2,angle=38)
    else:
        closed_loft('Structured_leather_brigandine',[(1.13,.19*w,.154,0,-.002),(1.25,.20*w,.164,0,-.002),
            (1.4,.23*w,.165,0,0),(1.47,.214*w,.134,0,0),(1.49,.19*w,.118,0,0)],n=32,power=2.15)
    closed_loft('Leather_belt_with_real_thickness',[(1.105,.195*w,.158,0,0),(1.115,.197*w,.160,0,0),
        (1.16,.192*w,.158,0,0),(1.17,.19*w,.155,0,0)],n=48,power=2.1)
    forged_box('Belt_pouch_real_volume',(-.145,-.148,1.060),(.046,.035,.054),PAINT)
    for x,z,hx,hz in [(-.028,1.142,.003,.022),(.028,1.142,.003,.022),(0,1.120,.028,.003),(0,1.164,.028,.003)]:
        forged_box('Forged_belt_buckle',(x,-.173,z),(hx,.004,hz),SOLIDS['Brass'])
    # Boots have a defined sole/heel/toe, not inflated cylinders.
    for s in [-1,1]:
        x=s*.183*w
        closed_loft('Fitted_boot_'+str(s),[(.008,.070,.132,x,-.042),(.025,.074,.137,x,-.042),(.05,.075,.137,x,-.042),
            (.085,.073,.127,x,-.032),(.13,.064,.105,x,-.012),(.19,.057,.072,x,.025),
            (.29,.065,.077,x,.035),(.395,.072,.085,x,.035),(.425,.074,.087,x,.035)],n=32,power=2.6,mat=PAINTS['Boot'])
        # Anatomical continuous fist made with the new signed-distance toolkit.
        clay=S.Clay((-.06,-.05,-.075),(.06,.05,.065),.0028)
        clay.add(S.sd_round_box((0,0,0),(.032,.023,.043),.009))
        for i in range(4):
            clay.add(S.sd_ellipsoid((-.022+i*.015,-.019,-.022),(.011,.014,.026)),blend=.007)
        clay.add(S.sd_ellipsoid((-.031,-.027,.011),(.014,.017,.027),rot=(0,25,0)),blend=.008)
        hand=clay.to_object('Closed_anatomical_glove_'+str(s),symmetric=False)
        hand.location=(s*.398*w,-.035,.910);hand.data.materials.append(PAINT);PARTS.append(hand)
        closed_loft('Fitted_wrist_cuff_'+str(s),[(.935,.045,.043,s*.39*w,-.025),(.98,.047,.046,s*.383*w,-.014),
            (1.035,.058,.052,s*.371*w,-.005)],n=24,power=2.5)
    shoulders=[-1,1] if P['plate'] else [-1]
    for s in shoulders:
        for layer in range(3 if P['plate'] else 1):
            verts=[];faces=[];n=20
            for i in range(5):
                b=.10+i*(1.35 if layer==0 else .50)/4
                for j in range(n+1):
                    a=-math.pi*.48+j/n*math.pi*.96
                    verts.append((s*(.17*w+(.085+layer*.008)*math.cos(a)*math.cos(b)),.109*math.sin(a)*math.cos(b),
                                  1.455+.105*math.sin(b)-layer*.040))
            for i in range(4):
                for j in range(n):
                    a=i*(n+1)+j;faces.append((a,a+1,a+n+2,a+n+1))
            ob=mesh('Forged_shoulder_lame',verts,faces,PAINTS['Metal'])
            mod=ob.modifiers.new('Plate wall','SOLIDIFY');mod.thickness=.008;activate(ob);bpy.ops.object.modifier_apply(modifier=mod.name)
            HS.hard_surface_stack(ob,micro_width=.0008,micro_segments=2,angle=40)
    # Actual cloth surface with asymmetrical hanging mass and thin folded edge.
    verts=[];faces=[];nu,nv=26,24
    for j in range(nv+1):
        t=j/nv;z=1.53-(1.53-P['cape'])*t
        for i in range(nu+1):
            u=i/nu;topx=-.14+.38*u
            x=topx+(u-.3)*.07*t
            y=.115+.090*math.sin(min(1,t*4)*math.pi/2)+.040*t+.022*math.sin(u*math.pi*7+.4)*t
            verts.append((x,y,z-.065*(1-u)*(1-t)+.10*(1-u)*t+.020*math.sin(u*math.pi*3)*t**8))
    for j in range(nv):
        for i in range(nu):
            a=j*(nu+1)+i;faces.append((a,a+1,a+nu+2,a+nu+1))
    ob=mesh('Thin_woven_half_cloak',verts,faces,PAINTS['Cloak'])
    mod=ob.modifiers.new('Wool thickness','SOLIDIFY');mod.thickness=.009;activate(ob);bpy.ops.object.modifier_apply(modifier=mod.name)
    # Hair follows the anatomical skull. Paint carries strand information;
    # shallow directional ridges shape the outline without sausage-like tubes.
    hvs=[v.co.copy() for v in head.data.vertices];hfs=[]
    for f in head.data.polygons:
        p=sum((hvs[i] for i in f.vertices),Vector())/len(f.vertices)
        if p.z>1.79 or (p.y>.018 and p.z>(1.68 if P['id']=='03_wayfarer' else 1.72)):
            hfs.append(tuple(f.vertices))
    hair=mesh('Coherent_swept_hair_mass',hvs,hfs,PAINTS['Head'])
    normals=[v.normal.copy() for v in hair.data.vertices]
    for v,n in zip(hair.data.vertices,normals):v.co+=n*.007
    mod=hair.modifiers.new('Hair mass thickness','SOLIDIFY');mod.thickness=.006;activate(hair);bpy.ops.object.modifier_apply(modifier=mod.name)
    for v in hair.data.vertices:
        if v.co.z>1.79:v.co.x+=.008*(v.co.z-1.79)/.05
    return head


def prepare_projection():
    bpy.context.view_layer.update()
    silhouettes=json.loads((FOLDER/'projection-silhouette.json').read_text())
    for ob in PARTS:
        # Freeze modifiers and world transforms before assigning image coordinates.
        activate(ob)
        for mod in list(ob.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
        ob.data.transform(ob.matrix_world);ob.matrix_world=Matrix.Identity(4)
        # Remove vertices retained outside extracted faces and recalculate normals.
        bm=bmesh.new();bm.from_mesh(ob.data)
        bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
        bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(ob.data);bm.free()
        for key in ['front','side','back']:
            layer=ob.data.uv_layers.get('Reference_'+key) or ob.data.uv_layers.new(name='Reference_'+key)
            for poly in ob.data.polygons:
                for loop in poly.loop_indices:
                    p=ob.data.vertices[ob.data.loops[loop].vertex_index].co
                    is_head=any(t in ob.name for t in ['face_and_neck','Anatomical_eye','hair_mass'])
                    ppmx,ppmy,ppmz=(410,460,460) if is_head else (P['ppm']*.90,P['ppm']*.83,P['ppm'])
                    px=p.x
                    if ob.name.startswith('Fitted_boot'):
                        center=math.copysign(.183*P['width'],p.x)
                        px=center+(p.x-center)*.78
                        ppmx=P['ppm']*.95
                    u=P['front']+px*ppmx if key=='front' else P['back']-px*ppmx if key=='back' else P['side']+p.y*ppmy
                    y=20+(1.84-p.z)*ppmz if is_head else P['baseline']-p.z*ppmz
                    if 'hair_mass' in ob.name:y=max(36,y)
                    if ob.name.startswith('Fitted_boot'):y=P['baseline']-p.z*P['ppm']*.85
                    runs=silhouettes[key][max(0,min(1023,round(y)))]
                    if runs:
                        side_sign=(1 if p.x>0 else -1)*(1 if key=='front' else -1)
                        if ob.name.startswith('Fitted_boot'):
                            if key=='side':run=max(runs,key=lambda a:a[1]-a[0])
                            else:run=(runs[-1] if side_sign>0 else runs[0])
                            coords=[v.co.y if key=='side' else v.co.x for v in ob.data.vertices]
                            coord=p.y if key=='side' else p.x
                            t=(coord-min(coords))/max(.0001,max(coords)-min(coords))
                            if key=='back':t=1-t
                            u=run[0]+3+t*max(1,run[1]-run[0]-6)
                        else:
                            # Project into the actual silhouette of the matching
                            # garment region, not an AI sheet's empty arm/leg gap.
                            if 'sleeves' in ob.name or 'wrist_cuff' in ob.name or 'glove' in ob.name:
                                run=runs[-1] if side_sign>0 else runs[0]
                            elif 'half_cloak' in ob.name:
                                run=runs[0] if key=='back' else runs[-1]
                            elif 'Split_tailored_coat' in ob.name:
                                run=min(runs,key=lambda a:0 if a[0]<=u<=a[1] else min(abs(u-a[0]),abs(u-a[1])))
                            elif is_head or any(t in ob.name for t in ['core','cuirass','brigandine','belt']):
                                center=P[key]
                                run=min(runs,key=lambda a:abs((a[0]+a[1])/2-center))
                            else:run=min(runs,key=lambda a:0 if a[0]<=u<=a[1] else min(abs(u-a[0]),abs(u-a[1])))
                            u=max(run[0]+3,min(run[1]-3,u))
                    if 'half_cloak' in ob.name:
                        # A dedicated uninterrupted cloth patch avoids projecting
                        # an arm, belt or trouser where AI turnaround views differ.
                        x0,x1,y0,y1={'01_mercenary':(1140,1210,300,615),'02_warden':(1180,1260,260,435),
                                    '03_wayfarer':(1130,1195,280,475)}[P['id']]
                        xs=[v.co.x for v in ob.data.vertices]
                        t=max(0,min(1,(p.x-min(xs))/max(.001,max(xs)-min(xs))))
                        tz=max(0,min(1,(1.53-p.z)/max(.001,1.53-P['cape'])))
                        u=x0+t*(x1-x0);y=y0+tz*(y1-y0)
                    layer.data[loop].uv=(u/1536,1-y/1024)
        ob.data.uv_layers.active=ob.data.uv_layers.get('Reference_front')


def export_and_render(quick):
    sc=bpy.context.scene
    if quick:
        for view,yaw in [('quick',330),('quick_side',90),('quick_back',180)]:
            G.camera(yaw,ortho=2.7,size=768,target=(0,0,.94));sc.render.filepath=str(FOLDER/'renders'/(view+'.png'));bpy.ops.render.render(write_still=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(FOLDER/'work.blend'))
        return
    # Preserve editable separate parts before making the one portable actor.
    source=bpy.data.collections.new('AUTHORING - anatomy and tailored gear');sc.collection.children.link(source)
    source.hide_render=True;source.hide_viewport=True
    for ob in PARTS:
        copy=ob.copy();copy.data=ob.data.copy();copy.name='SOURCE_'+ob.name;source.objects.link(copy)
    bpy.ops.object.select_all(action='DESELECT')
    for ob in PARTS:ob.select_set(True)
    bpy.context.view_layer.objects.active=PARTS[0];bpy.ops.object.join();actor=bpy.context.object;actor.name=P['id']+'_static_actor'
    gate=AUDIT.deliverable([actor],profile='render')
    assert gate['pass'],gate
    layer=actor.data.uv_layers.new(name='BakedAtlas');actor.data.uv_layers.active=layer
    for uv in actor.data.uv_layers:uv.active_render=uv==layer
    activate(actor);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=1.1,island_margin=.004);bpy.ops.object.mode_set(mode='OBJECT')
    image=bpy.data.images.new(P['id']+'_painted_albedo',2048,2048,alpha=True)
    for mat in actor.data.materials:
        node=mat.node_tree.nodes.new('ShaderNodeTexImage');node.image=image;mat.node_tree.nodes.active=node
    sc.cycles.samples=1;sc.render.bake.margin=12;bpy.ops.object.bake(type='COMBINED',pass_filter={'EMIT','DIFFUSE','DIRECT','INDIRECT','COLOR'})
    image.filepath_raw=str(FOLDER/'textures'/f"{P['id']}_albedo.png");image.file_format='PNG';image.save();sc.cycles.samples=24
    # Portable FBX uses only a baked diffuse texture; no projection shader needed.
    portable=actor.copy();portable.data=actor.data.copy();bpy.context.collection.objects.link(portable)
    mat=bpy.data.materials.new('Portable_painted_albedo');mat.use_nodes=True
    bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED');bs.inputs['Roughness'].default_value=.85
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
    uv=mat.node_tree.nodes.new('ShaderNodeUVMap');uv.uv_map='BakedAtlas'
    mat.node_tree.links.new(uv.outputs[0],tex.inputs[0]);mat.node_tree.links.new(tex.outputs[0],bs.inputs['Base Color'])
    portable.data.materials.clear();portable.data.materials.append(mat)
    for poly in portable.data.polygons:poly.material_index=0
    # Export only the atlas UV. The source keeps all projection/editable layers.
    for uv in list(portable.data.uv_layers):
        if uv.name!='BakedAtlas':portable.data.uv_layers.remove(uv)
    activate(portable);bpy.ops.export_scene.fbx(filepath=str(FOLDER/(P['id']+'.fbx')),use_selection=True,object_types={'MESH'},bake_anim=False,path_mode='RELATIVE',axis_forward='-Z',axis_up='Y')
    bpy.data.objects.remove(portable,do_unlink=True)
    for view,yaw in [('front',0),('three_quarter',330),('side',90),('rear',180)]:
        G.camera(yaw,ortho=2.7,size=900,target=(0,0,.94));sc.render.filepath=str(FOLDER/'renders'/(view+'.png'));bpy.ops.render.render(write_still=True)
    G.camera(330,ortho=3.84,size=384,target=(0,0,.94));sc.render.filepath=str(FOLDER/'renders/tactical.png');bpy.ops.render.render(write_still=True)
    G.camera(330,ortho=.64,size=900,elevation=5,target=(0,-.01,1.65));sc.render.filepath=str(FOLDER/'renders/face.png');bpy.ops.render.render(write_still=True)
    G.camera(330,ortho=2.7,size=900,target=(0,0,.94))
    REVIEW.review([actor],str(FOLDER/'geometry_review'),views=('front','right','threequarter','back'),
                  modes=('silhouette','matcap','wire'),res=400)
    paint_workspace=add_paint_workspace(actor,image,source)
    for im in bpy.data.images:
        if im.name not in ('Render Result','Viewer Node') and im.size[0]>0:im.pack()
    bpy.ops.wm.save_as_mainfile(filepath=str(FOLDER/(P['id']+'.blend')))
    points=[v.co for v in actor.data.vertices]
    metadata=dict(id=P['id'],title=P['title'],static=True,rigged=False,animated=False,integrated=False,
        triangles=sum(len(p.vertices)-2 for p in actor.data.polygons),source_parts=len(source.objects),
        bounds=[[min(p[i] for p in points),max(p[i] for p in points)] for i in range(3)],audit=gate,ucupaint=paint_workspace,
        method='CC0 anatomical scaffold; authored tailored/forged geometry; original AI-painted multiview projection with baked diffuse atlas',
        limits=['static visual prototype','projection contains designed/baked lighting','inferred geometry and view seams need later animation polish','no live GUI sculpt/paint strokes'],
        camera=dict(elevation=18,yaw=330,ortho=2.7,render_size=900,tactical_pixels_per_metre=100),
        files={p.relative_to(FOLDER).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in FOLDER.rglob('*') if p.is_file() and p.suffix in ['.blend','.fbx','.png'] and not p.stem.startswith(('quick','work'))})
    (FOLDER/'model.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
    print('PAINTED_CANDIDATE_DONE '+P['id']+' '+str(metadata['triangles'])+' triangles; audit '+str(gate['pass']))


def add_paint_workspace(actor,image,source):
    """Editable image layer; no claim that GUI brush strokes produced the paint."""
    sys.path.insert(0,str(Path.home()/'.codex/tools/character-art/profile/scripts/addons'))
    import addon_utils
    addon_utils.enable('ucupaint',default_set=True,persistent=False)
    from ucupaint.common import get_layer_source
    clone=actor.copy();clone.data=actor.data.copy();clone.name='PAINT_WORKSPACE_'+P['id']
    bpy.context.collection.objects.link(clone)
    clone.data.materials.clear();activate(clone)
    bpy.ops.wm.y_quick_ypaint_node_setup(type='EMISSION',tree_name='Editable painted diffuse '+P['id'],
        enable_metallic=False,enable_roughness=False,enable_height=False,enable_normal=False,switch_to_material_view=False)
    bpy.ops.wm.y_new_layer(name='Original baked diffuse - editable',type='IMAGE',width=2048,height=2048,
        channel_idx='0',uv_map='BakedAtlas',blend_type='MIX')
    group=next(n.node_tree for n in clone.active_material.node_tree.nodes if n.type=='GROUP' and hasattr(n.node_tree,'yp') and n.node_tree.yp.is_ypaint_node)
    layer=group.yp.layers[group.yp.active_layer_index]
    get_layer_source(layer).image=image
    for coll in list(clone.users_collection):coll.objects.unlink(clone)
    source.objects.link(clone)
    clone.hide_render=True
    activate(actor)
    return dict(version='3.0.0',workspace=clone.name,layers=len(group.yp.layers),image=image.name,gui_brush_strokes=False)


def main():
    global P,FOLDER,PAINT
    parser=argparse.ArgumentParser();parser.add_argument('--id',choices=PROFILES,required=True);parser.add_argument('--quick',action='store_true')
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
    P=dict(PROFILES[args.id],id=args.id);FOLDER=BASE/args.id
    (FOLDER/'renders').mkdir(exist_ok=True);(FOLDER/'textures').mkdir(exist_ok=True)
    G.P=dict(rough=.8,key='a');G.setup_scene();bpy.context.scene.render.threads=6
    PAINT=projection_material()
    PAINTS['Head']=projection_material('Head',(.19,.12,.075),True)
    PAINTS['Dark']=solid_material('Dark_wool',(.055,.042,.035),light_response=.7)
    PAINTS['Cloak']=projection_material('Cloak',(.022,.035,.055))
    PAINTS['Boot']=projection_material('Boot',(.045,.028,.019),True)
    PAINTS['Metal']=projection_material('Metal',(.11,.12,.13))
    solid_material('Hair',(.045,.026,.017))
    solid_material('Collar',(.018,.025,.039))
    solid_material('Brass',(.24,.16,.065),.7,.4)
    make_body();prepare_projection();export_and_render(args.quick)


if __name__=='__main__':main()
