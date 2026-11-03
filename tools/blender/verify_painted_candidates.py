"""Presentation012: actual source reopen, FBX import and retained-art proof."""
import array
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'assets_src/characters/painted_candidates/2026-11-02'
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_style_studies as G
sys.path.insert(0,str(Path.home()/'.codex/tools/character-art/profile/scripts/addons'))
import addon_utils
addon_utils.enable('ucupaint',default_set=True,persistent=False)
from ucupaint.common import get_layer_source

checks=0
reports=[]


def require(condition,label):
    global checks
    assert condition,label
    checks+=1


def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def bounds(objects):
    points=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
    return [[min(p[i] for p in points),max(p[i] for p in points)] for i in range(3)]


def inspect_image(path,face=False):
    im=bpy.data.images.load(str(path),check_existing=False)
    w,h=im.size;buf=array.array('f',[0])*(w*h*4);im.pixels.foreach_get(buf)
    visible=[i for i in range(w*h) if buf[i*4+3]>.1]
    require(len(visible)>100,'nonempty '+str(path))
    lo=[min(i%w for i in visible),min(i//w for i in visible)]
    hi=[max(i%w for i in visible),max(i//w for i in visible)]
    if face:require(hi[1]<h-2,'head top within intentional bust crop')
    else:require(min(lo)>1 and hi[0]<w-2 and hi[1]<h-2,'no full-body clipping '+path.name)
    require(buf[3]==0,'alpha background '+path.name)
    mean=sum(sum(buf[i*4:i*4+3])/3 for i in visible)/len(visible)
    require(mean>.025,'not black '+path.name)
    report=dict(size=[w,h],alpha_bounds=[*lo,*hi],mean_linear_rgb=round(mean,5))
    bpy.data.images.remove(im)
    return report


for ident in ['01_mercenary','02_warden','03_wayfarer']:
    before=checks;folder=BASE/ident
    meta=json.loads((folder/'model.json').read_text())
    require(meta['static'] and not any(meta[k] for k in ['rigged','animated','integrated']),ident+' static scope')
    require(0<meta['triangles']<50000,ident+' static exploration budget')
    require(meta['audit']['pass'] and not meta['audit']['errors'],ident+' deliverable audit')
    require(meta['camera']['tactical_pixels_per_metre']==100,ident+' native scale')
    for rel,sha in meta['files'].items():require(digest(folder/rel)==sha,ident+' hash '+rel)
    addon_utils.enable('ucupaint',default_set=True,persistent=False)
    bpy.ops.wm.open_mainfile(filepath=str(folder/(ident+'.blend')))
    actor=bpy.data.objects[ident+'_static_actor']
    require(bpy.context.scene.render.engine=='CYCLES',ident+' source Cycles')
    require(bpy.context.scene.camera.data.type=='ORTHO',ident+' orthographic camera')
    require(bpy.context.scene.view_settings.exposure==0,ident+' neutral exposure')
    source=bpy.data.collections.get('AUTHORING - anatomy and tailored gear')
    require(source and source.hide_render and source.hide_viewport,ident+' isolated editable source')
    require(len(source.objects)>=25,ident+' source parts')
    require(any('anatomical_face' in o.name for o in source.objects),ident+' separate face')
    require(any('Closed_anatomical_glove' in o.name for o in source.objects),ident+' continuous fist')
    workspace=source.objects.get(meta['ucupaint']['workspace'])
    require(workspace is not None,ident+' editable paint workspace')
    group=next(n.node_tree for n in workspace.active_material.node_tree.nodes if n.type=='GROUP' and hasattr(n.node_tree,'yp') and n.node_tree.yp.is_ypaint_node)
    require(len(group.yp.layers)==1,ident+' real Ucupaint layer')
    require(tuple(get_layer_source(group.yp.layers[0]).image.size)==(2048,2048),ident+' paint-layer atlas')
    require(not meta['ucupaint']['gui_brush_strokes'],ident+' honest brush provenance')
    require(max(abs(bounds([actor])[i][j]-meta['bounds'][i][j]) for i in range(3) for j in range(2))<.0001,ident+' source bounds')
    images={view:inspect_image(folder/'renders'/(view+'.png'),view=='face') for view in ['front','three_quarter','side','rear','face','tactical']}
    require(images['tactical']['size']==[384,384],ident+' native canvas')
    require((folder/'geometry_review/review_sheet.png').is_file(),ident+' geometry-only review')
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.world=bpy.data.worlds.new('Fresh_import_world')
    G.setup_scene();bpy.context.scene.render.threads=6
    bpy.ops.import_scene.fbx(filepath=str(folder/(ident+'.fbx')))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    require(len(meshes)==1 and not any(o.type=='ARMATURE' for o in bpy.context.scene.objects),ident+' static FBX')
    actor=meshes[0];tris=sum(len(p.vertices)-2 for p in actor.data.polygons)
    require(tris==meta['triangles'],ident+' roundtrip triangles')
    require(len(actor.data.uv_layers)==1,ident+' one portable atlas UV')
    require(all(math.isfinite(x) and -.0001<=x<=1.0001 for uv in actor.data.uv_layers[0].data for x in uv.uv),ident+' finite packed UV')
    require(max(abs(bounds(meshes)[i][j]-meta['bounds'][i][j]) for i in range(3) for j in range(2))<.0005,ident+' FBX scale roundtrip')
    textures=[]
    for mat in actor.data.materials:
        require(mat is not None and mat.node_tree is not None,ident+' portable material')
        ns,ls=mat.node_tree.nodes,mat.node_tree.links
        tex=next(n for n in ns if n.type=='TEX_IMAGE' and n.image)
        require(tuple(tex.image.size)==(2048,2048),ident+' actual texture loading')
        path=Path(bpy.path.abspath(tex.image.filepath)).resolve()
        require(path.is_file(),ident+' texture exists')
        require(digest(path)==digest(folder/'textures'/(ident+'_albedo.png')),ident+' correct diffuse dependency')
        textures.append(str(path.relative_to(ROOT)))
        # Inspect the imported atlas without adding another lighting pass to its
        # designed diffuse values. Exported FBX itself remains basic Principled.
        em=ns.new('ShaderNodeEmission');ls.new(tex.outputs[0],em.inputs[0])
        ls.new(em.outputs[0],next(n for n in ns if n.type=='OUTPUT_MATERIAL').inputs[0])
    G.camera(330,ortho=2.7,size=900,target=(0,0,.94))
    bpy.context.scene.render.filepath=str(folder/'renders/fbx_roundtrip.png')
    bpy.ops.render.render(write_still=True)
    images['fbx_roundtrip']=inspect_image(folder/'renders/fbx_roundtrip.png')
    meta['files']['renders/fbx_roundtrip.png']=digest(folder/'renders/fbx_roundtrip.png')
    (folder/'model.json').write_text(json.dumps(meta,indent=2)+'\n')
    reports.append(dict(id=ident,status='PASS',checks=checks-before,triangles=tris,actual_fbx_reimport=True,
                        ucupaint_layer_reopened=True,textures=textures,renders=images,audit_warnings=meta['audit']['warnings']))

baseline=[]
for name in ['assets_src/characters/roster/manifest.json','assets_src/environment/manifest.json']:
    manifest=json.loads((ROOT/name).read_text())
    for item in manifest['files']:require(digest(ROOT/item['path'])==item['sha256'],'retained '+item['path'])
    baseline.append(dict(manifest=name,files=len(manifest['files']),status='PASS'))
old=ROOT/'assets_src/characters/style_studies/2026-11-02'
for folder in [p for p in old.iterdir() if p.is_dir()]:
    meta=json.loads((folder/'model.json').read_text())
    for name,sha in meta['files'].items():require(digest(folder/name)==sha,'original style preserved '+name)
result=dict(status='TECHNICAL_PASS',art_acceptance='AWAITING_USER_REVIEW',checks=checks,models=reports,
            production_manifests=baseline,os_input_used=False,gameplay_tested=False)
(BASE/'verification.json').write_text(json.dumps(result,indent=2)+'\n')
print('PAINTED_CANDIDATES_PASS '+str(checks)+' checks; 3 actual FBX reimports')
