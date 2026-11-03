"""Read-only diagnosis of the stage40 warden's actual face projection source."""
import hashlib
import json
from pathlib import Path
import bpy

ROOT=Path(__file__).resolve().parents[2]
FOLDER=ROOT/'assets_src/characters/surface_refinement/2026-11-02/02_warden'
SOURCE=FOLDER/'02_warden.blend'
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
head=bpy.data.objects['SOURCE_CC0_derived_anatomical_face_and_neck']
uv=head.data.uv_layers['Reference_front']
mat=head.data.materials[0]
front_node=next(n for n in mat.node_tree.nodes if n.type=='UVMAP' and n.uv_map=='Reference_front')
front_images=[link.to_node.image for link in front_node.outputs[0].links if link.to_node.type=='TEX_IMAGE']
assert len(front_images)==1 and front_images[0],'expected one image connected to the front projection UV node'
source_image=front_images[0]
width,height=source_image.size[:]
assert width>0 and height>0,'source image is not loaded'
pixels=[]
for poly in head.data.polygons:
    if 1.61<poly.center.z<1.79 and poly.normal.y<-.3 and abs(poly.center.x)<.07:
        pixels.extend((uv.data[i].uv.x*width,(1-uv.data[i].uv.y)*height) for i in poly.loop_indices)
assert pixels,'face ROI has no polygons'
lo=[min(p[i] for p in pixels) for i in range(2)]
hi=[max(p[i] for p in pixels) for i in range(2)]
report=dict(source=SOURCE.relative_to(ROOT).as_posix(),source_sha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
    source_image_name=source_image.name,source_image_size=[width,height],
    selected_region='front-facing head faces z1.61..1.79m, abs(x)<0.07m; approximate central-face ROI, not a full anatomical segmentation',
    source_pixel_bounds=[lo,hi],source_pixel_span=[hi[i]-lo[i] for i in range(2)],
    projection_uv_maps=[n.uv_map for n in mat.node_tree.nodes if n.type=='UVMAP'],
    shared_head_material_parts=[o.name for o in bpy.data.collections['AUTHORING - anatomy and tailored gear'].objects if o.type=='MESH' and mat in list(o.data.materials)],
    scope='read-only diagnosis; no source model saved')
out=ROOT/'artifacts/face-source-diagnosis.json';out.parent.mkdir(exist_ok=True)
out.write_text(json.dumps(report,indent=2)+'\n')
print('FACE_SOURCE_DIAGNOSIS '+json.dumps(report))
