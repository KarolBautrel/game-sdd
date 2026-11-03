"""Re-import each delivered FBX and verify real mesh/UV/weights/clip motion."""
import argparse
import json
from pathlib import Path
import sys
import hashlib
import bpy

ROOT=Path(__file__).resolve().parents[2]
PROFILES={row["id"]:row for row in json.loads((ROOT/"resources/data/presentation/original_roster.json").read_text())["characters"]}
parser=argparse.ArgumentParser();parser.add_argument("--ids",required=True)
parser.add_argument("--report")
args=parser.parse_args(sys.argv[sys.argv.index("--")+1:])
reports=[]
for ident in args.ids.split(","):
    folder=ROOT/"assets_src/characters/roster"/ident
    assert not (folder/".rendering").exists(),ident+" incomplete source render"
    metadata=json.loads((folder/"model.json").read_text())
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(folder/(ident+".fbx")))
    meshes=[o for o in bpy.data.objects if o.type=="MESH"]
    rigs=[o for o in bpy.data.objects if o.type=="ARMATURE"]
    assert len(meshes)==len(rigs)==1,ident
    mesh,rig=meshes[0],rigs[0]
    # FBX importer auto-connects coincident joint heads/tails. Blender then
    # suppresses keyed local translation, although the FBX contains it. Match
    # the authored unconnected rig (and engine Skeleton transforms) explicitly.
    bpy.context.view_layer.objects.active=rig
    bpy.ops.object.select_all(action="DESELECT");rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    for bone in rig.data.edit_bones:bone.use_connect=False
    bpy.ops.object.mode_set(mode="OBJECT")
    triangles=sum(len(p.vertices)-2 for p in mesh.data.polygons)
    assert triangles==metadata["triangles"] and mesh.data.uv_layers,ident
    assert all(v.groups for v in mesh.data.vertices),ident
    assert len(rig.data.bones)==metadata["bones"],ident
    images=[i for i in bpy.data.images if i.name not in ("Render Result","Viewer Node")]
    assert images and all(i.size[0]>0 for i in images),ident
    movement={}
    ground={}
    for kind,name in metadata["actions"].items():
        action=next(a for a in bpy.data.actions if name in a.name)
        rig.animation_data.action=action
        start,end=action.frame_range
        bpy.context.scene.frame_set(int(start+(end-start)*.17))
        before=[b.matrix.copy() for b in rig.pose.bones]
        bpy.context.scene.frame_set(int(start+(end-start)*.65))
        delta=sum(abs(m[r][c]-b.matrix[r][c]) for m,b in zip(before,rig.pose.bones) for r in range(4) for c in range(4))
        assert delta>.00001,(ident,kind,delta)
        movement[kind]=delta
        if PROFILES[ident]["weapon"]=="spear":
            hand=mesh.vertex_groups["hand_r"].index
            vertices=[v.index for v in mesh.data.vertices if any(g.group==hand and g.weight>.5 for g in v.groups)]
            assert vertices
            minimum=1000.0
            for sample in range(65):
                value=start+(end-start)*sample/64
                bpy.context.scene.frame_set(int(value),subframe=value%1)
                bpy.context.view_layer.update()
                evaluated=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
                minimum=min(minimum,min((evaluated.matrix_world @ evaluated.data.vertices[i].co).z for i in vertices))
            assert minimum>=-.025,(ident,kind,"weapon below ground",minimum)
            ground[kind]=round(minimum,5)
    reports.append({"id":ident,"status":"PASS","triangles":triangles,"bones":len(rig.data.bones),
                    "uv":True,"weighted":True,"texture":True,"motion":movement,"weapon_min_z":ground,
                    "fbx_sha256":hashlib.sha256((folder/(ident+".fbx")).read_bytes()).hexdigest()})
    print("ROSTER_FBX_PASS",ident,flush=True)
name="fbx-"+args.ids.replace(",","-")+".json"
if len(name)>100:name="fbx-batch-"+hashlib.sha256(args.ids.encode()).hexdigest()[:12]+".json"
if args.report:
    assert Path(args.report).name==args.report and args.report.endswith(".json")
    name=args.report
out=ROOT/"artifacts/roster"/name
out.parent.mkdir(parents=True,exist_ok=True)
delivery={"status":"PASS","blender":bpy.app.version_string,"import_policy":"preserve authored unconnected joints and animated bone translations","models":reports}
out.write_text(json.dumps(delivery,indent=2)+"\n")
if set(args.ids.split(","))==set(PROFILES) and len(reports)==27:
    (ROOT/"assets_src/characters/roster/fbx-check.json").write_text(json.dumps(delivery,indent=2)+"\n")
