"""Static presentation015 pilot: coherent MPFB skin/eyes, retained warden costume."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import shutil
import sys

import bpy
import bmesh
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from mpfb_runtime import enable_mpfb, ASSETS, INSTALL
import build_style_studies as G

OUT = ROOT / 'assets_src/characters/mpfb_warden/2026-11-02'
BEFORE = ROOT / 'assets_src/characters/surface_refinement/2026-11-02/02_warden'
PARTS = []
SOURCES = []


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def active(obj):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def textured_material(name, path, roughness=.65, metallic=0.0, alpha=False, sss=0.0):
    path = Path(path)
    destination = OUT / 'textures' / path.name
    if path.resolve() != destination.resolve():
        shutil.copyfile(path, destination)
    image = bpy.data.images.load(str(destination), check_existing=True)
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bs = next(n for n in nodes if n.type == 'BSDF_PRINCIPLED')
    bs.inputs['Roughness'].default_value = roughness
    bs.inputs['Metallic'].default_value = metallic
    bs.inputs['Specular IOR Level'].default_value = .3 if not metallic else .5
    bs.inputs['Subsurface Weight'].default_value = sss
    bs.inputs['Subsurface Scale'].default_value = .006
    texture = nodes.new('ShaderNodeTexImage')
    texture.image = image
    texture.interpolation = 'Linear'
    links.new(texture.outputs['Color'], bs.inputs['Base Color'])
    if alpha:
        links.new(texture.outputs['Alpha'], bs.inputs['Alpha'])
        mat.surface_render_method = 'DITHERED'
        mat.use_backface_culling = False
    return mat


def material_texture(mhmat):
    mhmat = Path(mhmat)
    line = next(s for s in mhmat.read_text(encoding='utf-8').splitlines() if s.startswith('diffuseTexture '))
    return mhmat.parent / line.split(' ', 1)[1].strip()


def frozen(obj, name, transform):
    evaluated = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = bpy.data.meshes.new_from_object(evaluated)
    clone = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(clone)
    mesh.transform(transform @ obj.matrix_world)
    for poly in mesh.polygons:
        poly.use_smooth = True
    PARTS.append(clone)
    return clone


def build_character():
    human_service, target_service, _ = enable_mpfb()
    macro = target_service.get_default_macro_info_dict()
    macro.update(gender=1.0, age=.63, muscle=.63, weight=.46, height=.55)
    macro['race'] = dict(caucasian=1.0, african=0.0, asian=0.0)
    human = human_service.create_human(macro_detail_dict=macro)
    human.name = 'MPFB_editable_human_master'
    # Moderate parametric shaping; preserve a continuous anatomical UV surface.
    for name, weight in [('head/head-square', .14), ('chin/chin-width-incr', .14),
                         ('head/head-age-incr', .32), ('eyebrows/eyebrows-angle-down', .10)]:
        path = INSTALL / 'addons/mpfb/data/targets' / (name + '.target.gz')
        assert path.exists(), path
        target_service.load_target(human, str(path), weight=weight)
    skin_path = ASSETS / 'skins/jartur69_middleage_slavic_male_with_genitals_and_beard/jartur69_middleage_slavic_male_with_genitals_and_beard.mhmat'
    human_service.set_character_skin(str(skin_path), human, skin_type='MAKESKIN')
    loaded = []
    for kind, rel in [('Eyes', 'eyes/high-poly/high-poly.mhclo'),
                      ('Hair', 'hair/short01/short01.mhclo'),
                      ('Eyebrows', 'eyebrows/eyebrow001/eyebrow001.mhclo')]:
        obj = human_service.add_mhclo_asset(str(ASSETS / rel), human, asset_type=kind,
            subdiv_levels=1, material_type='MAKESKIN', set_up_rigging=False,
            interpolate_weights=False, import_subrig=False, import_weights=False)
        loaded.append((kind, obj, ASSETS / rel))
    bpy.context.view_layer.update()
    body_eval = human.evaluated_get(bpy.context.evaluated_depsgraph_get())
    max_z = max((human.matrix_world @ v.co).z for v in body_eval.data.vertices)
    transform = Matrix.Translation((0, .020, 0)) @ Matrix.Scale(1.84 / max_z, 4)
    head = frozen(human, 'MPFB_coherent_head_and_neck', transform)
    bm = bmesh.new()
    bm.from_mesh(head.data)
    bmesh.ops.bisect_plane(bm, geom=list(bm.verts)+list(bm.edges)+list(bm.faces),
        dist=.000001, plane_co=(0, 0, 1.54), plane_no=(0, 0, 1), clear_inner=True)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
    bm.to_mesh(head.data)
    bm.free()
    # Lower neck/trapezius is hidden inside the existing garment, not on top of it.
    for vertex in head.data.vertices:
        if vertex.co.z < 1.602:
            influence = max(0, min(1, (1.602-vertex.co.z)/.025))
            radius = math.hypot(vertex.co.x/.057, (vertex.co.y-.012)/.044)
            if radius > 1:
                target = Vector((vertex.co.x/radius, .012+(vertex.co.y-.012)/radius, vertex.co.z))
                vertex.co = vertex.co.lerp(target, influence)
    head.data.materials.clear()
    head.data.materials.append(textured_material('MPFB_skin_matching_native_UV', material_texture(skin_path), .67, sss=.055))
    for poly in head.data.polygons:
        poly.material_index = 0
    active(head)
    mod = head.modifiers.new('One anatomical subdivision', 'SUBSURF')
    mod.levels = 1
    bpy.ops.object.modifier_apply(modifier=mod.name)
    for kind, obj, source in loaded:
        clone = frozen(obj, 'MPFB_'+kind.lower(), transform)
        clone.data.materials.clear()
        if kind == 'Eyes':
            mhmat = ASSETS / 'eyes/materials/mindfront_brown_eye_02/mindfront_brown_eye_02.mhmat'
            mat = textured_material('MPFB_separate_brown_iris_and_sclera', material_texture(mhmat), .25, alpha=True)
        elif kind == 'Hair':
            mat = textured_material('MPFB_separate_dark_hair', material_texture(source.with_suffix('.mhmat')), .72, alpha=True)
            # Separate the source scalp/cards from skin and coplanar card layers.
            bm = bmesh.new()
            bm.from_mesh(clone.data)
            bm.normal_update()
            remaining = set(bm.verts)
            component = 0
            part_for_vertex = {}
            while remaining:
                seed = min(remaining, key=lambda v:v.index)
                stack, island = [seed], set()
                while stack:
                    vertex = stack.pop()
                    if vertex in island:
                        continue
                    island.add(vertex)
                    stack.extend(e.other_vert(vertex) for e in vertex.link_edges if e.other_vert(vertex) not in island)
                remaining.difference_update(island)
                offset = .0008+.0004*(component%7)
                for vertex in island:
                    part_for_vertex[vertex.index] = component
                    vertex.co += vertex.normal*offset
                component += 1
            bm.to_mesh(clone.data)
            bm.free()
            # Resolve only demonstrated remaining parallel overlaps, not tolerances.
            for _ in range(4):
                clone.data.update()
                mesh = clone.data
                tree = BVHTree.FromPolygons([v.co for v in mesh.vertices], [p.vertices for p in mesh.polygons])
                corrections = {}
                for face in mesh.polygons:
                    own = part_for_vertex[face.vertices[0]]
                    for point, normal, index, _ in tree.find_nearest_range(face.center, .00023):
                        other = part_for_vertex[mesh.polygons[index].vertices[0]]
                        delta = face.center-point
                        if own!=other and face.normal.dot(normal)>.999 and (delta-delta.dot(normal)*normal).length<.0000023:
                            corrections[max(own,other)] = normal.copy()
                if not corrections:
                    break
                for vertex in mesh.vertices:
                    part = part_for_vertex[vertex.index]
                    if part in corrections:
                        vertex.co += corrections[part]*.001
            else:
                raise AssertionError('Hair card overlap repair did not converge')
        else:
            mat = textured_material('MPFB_separate_eyebrows', material_texture(source.with_suffix('.mhmat')), .8, alpha=True)
        clone.data.materials.append(mat)
        for poly in clone.data.polygons:
            poly.material_index = 0
        SOURCES.append(dict(asset=source.relative_to(ASSETS).as_posix(), sha256=sha(source), license='CC0'))
    # Keep a source base for later authorized work, separate from the static deliverable.
    source_collection = bpy.data.collections.new('SOURCE - editable MPFB master (hidden)')
    bpy.context.scene.collection.children.link(source_collection)
    source_collection.hide_render = True
    source_collection.hide_viewport = True
    for obj in [human]+[x[1] for x in loaded]:
        for collection in list(obj.users_collection):
            collection.objects.unlink(obj)
        source_collection.objects.link(obj)
    SOURCES.append(dict(asset=skin_path.relative_to(ASSETS).as_posix(), sha256=sha(skin_path), license='CC0'))
    return head


def add_retained_costume():
    with bpy.data.libraries.load(str(BEFORE/'02_warden.blend'), link=False) as (src, dest):
        dest.objects = ['02_warden_static_actor']
    costume = dest.objects[0]
    assert costume is not None
    bpy.context.collection.objects.link(costume)
    costume.name = 'Retained_authored_warden_costume'
    bm = bmesh.new()
    bm.from_mesh(costume.data)
    head_slots = {i for i, m in enumerate(costume.data.materials) if m and m.name.startswith('Painted_reference_Head')}
    assert head_slots
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.material_index in head_slots], context='FACES')
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
    bm.to_mesh(costume.data)
    bm.free()
    old_materials = list(costume.data.materials)
    costume.data.materials.clear()
    for old in old_materials:
        metal = .3 if 'Metal' in old.name else (.45 if 'Brass' in old.name else 0)
        material = textured_material('Retained_painted_costume_'+old.name,
            BEFORE/'textures/02_warden_albedo.png', .7 if metal else .86, metal)
        costume.data.materials.append(material)
    for uv in list(costume.data.uv_layers):
        if uv.name != 'BakedAtlas':
            costume.data.uv_layers.remove(uv)
    assert len(costume.data.uv_layers) == 1
    PARTS.insert(0, costume)


def render(name, yaw=330, face=False, elevation=None, size=800):
    G.camera(yaw, ortho=.64 if face else 2.7, size=size,
             elevation=(5 if face else 18) if elevation is None else elevation,
             target=(0,-.01,1.65) if face else (0,0,.94))
    bpy.context.scene.render.filepath = str(OUT/'renders'/f'{name}.png')
    bpy.ops.render.render(write_still=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--quick', action='store_true')
    args = parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    reference = json.loads((OUT/'reference.json').read_text())
    assert reference['status'] == 'READY_FOR_STATIC_PILOT'
    assert sha(ROOT/reference['reference']) == reference['sha256']
    for directory in ('textures', 'renders'):
        (OUT/directory).mkdir(exist_ok=True)
    G.setup_scene()
    scene = bpy.context.scene
    scene.render.threads = 6
    scene.cycles.samples = 24
    head = build_character()
    add_retained_costume()
    render('quick_face' if args.quick else 'face_three_quarter', face=True, size=640 if args.quick else 900)
    if args.quick:
        render('quick_body', size=640)
        bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'artifacts/mpfb-warden-work.blend'))
        print('MPFB_WARDEN_QUICK_PASS')
        return
    for name, yaw in [('front',0),('three_quarter',330),('side',90),('rear',180)]:
        render(name, yaw=yaw, size=900)
    for name, yaw in [('face_front',0),('face_profile',90)]:
        render(name, yaw=yaw, face=True, size=900)
    G.camera(330, ortho=3.84, size=384, elevation=18, target=(0,0,.94))
    scene.render.filepath = str(OUT/'renders/tactical.png')
    bpy.ops.render.render(write_still=True)
    render('isometric35', elevation=35, size=900)
    original_lights = [(o, o.location.copy(), o.data.color[:]) for o in scene.objects if o.type=='LIGHT']
    for obj, _, _ in original_lights:
        obj.location.x *= -1
        obj.data.color = (1,1,1)
    render('face_changed_light', yaw=330, face=True, size=900)
    for obj, location, color in original_lights:
        obj.location = location
        obj.data.color = color
    # A temporary UV checker diagnoses the same head UV without altering delivery.
    skin = head.data.materials[0]
    checker = bpy.data.materials.new('DIAGNOSTIC UV checker')
    checker.use_nodes = True
    nodes, links = checker.node_tree.nodes, checker.node_tree.links
    coords = nodes.new('ShaderNodeTexCoord')
    grid = nodes.new('ShaderNodeTexChecker')
    grid.inputs['Scale'].default_value = 64
    grid.inputs['Color1'].default_value = (.04,.10,.2,1)
    grid.inputs['Color2'].default_value = (.7,.7,.7,1)
    links.new(coords.outputs['UV'],grid.inputs['Vector'])
    links.new(grid.outputs['Color'],next(n for n in nodes if n.type=='BSDF_PRINCIPLED').inputs['Base Color'])
    head.data.materials[0] = checker
    render('face_uv_checker', yaw=330, face=True, size=900)
    head.data.materials[0] = skin
    G.camera(330, ortho=2.7, size=900, target=(0,0,.94))
    # Export only visible static parts and simple portable PBR materials.
    bpy.ops.object.select_all(action='DESELECT')
    for obj in PARTS:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = PARTS[0]
    bpy.ops.export_scene.fbx(filepath=str(OUT/'mpfb_warden.fbx'), use_selection=True,
        object_types={'MESH'}, bake_anim=False, path_mode='RELATIVE',
        axis_forward='-Z', axis_up='Y', add_leaf_bones=False)
    for image in bpy.data.images:
        if image.name not in ('Render Result','Viewer Node') and image.size[0] > 0:
            image.pack()
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'mpfb_warden.blend'))
    report = dict(schema='sdd.mpfb-warden-v1', static=True, rigged=False, animated=False,
        integrated=False, addon_version='2.0.18', blender=bpy.app.version_string,
        reference_sha256=reference['sha256'], parts=[dict(name=o.name,
        triangles=sum(len(p.vertices)-2 for p in o.data.polygons), uvs=[u.name for u in o.data.uv_layers],
        materials=[m.name for m in o.data.materials]) for o in PARTS], sources=SOURCES,
        method='coherent native-UV MPFB skin, separate CC0 eyes/hair/brows; retained authored costume',
        limits=['static visual pilot','costume retains earlier painted lighting','lower neck is cut under collar',
                'no deformation/animation proof','offline tactical composition is not a Godot capture'],
        camera=dict(elevation=18,yaw=330,ortho=2.7,tactical_pixels_per_metre=100),
        files={p.relative_to(OUT).as_posix():sha(p) for p in OUT.rglob('*')
               if p.is_file() and p.suffix in ('.blend','.fbx','.png')
               and (p.parent==OUT/'textures' or p.name in ('mpfb_warden.blend','mpfb_warden.fbx')
                    or (p.parent==OUT/'renders' and not p.stem.startswith(('quick','fbx_')) and p.stem!='face_albedo'))})
    (OUT/'model.json').write_text(json.dumps(report, indent=2)+'\n')
    print('MPFB_WARDEN_BUILD_PASS '+str(sum(p['triangles'] for p in report['parts']))+' triangles')


if __name__ == '__main__':
    main()
