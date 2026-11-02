"""Re-import delivery FBX and assert geometry, textures, skin and all five clips."""
import json
from pathlib import Path
import bpy

root = Path(__file__).resolve().parents[2]
source = root / "assets_src/characters/ash_raider"
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(source / "ash_raider.fbx"))
meshes = [o for o in bpy.data.objects if o.type == "MESH"]
rigs = [o for o in bpy.data.objects if o.type == "ARMATURE"]
assert len(meshes) == len(rigs) == 1
actor, rig = meshes[0], rigs[0]
assert len(rig.data.bones) == 65
assert actor.data.uv_layers and all(v.groups for v in actor.data.vertices)
assert sum(len(p.vertices)-2 for p in actor.data.polygons) == 5287
images = [i for i in bpy.data.images if i.name not in ("Render Result", "Viewer Node")]
assert images and all(i.size[0] > 0 for i in images)
motions = {}
for clip in ("Sword_Idle", "Walk_Loop", "Sword_Attack", "Hit_Chest", "Death01"):
    action = next(a for a in bpy.data.actions if clip in a.name)
    rig.animation_data.action = action
    begin, end = action.frame_range
    bpy.context.scene.frame_set(int(begin+(end-begin)*.2))
    before = [b.matrix.copy() for b in rig.pose.bones]
    bpy.context.scene.frame_set(int(begin+(end-begin)*.7))
    delta = sum(abs(m[r][c]-b.matrix[r][c]) for m,b in zip(before,rig.pose.bones) for r in range(4) for c in range(4))
    assert delta > .001, (clip, delta)
    motions[clip] = {"range":list(action.frame_range),"bone_motion_delta":delta}
report = {"status":"PASS","meshes":1,"bones":65,"triangles":5287,
          "uv":True,"all_vertices_weighted":True,"textures":[i.name for i in images],"motions":motions}
out = root/"artifacts/character-pilot/fbx-verification.json"
out.write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
print("SDD_RAIDER_FBX_PASS",json.dumps(report))
