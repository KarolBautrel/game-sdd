"""Presentation013. Refine stage39 in a separate package; never rewrite it."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import shutil
import sys
import inspect

import bpy
import bmesh

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_painted_candidates as B

BEFORE=ROOT/'assets_src/characters/painted_candidates/2026-11-02'
AFTER=ROOT/'assets_src/characters/surface_refinement/2026-11-02'
OPS=[]
original_mesh=B.mesh
original_loft=B.closed_loft
original_body=B.make_body
original_box=B.forged_box
original_export=B.export_and_render
original_hard_stack=B.HS.hard_surface_stack


def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def tris(ob):return sum(len(f.vertices)-2 for f in ob.data.polygons)


def prune(ob):
    bm=bmesh.new();bm.from_mesh(ob.data)
    bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
    bm.normal_update();bm.to_mesh(ob.data);bm.free();ob.data.update()


def subdivide(ob,levels=1):
    prune(ob);before=tris(ob)
    B.activate(ob)
    mod=ob.modifiers.new('Controlled curved cage','SUBSURF')
    mod.subdivision_type='CATMULL_CLARK';mod.levels=levels;mod.render_levels=levels
    bpy.ops.object.modifier_apply(modifier=mod.name)
    for poly in ob.data.polygons:poly.use_smooth=True
    OPS.append(dict(part=ob.name,operation='Catmull-Clark before shell thickness',levels=levels,
                    triangles_before=before,triangles_after=tris(ob)))


def refined_mesh(name,verts,faces,mat=None,smooth=True):
    if name=='Thin_woven_half_cloak':
        # Replace the evenly spaced original pleats with broader, gently curved
        # folds. Keep the torso-clearance envelope and existing cloth outline.
        verts=list(verts)
        for index,(x,y,z) in enumerate(verts):
            row,col=divmod(index,27);t=row/24;u=col/26
            old=.022*math.sin(u*math.pi*7+.4)*t
            new=t*(.014*math.sin(u*math.pi*4+.3+.8*t)+.006*math.sin(u*math.pi*7.2-.4*t))
            verts[index]=(x,y-old+new,z)
    ob=original_mesh(name,verts,faces,mat,smooth)
    if name=='CC0_derived_anatomical_face_and_neck' or name.startswith(('Split_tailored_coat','Thin_woven_half_cloak','Forged_shoulder_lame')):
        subdivide(ob)
    elif name=='Coherent_swept_hair_mass':
        prune(ob)
        bm=bmesh.new();bm.from_mesh(ob.data)
        boundary=[v for v in bm.verts if any(e.is_boundary for e in v.link_edges)]
        max_move=0
        for _ in range(2):
            moves={}
            for v in boundary:
                ns=[e.other_vert(v) for e in v.link_edges if e.is_boundary]
                if len(ns)==2:
                    delta=((ns[0].co+ns[1].co)/2-v.co)*.28
                    if delta.length>.0015:delta*=.0015/delta.length
                    moves[v]=delta
            for v,delta in moves.items():v.co+=delta;max_move=max(max_move,delta.length)
        bm.normal_update();bm.to_mesh(ob.data);bm.free()
        OPS.append(dict(part=name,operation='local hairline boundary relax',iterations=2,max_step_metres=max_move))
    return ob


def monotone_slopes(xs,ys):
    h=[b-a for a,b in zip(xs,xs[1:])]
    d=[(b-a)/step for a,b,step in zip(ys,ys[1:],h)]
    slopes=[d[0]]
    for i in range(1,len(xs)-1):
        if d[i-1]*d[i]<=0:slopes.append(0)
        else:
            w1=2*h[i]+h[i-1];w2=h[i]+2*h[i-1]
            slopes.append((w1+w2)/(w1/d[i-1]+w2/d[i]))
    slopes.append(d[-1])
    return slopes


def curved_rings(rings,steps=3):
    xs=[r[0] for r in rings]
    columns=[[r[k] for r in rings] for k in range(1,5)]
    slopes=[monotone_slopes(xs,c) for c in columns]
    result=[]
    for i in range(len(rings)-1):
        h=xs[i+1]-xs[i]
        for j in range(steps):
            t=j/steps;t2=t*t;t3=t2*t
            vals=[(2*t3-3*t2+1)*c[i]+(t3-2*t2+t)*h*m[i]+(-2*t3+3*t2)*c[i+1]+(t3-t2)*h*m[i+1]
                  for c,m in zip(columns,slopes)]
            result.append((xs[i]+h*t,*vals))
    result.append(tuple(rings[-1]))
    return result


def refined_loft(name,rings,n=32,power=2.,fold=0.,mat=None):
    dense=curved_rings(rings)
    count=max(48,n)
    ob=original_loft(name,dense,n=count,power=power,fold=fold,mat=mat)
    OPS.append(dict(part=name,operation='monotone curved profile',rings_before=len(rings),rings_after=len(dense),
                    radial_segments_before=n,radial_segments_after=count,profile_control_points_preserved=True))
    if name.startswith(('Fitted_boot','Fitted_wrist_cuff','Structured_leather_brigandine')):
        original_hard_stack(ob,micro_width=.0022,micro_segments=3,angle=38)
    return ob


def hard_stack(ob,*args,**kwargs):
    kwargs['micro_segments']=max(3,kwargs.get('micro_segments',2))
    return original_hard_stack(ob,*args,**kwargs)


def forged_box(name,center,half,material):
    if name!='Belt_pouch_real_volume':return original_box(name,center,half,material)
    bpy.ops.mesh.primitive_cube_add(size=2,location=center)
    ob=bpy.context.object;ob.name=name;ob.scale=half
    B.HS.apply_scale(ob);ob.data.materials.append(material)
    original_hard_stack(ob,micro_width=.006,micro_segments=4,angle=38)
    B.PARTS.append(ob)
    OPS.append(dict(part=name,operation='rounded leather corners',radius_metres=.006,segments=4))
    return ob


def make_body():
    # Keep the original cloth grain, compress its painted light contrast and let
    # the actual folds supply broad lighting. A uniform replacement lost the
    # selected painted surface, while full reference contrast made false facets.
    cloth=B.PAINTS['Cloak']
    for node in cloth.node_tree.nodes:
        if node.type=='MAP_RANGE' and abs(node.inputs['From Max'].default_value-.22)<.00001:
            node.inputs['To Min'].default_value=.86;node.inputs['To Max'].default_value=1.10
        elif node.type=='MIX_RGB' and node.blend_type=='MULTIPLY' and not node.inputs[1].is_linked:
            node.inputs[1].default_value=(.035,.056,.089,1)
        elif node.type=='MIX_SHADER':node.inputs[0].default_value=.82
    OPS.append(dict(part='Cloak',operation='low-contrast original cloth grain with real fold lighting',
                    palette='retained navy',reason='soften angular reference-light patches; no bitmap blur'))
    head=original_body()
    for ob in B.PARTS:
        if ob.name.startswith('Closed_anatomical_glove'):
            B.activate(ob)
            mod=ob.modifiers.new('Relax voxel stepping','SMOOTH');mod.factor=.28;mod.iterations=2
            bpy.ops.object.modifier_apply(modifier=mod.name)
            for poly in ob.data.polygons:poly.use_smooth=True
            OPS.append(dict(part=ob.name,operation='glove local surface relax',factor=.28,iterations=2))
    # A sewn rolled lip belongs to the fitted shirt; it is not a separate broad
    # floating collar. Its centreline follows the existing opening exactly.
    verts=[];faces=[];n,m=64,8
    for i in range(n):
        a=i*math.tau/n
        for j in range(m):
            b=j*math.tau/m;r=.0022
            verts.append(((.073+r*math.cos(b))*math.cos(a),(.065+r*math.cos(b))*math.sin(a),1.58+r*math.sin(b)))
    for i in range(n):
        for j in range(m):faces.append((i*m+j,((i+1)%n)*m+j,((i+1)%n)*m+(j+1)%m,i*m+(j+1)%m))
    original_mesh('Rolled_wool_neckline_seam',verts,faces,B.SOLIDS['Collar'])
    OPS.append(dict(part='Rolled_wool_neckline_seam',operation='sewn rounded edge',radius_metres=.0022))
    return head


def export(quick):
    total=sum(tris(ob) for ob in B.PARTS)
    assert total<120000,('offline source budget',total)
    original_export(quick)
    if not quick:
        path=B.FOLDER/'model.json';meta=json.loads(path.read_text())
        meta['refinement']=dict(baseline=str((BEFORE/B.P['id']).relative_to(ROOT)),
            baseline_model_sha256=digest(BEFORE/B.P['id']/'model.json'),
            baseline_delivery_sha256=digest(BEFORE/'delivery.json'),
            changes=OPS,texture_design_preserved=True,camera_pose_preserved=True,triangle_budget=120000)
        meta['method']+='; controlled curved profiles, local cage subdivision, leather/cloth edge finishing'
        path.write_text(json.dumps(meta,indent=2)+'\n')
        print('SURFACE_REFINEMENT_DONE '+B.P['id']+' '+str(meta['triangles'])+' triangles')


def preflight():
    delivery=json.loads((BEFORE/'delivery.json').read_text())
    for item in delivery['files']:assert digest(BEFORE/item['path'])==item['sha256'],item['path']
    for name,sha in delivery['source_tools'].items():assert digest(ROOT/name)==sha,name
    for ident in B.PROFILES:
        target=AFTER/ident;target.mkdir(parents=True,exist_ok=True)
        for name in ['concept.png','projection-padded.png','projection-padded.aseprite','projection-silhouette.json']:
            src=BEFORE/ident/name;dst=target/name
            if dst.exists():assert digest(src)==digest(dst),'changed reference '+str(dst)
            else:shutil.copy2(src,dst)


def install_cached_projection():
    """Keep the pinned projection math, hoist its repeated mesh-bound scans.

    This is an in-memory optimization of the preserved stage39 builder. The
    exact source replacements fail closed if that source contract changes.
    """
    source=inspect.getsource(B.prepare_projection)
    replacements={
        "        for key in ['front','side','back']:\n":
        "        coord_bounds={axis:(min(getattr(v.co,axis) for v in ob.data.vertices),max(getattr(v.co,axis) for v in ob.data.vertices)) for axis in ('x','y')}\n        for key in ['front','side','back']:\n",
        "                            coords=[v.co.y if key=='side' else v.co.x for v in ob.data.vertices]\n":
        "                            coord_lo,coord_hi=coord_bounds['y' if key=='side' else 'x']\n",
        "                            t=(coord-min(coords))/max(.0001,max(coords)-min(coords))\n":
        "                            t=(coord-coord_lo)/max(.0001,coord_hi-coord_lo)\n",
        "                        xs=[v.co.x for v in ob.data.vertices]\n":
        "                        coord_lo,coord_hi=coord_bounds['x']\n",
        "                        t=max(0,min(1,(p.x-min(xs))/max(.001,max(xs)-min(xs))))\n":
        "                        t=max(0,min(1,(p.x-coord_lo)/max(.001,coord_hi-coord_lo)))\n",
    }
    for old,new in replacements.items():
        assert source.count(old)==1,'projection source contract changed: '+old
        source=source.replace(old,new)
    exec(compile(source,'<cached stage39 reference projection>','exec'),B.__dict__)


if __name__=='__main__':
    preflight()
    install_cached_projection()
    B.BASE=AFTER;B.mesh=refined_mesh;B.closed_loft=refined_loft;B.forged_box=forged_box
    B.make_body=make_body;B.export_and_render=export;B.HS.hard_surface_stack=hard_stack
    B.main()
