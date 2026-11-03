"""Presentation017: exact stage41 restoration, modest existing-foot shrink only."""
import array
import hashlib
import json
from pathlib import Path
import shutil
import sys

import bpy

ROOT=Path(__file__).resolve().parents[2]
BEFORE=ROOT/'assets_src/characters/mpfb_warden/2026-11-02'
OUT=ROOT/'assets_src/characters/mpfb_warden_boots_only/2026-11-02'
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_style_studies as G
import verify_mpfb_warden as V

checks=0


def require(value,label):
    global checks
    assert value,label
    checks+=1


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def structure(obj):
    uv=[]
    for layer in obj.data.uv_layers:
        data=array.array('f',[0])*(len(layer.data)*2);layer.data.foreach_get('uv',data)
        uv.append((layer.name,hashlib.sha256(data.tobytes()).hexdigest()))
    topology=[(list(p.vertices),p.material_index,p.use_smooth) for p in obj.data.polygons]
    mats=[]
    for mat in obj.data.materials:
        nodes=[]
        for node in mat.node_tree.nodes:
            if node.type=='TEX_IMAGE':nodes.append(('image',Path(bpy.path.abspath(node.image.filepath)).name,node.image.colorspace_settings.name))
            if node.type=='BSDF_PRINCIPLED':nodes.append(('pbr',[list(s.default_value) if s.type=='RGBA' else s.default_value for s in node.inputs if s.name in ('Base Color','Roughness','Metallic','Alpha','Subsurface Weight','Subsurface Scale')]))
        links=sorted((l.from_node.name,l.from_socket.identifier,l.to_node.name,l.to_socket.identifier) for l in mat.node_tree.links)
        mats.append((mat.name,nodes,links))
    return dict(uv=uv,topology=hashlib.sha256(json.dumps(topology).encode()).hexdigest(),materials=mats,
                matrix=[list(row) for row in obj.matrix_world])


def render(name,boots=False,native=False):
    G.camera(330,ortho=.75 if boots else (3.84 if native else 2.7),size=384 if native else 900,
             elevation=12 if boots else 18,target=(0,-.02,.24) if boots else (0,0,.94))
    bpy.context.scene.render.filepath=str(OUT/'renders'/(name+'.png'));bpy.ops.render.render(write_still=True)


def main():
    for directory in ('textures','renders','licenses'):(OUT/directory).mkdir(parents=True,exist_ok=True)
    before_meta=json.loads((BEFORE/'model.json').read_text())
    bpy.ops.wm.open_mainfile(filepath=str(BEFORE/'mpfb_warden.blend'))
    bpy.context.scene.render.threads=6
    parts=[bpy.data.objects[p['name']] for p in before_meta['parts']]
    original={o.name:[tuple(v.co) for v in o.data.vertices] for o in parts}
    original_structure={o.name:structure(o) for o in parts}
    render('before_boots',boots=True)
    costume=bpy.data.objects['Retained_authored_warden_costume']
    # The retained atlas actor has shared material slots. Use actual disconnected
    # boot geometry, not material names that may be unused after the old bake.
    neighbors=[[] for _ in costume.data.vertices]
    for edge in costume.data.edges:
        a,b=edge.vertices;neighbors[a].append(b);neighbors[b].append(a)
    unseen=set(range(len(costume.data.vertices)));indices=set();boot_components=0
    while unseen:
        seed=next(iter(unseen));stack=[seed];component=set()
        while stack:
            index=stack.pop()
            if index in component:continue
            component.add(index);stack.extend(n for n in neighbors[index] if n not in component)
        unseen.difference_update(component)
        zs=[costume.data.vertices[i].co.z for i in component]
        if max(zs)<.5 and min(zs)<.025 and len(component)>200:
            indices.update(component);boot_components+=1
    require(boot_components==2,'exact two original boot components')
    require(len(indices)>500,'original low-boot geometry identified')
    centers={}
    for side in (-1,1):
        group=[costume.data.vertices[i].co.x for i in indices if costume.data.vertices[i].co.x*side>0]
        require(len(group)>200,'both original boots identified')
        centers[side]=(min(group)+max(group))/2
    modified=[]
    for index in sorted(indices):
        vertex=costume.data.vertices[index];z=vertex.co.z
        if z>=.32:continue
        t=max(0,min(1,(z-.16)/.16));t=t*t*(3-2*t);factor=.94+.06*t
        side=1 if vertex.co.x>0 else -1
        vertex.co.x=centers[side]+(vertex.co.x-centers[side])*factor
        vertex.co.y*=factor
        modified.append(index)
    costume.data.update();allowed=set(modified)
    textures={}
    for obj in parts:
        for mat in obj.data.materials:
            for node in mat.node_tree.nodes:
                if node.type=='TEX_IMAGE' and node.image:
                    name=Path(bpy.path.abspath(node.image.filepath)).name
                    source=BEFORE/'textures'/name;dest=OUT/'textures'/name
                    shutil.copyfile(source,dest);require(sha(source)==sha(dest),'unchanged texture '+name)
                    node.image.filepath=str(dest);textures[name]=sha(dest)
    for name in ('three_quarter','boots','tactical'):render(name,boots=name=='boots',native=name=='tactical')
    G.camera(330,ortho=2.7,size=900,target=(0,0,.94))
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:obj.select_set(True)
    bpy.context.view_layer.objects.active=costume
    bpy.ops.export_scene.fbx(filepath=str(OUT/'warden_restored.fbx'),use_selection=True,object_types={'MESH'},
        bake_anim=False,path_mode='RELATIVE',axis_forward='-Z',axis_up='Y',add_leaf_bones=False)
    for image in bpy.data.images:
        if image.name not in ('Render Result','Viewer Node') and image.size[0]>0:image.pack()
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'warden_restored.blend'))
    # Reopen the actual saved source before asserting the very narrow change.
    bpy.ops.wm.open_mainfile(filepath=str(OUT/'warden_restored.blend'))
    parts=[bpy.data.objects[p['name']] for p in before_meta['parts']]
    for obj in parts:
        require(structure(obj)==original_structure[obj.name],'exact topology/UV/material/transform '+obj.name)
        for index,vertex in enumerate(obj.data.vertices):
            old=original[obj.name][index]
            if obj.name=='Retained_authored_warden_costume' and index in allowed:
                require(vertex.co.z==old[2],'original boot ground/height preserved')
            else:require(tuple(vertex.co)==old,'unchanged non-boot/upper-shaft vertex '+obj.name+str(index))
    require(len(modified)>0,'small boot change applied')
    current_costume=bpy.data.objects['Retained_authored_warden_costume']
    reductions={}
    for side in (-1,1):
        ids=[i for i in indices if original[current_costume.name][i][0]*side>0 and original[current_costume.name][i][2]<.15]
        old=[original[current_costume.name][i] for i in ids];new=[current_costume.data.vertices[i].co for i in ids]
        ratios=[(max(p[k] for p in new)-min(p[k] for p in new))/(max(p[k] for p in old)-min(p[k] for p in old)) for k in (0,1)]
        require(all(abs(r-.94)<.00001 for r in ratios),'six-percent foot-only XY reduction')
        reductions[str(side)]=ratios
    tris=V.triangles(parts);require(tris==sum(p['triangles'] for p in before_meta['parts']),'same original triangle count')
    source_bounds=V.bounds(parts)
    gate=V.AUDIT.deliverable(parts,profile='render');require(gate['pass'],'mesh audit '+str(gate['errors']))
    bpy.ops.wm.read_factory_settings(use_empty=False);G.setup_scene();bpy.context.scene.render.threads=6
    bpy.ops.import_scene.fbx(filepath=str(OUT/'warden_restored.fbx'),use_anim=False)
    imported=[o for o in bpy.context.scene.objects if o.type=='MESH']
    require(len(imported)==5 and V.triangles(imported)==tris,'actual FBX mesh/triangle preservation')
    drift=max(abs(a-b) for x,y in zip(source_bounds,V.bounds(imported)) for a,b in zip(x,y));require(drift<.001,'FBX bounds within1mm')
    imported_maps=set()
    for obj in imported:
        require(len(obj.data.uv_layers)==1,'FBX UV retained '+obj.name)
        for mat in obj.data.materials:
            for node in mat.node_tree.nodes:
                if node.type=='TEX_IMAGE' and node.image:
                    path=Path(bpy.path.abspath(node.image.filepath));require(path.exists(),'FBX map resolves '+path.name);imported_maps.add(path.name)
    require(imported_maps==set(textures),'all original FBX maps retained')
    render('fbx_body')
    preserved=[]
    for folder in (BEFORE,ROOT/'assets_src/characters/mpfb_warden_outfit/2026-11-02'):
        receipt=json.loads((folder/'delivery.json').read_text())
        for file in receipt['files']:require(sha(folder/file['path'])==file['sha256'],'historical source preserved '+file['path'])
        preserved.append(dict(package=folder.relative_to(ROOT).as_posix(),files=len(receipt['files'])))
    for name in ('assets_src/characters/roster/manifest.json','assets_src/environment/manifest.json'):
        receipt=json.loads((ROOT/name).read_text())
        for file in receipt['files']:require(sha(ROOT/file['path'])==file['sha256'],'production preserved '+file['path'])
        preserved.append(dict(package=name,files=len(receipt['files'])))
    shutil.copytree(BEFORE/'licenses',OUT/'licenses',dirs_exist_ok=True)
    result=dict(status='TECHNICAL_PASS_AWAITING_USER_REVIEW',baseline='stage41',rejected='stage42',
        scope='original model, only existing low boots shrunk6%XY, tapering to exact original above0.32m',
        checks=checks,modified_boot_vertices=modified,foot_xy_ratios=reductions,triangles=tris,
        actual_fbx_reimport=True,maximum_fbx_bounds_drift_metres=drift,mesh_audit=gate,
        preserved=preserved,unchanged_texture_sha256=textures,os_input_used=False,gameplay_tested=False)
    (OUT/'verification.json').write_text(json.dumps(result,indent=2)+'\n')
    print('WARDEN_BOOTS_ONLY_PASS '+str(checks)+' assertions; original armor/pose/head/UV, six-percent foot shrink only')


if __name__=='__main__':main()
