"""Background-only diagnostic: rigging, render, FBX roundtrip and library import."""
import argparse
import importlib
import json
from pathlib import Path
import sys

import bpy
from mathutils import Vector

parser = argparse.ArgumentParser()
parser.add_argument("--tool-root", type=Path, required=True)
parser.add_argument("--out", type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
assert bpy.app.background
args.tool_root = args.tool_root.resolve()
args.out = args.out.resolve()
args.out.mkdir(parents=True, exist_ok=True)
report = {"blender": bpy.app.version_string, "status": "RUNNING"}


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


# Prove the bundled rig generator actually produces a humanoid rig.
bpy.ops.preferences.addon_enable(module="rigify")
bpy.ops.object.armature_basic_human_metarig_add()
bpy.ops.pose.rigify_generate()
report["rigify"] = {"generated_bones": len(bpy.context.object.data.bones)}
assert report["rigify"]["generated_bones"] > 50

# Register the downloaded retargeter without persisting global user preferences.
sys.path.insert(0, str(args.tool_root / "retarget-5.2.0"))
retarget = importlib.import_module("retarget")
bpy.ops.preferences.addon_enable(module="retarget")
assert "retarget" in bpy.context.preferences.addons
report["retarget"] = {"registered": True, "source": "v5.2.0"}

clear()
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.5))
mesh = bpy.context.object
mesh.name = "SDD_Diagnostic_Only"
bpy.ops.object.armature_add(location=(0, 0, 0))
rig = bpy.context.object
rig.name = "SDD_Diagnostic_Rig"
group = mesh.vertex_groups.new(name=rig.data.bones[0].name)
group.add(list(range(len(mesh.data.vertices))), 1, "REPLACE")
modifier = mesh.modifiers.new("Skin", "ARMATURE")
modifier.object = rig
mesh.parent = rig
bone = rig.pose.bones[0]
bone.rotation_mode = "XYZ"
for frame, angle in [(1, 0), (8, 0.3), (16, 0)]:
    bone.rotation_euler[1] = angle
    bone.keyframe_insert(data_path="rotation_euler", frame=frame)
bpy.context.scene.frame_end = 16
bpy.context.scene.frame_set(8)
mat = bpy.data.materials.new("Diagnostic Ochre")
mat.diffuse_color = (0.35, 0.18, 0.055, 1)
mesh.data.materials.append(mat)
bpy.ops.object.camera_add(location=(3, -4, 3))
camera = bpy.context.object
camera.rotation_euler = (Vector((0, 0, 0.5)) - camera.location).to_track_quat("-Z", "Y").to_euler()
camera.data.type = "ORTHO"
camera.data.ortho_scale = 2.6
scene = bpy.context.scene
scene.camera = camera
bpy.ops.object.light_add(type="AREA", location=(2, -3, 5))
bpy.context.object.data.energy = 600
bpy.context.object.data.shape = "DISK"
bpy.context.object.data.size = 4
scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 8
scene.render.resolution_x = 256
scene.render.resolution_y = 256
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.filepath = str(args.out / "diagnostic.png")
bpy.ops.wm.save_as_mainfile(filepath=str(args.out / "diagnostic.blend"))
bpy.ops.render.render(write_still=True)
bpy.ops.export_scene.fbx(filepath=str(args.out / "diagnostic.fbx"),
                         object_types={"MESH", "ARMATURE"}, add_leaf_bones=False,
                         bake_anim=True, bake_anim_use_all_actions=False,
                         bake_anim_use_nla_strips=False)
assert (args.out / "diagnostic.png").stat().st_size > 100
clear()
bpy.ops.import_scene.fbx(filepath=str(args.out / "diagnostic.fbx"))
report["fbx_roundtrip"] = {"meshes": sum(o.type == "MESH" for o in bpy.data.objects),
                           "rigs": sum(o.type == "ARMATURE" for o in bpy.data.objects),
                           "actions": len(bpy.data.actions)}
assert all(report["fbx_roundtrip"].values()), report["fbx_roundtrip"]
imported_rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")
bpy.context.scene.frame_set(1)
start = imported_rig.pose.bones[0].matrix.copy()
bpy.context.scene.frame_set(8)
end = imported_rig.pose.bones[0].matrix.copy()
motion_delta = sum(abs(start[r][c] - end[r][c]) for r in range(4) for c in range(4))
assert motion_delta > 0.05, "FBX animation exists but has no tested bone motion"
report["fbx_roundtrip"]["bone_matrix_delta"] = motion_delta

report["libraries"] = []
for slug, filename in [("universal-animation-library", "UAL1_Standard.glb"),
                       ("universal-animation-library-2", "UAL2_Standard.glb")]:
    path = next((args.tool_root / "animations" / slug).rglob(filename))
    clear()
    bpy.ops.import_scene.gltf(filepath=str(path))
    rigs = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    actions = sorted(a.name for a in bpy.data.actions)
    assert rigs and len(actions) >= 10
    report["libraries"].append({"file": str(path), "clip_count": len(actions),
                                "bone_counts": [len(o.data.bones) for o in rigs],
                                "actions": actions,
                                "frame_ranges": {a.name: list(a.frame_range) for a in bpy.data.actions}})
report["status"] = "PASS"
(args.out / "blender-smoke.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print("SDD_BLENDER_SMOKE_PASS", json.dumps({"clips": [x["clip_count"] for x in report["libraries"]],
                                            "fbx": report["fbx_roundtrip"]}))
