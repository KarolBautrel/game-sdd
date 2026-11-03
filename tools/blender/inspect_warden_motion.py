"""Read-only source geometry probe for presentation018 joint fitting."""
import json
from pathlib import Path
import bpy

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'artifacts/warden-motion'
OUT.mkdir(parents=True,exist_ok=True)

def bounds(o):
    pts=[o.matrix_world@v.co for v in o.data.vertices]
    return [[round(min(p[k] for p in pts),5) for k in range(3)],
            [round(max(p[k] for p in pts),5) for k in range(3)]]

bpy.ops.wm.open_mainfile(filepath=str(ROOT/'assets_src/characters/surface_refinement/2026-11-02/02_warden/02_warden.blend'))
source=[dict(name=o.name,vertices=len(o.data.vertices),bounds=bounds(o))
        for o in bpy.data.objects if o.type=='MESH' and o.name.startswith('SOURCE_')]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'assets_src/characters/mpfb_warden_boots_only/2026-11-02/warden_restored.blend'))
names=['Retained_authored_warden_costume','MPFB_coherent_head_and_neck','MPFB_eyes','MPFB_hair','MPFB_eyebrows']
meshes=[dict(name=n,vertices=len(bpy.data.objects[n].data.vertices),bounds=bounds(bpy.data.objects[n])) for n in names]
o=bpy.data.objects[names[0]]
neighbors=[[] for _ in o.data.vertices]
for e in o.data.edges:
    a,b=e.vertices;neighbors[a].append(b);neighbors[b].append(a)
unseen=set(range(len(neighbors)));components=[]
while unseen:
    stack=[next(iter(unseen))];ids=set()
    while stack:
        i=stack.pop()
        if i in ids:continue
        ids.add(i);stack.extend(n for n in neighbors[i] if n not in ids)
    unseen.difference_update(ids)
    pts=[o.data.vertices[i].co for i in ids]
    components.append(dict(vertices=len(ids),bounds=[[round(min(p[k] for p in pts),5) for k in range(3)],[round(max(p[k] for p in pts),5) for k in range(3)]]))
(OUT/'geometry-probe.json').write_text(json.dumps(dict(source_parts=source,accepted_meshes=meshes,components=sorted(components,key=lambda c:-c['vertices'])),indent=2))
print('WARDEN_GEOMETRY_PROBE',len(source),len(components))
