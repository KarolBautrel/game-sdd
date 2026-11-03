"""Actual-file acceptance for modelled outfit, preserved face and portable FBX."""
import array
import hashlib
import json
import math
from pathlib import Path
import struct
import sys

import bpy
import bmesh

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets_src/characters/mpfb_warden_outfit/2026-11-02'
BEFORE=ROOT/'assets_src/characters/mpfb_warden/2026-11-02'
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_style_studies as G
sys.path.insert(0,str(Path.home()/'.codex/skills/scenario-blender-expert/scripts'))
import bx_audit as AUDIT

checks=0
HEAD_NAMES=['MPFB_coherent_head_and_neck','MPFB_eyes','MPFB_hair','MPFB_eyebrows']


def require(condition,label):
    global checks
    assert condition,label
    checks+=1


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def bounds(objects):
    ps=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
    return [[min(p[i] for p in ps),max(p[i] for p in ps)] for i in range(3)]


def triangles(objects):return sum(len(p.vertices)-2 for o in objects for p in o.data.polygons)


def head_identity(obj):
    h=hashlib.sha256()
    for row in obj.matrix_world:h.update(struct.pack('<4f',*row))
    coords=array.array('f',[0])*(len(obj.data.vertices)*3);obj.data.vertices.foreach_get('co',coords);h.update(coords.tobytes())
    for face in obj.data.polygons:h.update(struct.pack('<II',len(face.vertices),face.material_index)+array.array('I',face.vertices).tobytes())
    for layer in obj.data.uv_layers:
        uv=array.array('f',[0])*(len(layer.data)*2);layer.data.foreach_get('uv',uv);h.update(layer.name.encode()+uv.tobytes())
    materials=[]
    for mat in obj.data.materials:
        items=[]
        for node in mat.node_tree.nodes:
            if node.type=='TEX_IMAGE':items.append(('image',Path(bpy.path.abspath(node.image.filepath)).name,list(node.image.size),node.image.colorspace_settings.name))
            if node.type=='BSDF_PRINCIPLED':
                items.append(('principled',{key:list(node.inputs[key].default_value) if key=='Base Color' else node.inputs[key].default_value for key in ('Base Color','Roughness','Metallic','Alpha','Subsurface Weight','Subsurface Scale')}))
        links=sorted((l.from_node.name,l.from_socket.identifier,l.to_node.name,l.to_socket.identifier) for l in mat.node_tree.links)
        materials.append(dict(nodes=items,links=links))
    h.update(json.dumps(materials,sort_keys=True).encode())
    return h.hexdigest()


def render_check(path,full_body=False):
    image=bpy.data.images.load(str(path),check_existing=False);w,h=image.size[:]
    data=array.array('f',[0])*(w*h*4);image.pixels.foreach_get(data)
    visible=[i for i in range(w*h) if data[i*4+3]>.1]
    require(len(visible)>100,'nonempty actual render '+path.name)
    mean=sum(sum(data[i*4:i*4+3])/3 for i in visible)/len(visible)
    require(mean>.025,'not black '+path.name)
    lo=[min(i%w for i in visible),min(i//w for i in visible)];hi=[max(i%w for i in visible),max(i//w for i in visible)]
    if full_body:require(min(lo)>1 and hi[0]<w-2 and hi[1]<h-2,'whole body within frame '+path.name)
    bpy.data.images.remove(image)
    return dict(size=[w,h],alpha_bounds=lo+hi,mean_linear_rgb=mean,intentionally_cropped=not full_body)


def main():
    meta=json.loads((OUT/'model.json').read_text())
    require(meta['static'] and not any(meta[k] for k in ('rigged','animated','integrated')),'static scope')
    for name,digest in meta['files'].items():require(sha(OUT/name)==digest,'candidate identity '+name)
    bpy.ops.wm.open_mainfile(filepath=str(BEFORE/'mpfb_warden.blend'))
    identities={n:head_identity(bpy.data.objects[n]) for n in HEAD_NAMES}
    # Actual same-camera before-footwear capture, without saving the old source.
    G.camera(330,ortho=.83,size=900,target=(0,-.02,.29),elevation=12)
    bpy.context.scene.render.filepath=str(OUT/'renders/before_boots.png');bpy.ops.render.render(write_still=True)
    bpy.ops.wm.open_mainfile(filepath=str(OUT/'warden_outfit.blend'))
    for name,digest in identities.items():require(head_identity(bpy.data.objects[name])==digest,'exact approved head geometry/UV/shader '+name)
    source=bpy.data.collections.get('SOURCE - separate modelled outfit parts')
    require(source and source.hide_render and source.hide_viewport,'editable source parts retained')
    require(len(source.objects)>=80,'actual source outfit construction')
    names=[o.name for o in source.objects]
    for prefix in ('SOURCE_Physical_diagonal_leather_harness','SOURCE_Harness_buckle','SOURCE_Thick_waist_leather_belt','SOURCE_Forged_curved_breastplate','SOURCE_Smaller_fitted_boot','SOURCE_Layered_boot_sole'):
        require(any(n.startswith(prefix) for n in names),'actual component '+prefix)
    strap=next(o for o in source.objects if o.name.startswith('SOURCE_Physical_diagonal_leather_harness'))
    bm=bmesh.new();bm.from_mesh(strap.data);volume=abs(bm.calc_volume());bm.free()
    require(volume>.000001,'physical strap has measurable enclosed volume')
    for obj in source.objects:
        for mat in obj.data.materials:
            require(not any(n.type=='TEX_IMAGE' for n in mat.node_tree.nodes),'authored outfit not driven by old paint '+obj.name)
    measures=json.loads((OUT/'measurements.json').read_text());reductions={}
    for name,after in measures['boots_after'].items():
        side=1 if sum(after[0])>0 else -1
        before=next(b for b in measures['boots_before'].values() if (1 if sum(b[0])>0 else -1)==side)
        ratio=[(hi-lo)/(bhi-blo) for (lo,hi),(blo,bhi) in zip(after,before)]
        require(ratio[0]<.90 and ratio[1]<.95 and ratio[2]<.95,'smaller boot dimensions '+name)
        require(.0<=after[2][0]<.025,'planted boot base '+name)
        reductions[name]=dict(width_ratio=ratio[0],length_ratio=ratio[1],height_ratio=ratio[2])
    for side in ('l','r'):
        knee=measures['leg_axes_after']['joint-'+side+'-knee'];ankle=measures['leg_axes_after']['joint-'+side+'-ankle']
        require(abs(knee[0]-ankle[0])<.002,'front knee/ankle alignment '+side)
    parts=[bpy.data.objects[p['name']] for p in meta['parts']]
    source_bounds=bounds(parts);source_tris=triangles(parts)
    require(source_tris<220000,'offline source budget220k')
    outfit=bpy.data.objects['Warden_modelled_outfit']
    require(len(outfit.data.uv_layers)==1 and outfit.data.uv_layers[0].name=='OutfitAtlas','portable outfit UV')
    require(all(math.isfinite(c) for u in outfit.data.uv_layers[0].data for c in u.uv),'finite baked UVs')
    mat=outfit.data.materials[0];bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    for role,socket in [('albedo','Base Color'),('roughness','Roughness'),('metallic','Metallic')]:
        require(bs.inputs[socket].is_linked,'portable PBR input '+socket)
        image=bs.inputs[socket].links[0].from_node.image
        require(Path(bpy.path.abspath(image.filepath)).name=='warden_outfit_'+role+'.png','correct PBR map '+role)
        require(image.colorspace_settings.name==('sRGB' if role=='albedo' else 'Non-Color'),'map colorspace '+role)
    maps={}
    for obj in parts:
        for material in obj.data.materials:
            for node in material.node_tree.nodes:
                if node.type=='TEX_IMAGE' and node.image:
                    path=Path(bpy.path.abspath(node.image.filepath));require(path.exists() and path.resolve().is_relative_to((OUT/'textures').resolve()),'local texture '+path.name);maps[path.name]=list(node.image.size)
    gate=AUDIT.deliverable(parts,profile='render');(OUT/'mesh-audit.json').write_text(json.dumps(gate,indent=2)+'\n')
    require(gate['pass'],'final mesh audit '+str(gate['errors']))
    bpy.ops.wm.read_factory_settings(use_empty=False);G.setup_scene();bpy.context.scene.render.threads=6
    bpy.ops.import_scene.fbx(filepath=str(OUT/'warden_outfit.fbx'),use_anim=False)
    imported=[o for o in bpy.context.scene.objects if o.type=='MESH']
    require(len(imported)==5,'actual FBX mesh count')
    require(triangles(imported)==source_tris,'actual FBX triangle count')
    fresh_bounds=bounds(imported);drift=max(abs(a-b) for x,y in zip(source_bounds,fresh_bounds) for a,b in zip(x,y))
    require(drift<.001,'actual FBX bounds within1mm')
    imported_maps=set()
    for obj in imported:
        require(len(obj.data.uv_layers)==1,'actual imported UV '+obj.name)
        for material in obj.data.materials:
            for node in material.node_tree.nodes:
                if node.type=='TEX_IMAGE' and node.image:
                    path=Path(bpy.path.abspath(node.image.filepath));require(path.exists(),'FBX image resolves '+path.name);imported_maps.add(path.name)
    require(imported_maps==set(maps),'FBX retains all expected PBR/face maps')
    eye=next(o for o in imported if o.name=='MPFB_eyes');eye_bs=next(n for n in eye.data.materials[0].node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    require(eye_bs.inputs['Alpha'].is_linked,'FBX eye alpha retained')
    for name,scale,target,elev in [('fbx_body',2.7,(0,0,.94),18),('fbx_belt',.63,(0,-.05,1.29),8)]:
        G.camera(330,ortho=scale,size=900,target=target,elevation=elev)
        bpy.context.scene.render.filepath=str(OUT/'renders'/(name+'.png'));bpy.ops.render.render(write_still=True)
    rendered={}
    for path in sorted((OUT/'renders').glob('*.png')):
        if path.name.startswith('quick'):continue
        rendered[path.name]=render_check(path,path.stem in ('front','three_quarter','side','rear','source_body','source_front','tactical','geometry_body','fbx_body'))
    preserved=[]
    for folder in (BEFORE,ROOT/'assets_src/characters/painted_candidates/2026-11-02',ROOT/'assets_src/characters/surface_refinement/2026-11-02'):
        receipt=json.loads((folder/'delivery.json').read_text())
        for file in receipt['files']:require(sha(folder/file['path'])==file['sha256'],'preserved source '+str(folder.name)+'/'+file['path'])
        preserved.append(dict(package=folder.relative_to(ROOT).as_posix(),files=len(receipt['files'])))
    for name in ('assets_src/characters/roster/manifest.json','assets_src/environment/manifest.json'):
        receipt=json.loads((ROOT/name).read_text())
        for file in receipt['files']:require(sha(ROOT/file['path'])==file['sha256'],'preserved production '+file['path'])
        preserved.append(dict(package=name,files=len(receipt['files'])))
    result=dict(status='TECHNICAL_PASS',art_acceptance='AWAITING_USER_REVIEW',checks=checks,triangles=source_tris,
        source_bounds=source_bounds,head_identities=identities,strap_volume_m3=volume,boot_reductions=reductions,
        actual_fbx_reimport=True,maximum_fbx_bounds_drift_metres=drift,maps=maps,renders=rendered,
        audit=gate,preserved=preserved,os_input_used=False,gameplay_tested=False,
        limits=['static source outfit, no rig/deformation proof','offline comps are not Godot captures'])
    (OUT/'verification.json').write_text(json.dumps(result,indent=2)+'\n')
    print('WARDEN_OUTFIT_VERIFICATION_PASS '+str(checks)+' assertions; exact approved head, actual FBX and smaller boots')


if __name__=='__main__':main()
