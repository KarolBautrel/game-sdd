"""Fresh-scene FBX reimports and reopen checks for presentation011 studies."""
import array
import hashlib
import json
import math
from pathlib import Path

import bpy

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'assets_src/characters/style_studies/2026-11-02'
reports=[]
checks=0


def require(condition,label):
    global checks
    assert condition,label
    checks+=1


def bounds(objects):
    points=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
    return [[min(p[i] for p in points),max(p[i] for p in points)] for i in range(3)]


for folder in sorted(p for p in BASE.iterdir() if p.is_dir()):
    meta=json.loads((folder/'model.json').read_text(encoding='utf-8'))
    ident=meta['id'];before=checks
    require(meta['static'] and not meta['rigged'] and not meta['animated'] and not meta['integrated'],ident+' honest static scope')
    require(meta['camera']['pixels_per_meter']==100,ident+' tactical scale')
    for relative,digest in meta['files'].items():
        require(hashlib.sha256((folder/relative).read_bytes()).hexdigest()==digest,ident+' source hash '+relative)
    bpy.ops.wm.open_mainfile(filepath=str(folder/(ident+'.blend')))
    scene=bpy.context.scene
    actor=bpy.data.objects[ident+'_static_study']
    require(scene.render.engine=='CYCLES' and scene.camera.data.type=='ORTHO',ident+' source render recipe')
    require(scene.view_settings.view_transform=='Khronos PBR Neutral' and scene.view_settings.exposure==0,ident+' neutral exposure')
    parts=bpy.data.collections.get('AUTHORING - separate costume, face, hair and gear')
    require(parts is not None and len(parts.objects)>50 and parts.hide_render,ident+' editable separated source parts')
    require(any('Face_and_neck' in o.name for o in parts.objects),ident+' anatomical face source')
    require(any('glove finger' in o.name for o in parts.objects),ident+' articulated finger source')
    part_count=len(parts.objects)
    source_bounds=bounds([actor])
    require(max(abs(source_bounds[i][j]-meta['bounds'][i][j]) for i in range(3) for j in range(2))<.0001,ident+' saved bounds')
    image_reports=[]
    for view in ['front','three_quarter','side','rear','face','tactical_100ppm']:
        path=folder/'renders'/(view+'.png')
        im=bpy.data.images.load(str(path),check_existing=False)
        w,h=im.size;buf=array.array('f',[0])*(w*h*4);im.pixels.foreach_get(buf)
        visible=[i for i in range(w*h) if buf[i*4+3]>.1]
        require(len(visible)>100,ident+' nonempty '+view)
        lo=[min(i%w for i in visible),min(i//w for i in visible)]
        hi=[max(i%w for i in visible),max(i//w for i in visible)]
        if view=='face':
            # Face view is an intentional bust crop: shoulders leave the canvas.
            require(hi[1]<h-2,ident+' head top visible in intentional bust crop')
        else:
            require(min(lo)>1 and hi[0]<w-2 and hi[1]<h-2,ident+' unclipped '+view)
        require(any(buf[i*4+3]==0 for i in [0,w-1,w*(h-1),w*h-1]),ident+' transparent background '+view)
        mean=sum((buf[i*4]+buf[i*4+1]+buf[i*4+2])/3 for i in visible)/len(visible)
        require(mean>.025,ident+' not blacked out '+view)
        if view=='tactical_100ppm':require((w,h)==(384,384),ident+' native canvas')
        image_reports.append(dict(view=view,size=[w,h],alpha_bounds=[*lo,*hi],mean_linear_rgb=round(mean,5)))
        bpy.data.images.remove(im)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(folder/(ident+'.fbx')))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    require(len(meshes)==1 and not any(o.type=='ARMATURE' for o in bpy.context.scene.objects),ident+' one static portable mesh')
    actor=meshes[0]
    tris=sum(len(p.vertices)-2 for p in actor.data.polygons)
    require(tris==meta['triangles'] and actor.data.uv_layers,ident+' FBX geometry and UV')
    reimport_bounds=bounds(meshes)
    require(max(abs(reimport_bounds[i][j]-meta['bounds'][i][j]) for i in range(3) for j in range(2))<.0005,ident+' FBX dimension round trip')
    require(all(math.isfinite(x) for layer in actor.data.uv_layers for uv in layer.data for x in uv.uv),ident+' finite UVs')
    textures=[]
    for mat in actor.data.materials:
        require(mat is not None and mat.node_tree is not None,ident+' portable material')
        images=[n.image for n in mat.node_tree.nodes if n.type=='TEX_IMAGE' and n.image]
        require(images and all(tuple(im.size)==(2048,2048) for im in images),ident+' actual FBX texture loading')
        textures.extend(str(Path(bpy.path.abspath(im.filepath)).resolve()) for im in images)
    require(all(Path(p).is_file() for p in textures),ident+' texture dependencies exist')
    reports.append(dict(id=ident,status='PASS',checks=checks-before,triangles=tris,
                        source_part_count=part_count,bounds=reimport_bounds,uv=True,
                        actual_fbx_reimport=True,textures=sorted(set(textures)),renders=image_reports))

# The experiment cannot silently alter accepted production art or tooling.
baseline=[]
for name in ['assets_src/characters/roster/manifest.json','assets_src/environment/manifest.json']:
    manifest=json.loads((ROOT/name).read_text())
    for item in manifest['files']:
        require(hashlib.sha256((ROOT/item['path']).read_bytes()).hexdigest()==item['sha256'],'production unchanged '+item['path'])
    baseline.append(dict(manifest=name,files=len(manifest['files']),status='PASS'))
result=dict(status='TECHNICAL_PASS',art_acceptance='AWAITING_STYLE_CHOICE',checks=checks,models=reports,
            production_manifests=baseline,os_input_used=False,gameplay_tested=False)
(BASE/'verification.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print('STYLE_STUDIES_PASS '+str(checks)+' checks, '+str(len(reports))+' actual FBX reimports')
