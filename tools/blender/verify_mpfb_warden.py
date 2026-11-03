"""Source/material/export/preservation proofs for static presentation015."""
import array
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT/'assets_src/characters/mpfb_warden/2026-11-02'
sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_style_studies as G
sys.path.insert(0, str(Path.home()/'.codex/skills/scenario-blender-expert/scripts'))
import bx_audit as AUDIT

checks = 0


def require(condition, description):
    global checks
    assert condition, description
    checks += 1


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def bounds(parts):
    points = [o.matrix_world@v.co for o in parts for v in o.data.vertices]
    return [[min(p[i] for p in points), max(p[i] for p in points)] for i in range(3)]


def triangles(parts):
    return sum(len(p.vertices)-2 for o in parts for p in o.data.polygons)


def inspect_image(path, bust=False):
    image = bpy.data.images.load(str(path), check_existing=False)
    width, height = image.size[:]
    buf = array.array('f', [0])*(width*height*4)
    image.pixels.foreach_get(buf)
    visible = [i for i in range(width*height) if buf[i*4+3]>.1]
    require(len(visible)>100, 'nonempty render '+path.name)
    lo = [min(i%width for i in visible), min(i//width for i in visible)]
    hi = [max(i%width for i in visible), max(i//width for i in visible)]
    # Busts deliberately cut through the shoulders at the lower image edge.
    require(buf[(height-1)*width*4+3]==0, 'transparent upper background '+path.name)
    require(hi[1]<height-2, 'head not clipped '+path.name)
    if not bust:
        require(min(lo)>1 and hi[0]<width-2, 'body not clipped '+path.name)
    mean = sum(sum(buf[i*4:i*4+3])/3 for i in visible)/len(visible)
    require(mean>.025, 'render not black '+path.name)
    result = dict(size=[width,height], alpha_bounds=lo+hi, mean_linear_rgb=mean)
    bpy.data.images.remove(image)
    return result


def main():
    meta = json.loads((OUT/'model.json').read_text())
    require(meta['static'] and not any(meta[k] for k in ('rigged','animated','integrated')), 'static scope')
    for rel, digest in meta['files'].items():
        require(sha(OUT/rel)==digest, 'source file identity '+rel)
    bpy.ops.wm.open_mainfile(filepath=str(OUT/'mpfb_warden.blend'))
    parts = [bpy.data.objects[p['name']] for p in meta['parts']]
    require(len(parts)==5, 'five intended static meshes')
    require(not any(o.type=='ARMATURE' for o in bpy.data.objects), 'no rig/animation claim')
    require(triangles(parts)<180000, 'offline pilot geometry budget')
    source_bounds, source_tris = bounds(parts), triangles(parts)
    require(bpy.context.scene.camera.data.type=='ORTHO', 'orthographic source camera')
    require(bpy.context.scene.view_settings.exposure==0, 'fixed neutral exposure')
    source = bpy.data.collections.get('SOURCE - editable MPFB master (hidden)')
    require(source and source.hide_render and source.hide_viewport, 'editable master retained separately')
    images = {}
    for obj in parts:
        require(len(obj.data.uv_layers)==1, 'one explicit UV layer '+obj.name)
        require(all(math.isfinite(c) for v in obj.data.vertices for c in v.co), 'finite geometry '+obj.name)
        require(all(math.isfinite(c) for u in obj.data.uv_layers[0].data for c in u.uv), 'finite UVs '+obj.name)
        require(all(p.material_index<len(obj.data.materials) for p in obj.data.polygons), 'valid material slots '+obj.name)
        for material in obj.data.materials:
            require(not any(n.type=='UVMAP' and n.uv_map.startswith('Reference_') for n in material.node_tree.nodes), 'no multiview projection '+material.name)
            for node in material.node_tree.nodes:
                if node.type=='TEX_IMAGE' and node.image:
                    path = Path(bpy.path.abspath(node.image.filepath))
                    require(path.exists() and path.resolve().is_relative_to((OUT/'textures').resolve()), 'portable local map '+material.name)
                    images[path.name] = list(node.image.size)
    head = bpy.data.objects['MPFB_coherent_head_and_neck']
    skin = head.data.materials[0]
    require(skin.name=='MPFB_skin_matching_native_UV', 'dedicated native-UV skin')
    skin_image = next(n.image for n in skin.node_tree.nodes if n.type=='TEX_IMAGE')
    require(min(skin_image.size)>=2048, 'actual skin source at least2K')
    eyes = bpy.data.objects['MPFB_eyes']
    eye_bs = next(n for n in eyes.data.materials[0].node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    require(eye_bs.inputs['Alpha'].is_linked, 'eye cornea-mask alpha preserved')
    require(eyes.data.materials[0]!=skin and bpy.data.objects['MPFB_hair'].data.materials[0]!=skin, 'skin/eye/hair materials separated')
    # Diagnostic albedo from the exact source UV; leave the saved source untouched.
    unlit = skin.copy()
    head.data.materials[0] = unlit
    nodes, links = unlit.node_tree.nodes, unlit.node_tree.links
    bs = next(n for n in nodes if n.type=='BSDF_PRINCIPLED')
    emission = nodes.new('ShaderNodeEmission')
    links.new(bs.inputs['Base Color'].links[0].from_socket, emission.inputs[0])
    links.new(emission.outputs[0], next(n for n in nodes if n.type=='OUTPUT_MATERIAL').inputs[0])
    G.camera(330, ortho=.64, size=900, elevation=5, target=(0,-.01,1.65))
    bpy.context.scene.render.filepath = str(OUT/'renders/face_albedo.png')
    bpy.ops.render.render(write_still=True)
    head.data.materials[0] = skin
    gate = AUDIT.deliverable(parts, profile='render')
    (OUT/'mesh-audit.json').write_text(json.dumps(gate,indent=2)+'\n')
    require(gate['pass'], 'render-delivery mesh audit: '+str(gate['errors']))
    # Fresh scene, real FBX import, all expected maps and geometry.
    bpy.ops.wm.read_factory_settings(use_empty=False)
    G.setup_scene()
    bpy.context.scene.render.threads = 6
    bpy.ops.import_scene.fbx(filepath=str(OUT/'mpfb_warden.fbx'), use_anim=False)
    imported = [o for o in bpy.context.scene.objects if o.type=='MESH']
    require(len(imported)==len(parts), 'actual FBX mesh count')
    require(triangles(imported)==source_tris, 'actual FBX triangle preservation')
    imported_bounds = bounds(imported)
    drift = max(abs(a-b) for x,y in zip(source_bounds,imported_bounds) for a,b in zip(x,y))
    require(drift<.001, 'actual FBX bounds within1mm')
    imported_images = set()
    for obj in imported:
        require(len(obj.data.uv_layers)==1, 'FBX UV layer '+obj.name)
        for material in obj.data.materials:
            require(material.use_nodes, 'FBX material nodes '+material.name)
            for node in material.node_tree.nodes:
                if node.type=='TEX_IMAGE' and node.image:
                    path = Path(bpy.path.abspath(node.image.filepath))
                    require(path.exists(), 'FBX map resolves '+str(path))
                    imported_images.add(path.name)
    require(set(images)==imported_images, 'FBX all expected maps imported')
    imported_eye = next(o for o in imported if o.name=='MPFB_eyes')
    imported_eye_bs = next(n for n in imported_eye.data.materials[0].node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    require(imported_eye_bs.inputs['Alpha'].is_linked, 'FBX eye-mask alpha preserved')
    G.camera(330, ortho=.64, size=900, elevation=5, target=(0,-.01,1.65))
    bpy.context.scene.render.filepath = str(OUT/'renders/fbx_face.png')
    bpy.ops.render.render(write_still=True)
    G.camera(330, ortho=2.7, size=900, target=(0,0,.94))
    bpy.context.scene.render.filepath = str(OUT/'renders/fbx_body.png')
    bpy.ops.render.render(write_still=True)
    render_reports = {}
    for path in sorted((OUT/'renders').glob('*.png')):
        if path.name.startswith('quick'):
            continue
        render_reports[path.name] = inspect_image(path, bust=('face' in path.name))
    preserved = []
    for stage in ('painted_candidates','surface_refinement'):
        folder = ROOT/'assets_src/characters'/stage/'2026-11-02'
        receipt = json.loads((folder/'delivery.json').read_text())
        for file in receipt['files']:
            require(sha(folder/file['path'])==file['sha256'], 'retained '+stage+'/'+file['path'])
        preserved.append(dict(package=stage,files=len(receipt['files'])))
    for name in ('assets_src/characters/roster/manifest.json','assets_src/environment/manifest.json'):
        receipt = json.loads((ROOT/name).read_text())
        for file in receipt['files']:
            require(sha(ROOT/file['path'])==file['sha256'], 'retained '+file['path'])
        preserved.append(dict(package=name,files=len(receipt['files'])))
    result = dict(status='TECHNICAL_PASS',art_acceptance='AWAITING_USER_REVIEW',checks=checks,
        source_triangles=source_tris,source_bounds=source_bounds,actual_fbx_reimport=True,
        maximum_fbx_bounds_drift_metres=drift,images=images,renders=render_reports,
        mesh_audit=gate,preserved=preserved,os_input_used=False,gameplay_tested=False,
        limits=['static mesh proof, not rig/animation acceptance','FBX does not retain all Blender skin shading parameters'])
    (OUT/'verification.json').write_text(json.dumps(result,indent=2)+'\n')
    print('MPFB_WARDEN_VERIFICATION_PASS '+str(checks)+' assertions; actual FBX reimport')


if __name__ == '__main__':
    main()
