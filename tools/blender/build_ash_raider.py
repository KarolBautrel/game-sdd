"""Author an original fitted raider mesh, retaining only the CC0 rig/motion.

Run in owned background Blender. --preview renders construction views only;
without it, render the complete directional action inventory as raw PNGs.
Final pixel normalization/export belongs to tools/aseprite/ash_raider.lua.
"""
import argparse
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument("--preview", action="store_true")
args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
SOURCE = ROOT / "assets_src/characters/ash_raider"
OUT = ROOT / "artifacts/character-pilot"
RAW = OUT / "raw"
OUT.mkdir(parents=True, exist_ok=True)
library = next((Path.home() / ".codex/tools/character-art/animations/universal-animation-library").rglob("UAL1_Standard.glb"))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(library))
rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")
rig.name = "AshRaider_Rig"
for obj in list(bpy.data.objects):
    if obj != rig:
        bpy.data.objects.remove(obj, do_unlink=True)
rig.animation_data.action = None
for track in list(rig.animation_data.nla_tracks):
    rig.animation_data.nla_tracks.remove(track)

image = bpy.data.images.load(str(SOURCE / "textures/ash_raider_albedo.png"))
materials = []
for name, roughness, metal in [("Weathered cloth and leather", .91, 0), ("Worn iron", .58, .65)]:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = image
    tex.interpolation = "Linear"
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metal
    materials.append(mat)


def solid(name, color, metal=0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Roughness"].default_value = .67
    bsdf.inputs["Metallic"].default_value = metal
    materials.append(mat)
    return len(materials) - 1


steel = solid("Cleaver steel", (.29, .31, .30), .72)
edge = solid("Worn cutting edge", (.53, .54, .49), .8)
dark = solid("Hood seam and glove", (.055, .038, .025))
brass = solid("Dull buckle and rivets", (.27, .19, .095), .5)
red = solid("Sash fold", (.17, .038, .029))
parts = []


def uv_for(point, normal, virtual=None):
    p = Vector(point) if virtual is None else Vector(virtual)
    # The reference front and inferred rear are separate; never mirror equipment.
    center = .152 if normal[1] < .12 else .594
    x = p.x if normal[1] < .12 else -p.x
    return (center + x * .274, .032 + .943 * p.z / 1.88)


def mesh_part(name, verts, faces, bone, material=0, virtuals=None):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(materials[material])
    layer = data.uv_layers.new(name="ReferenceAtlas")
    # Surface patches stay inside the reference's actual material. Projecting
    # every side to its silhouette samples the gray backdrop at hidden surfaces.
    patch = None
    if "Hood" in name: patch = (.58,.84,.61,.90)
    elif "Masked head" in name: patch = (.129,.813,.171,.916)
    elif "pauldron" in name: patch = (.09,.73,.115,.76)
    elif "upper sleeve" in name: patch = (.063,.61,.08,.68)
    elif "forearm" in name: patch = (.045,.51,.062,.60)
    elif "trousers" in name: patch = (.102,.32,.12,.41)
    elif "Boot" in name: patch = (.075,.08,.09,.14)
    elif "tasset" in name: patch = (.1,.43,.12,.51)
    elif "Sash" == name: patch = (.12,.54,.18,.58)
    elif "Brigandine" == name: patch = (.125,.59,.178,.73)
    minimum = Vector(tuple(min(p[k] for p in verts) for k in range(3)))
    span = Vector(tuple(max(p[k] for p in verts) - minimum[k] for k in range(3)))
    for polygon in data.polygons:
        for loop in polygon.loop_indices:
            vi = data.loops[loop].vertex_index
            point = data.vertices[vi].co
            if patch:
                s = (point.x-minimum.x)/max(span.x,.001)
                t = (point.z-minimum.z)/max(span.z,.001)
                layer.data[loop].uv = (patch[0]+(patch[2]-patch[0])*s,
                                       patch[1]+(patch[3]-patch[1])*t)
            else:
                layer.data[loop].uv = uv_for(point, polygon.normal,
                                             virtuals[vi] if virtuals else None)
        polygon.use_smooth = False
    group = obj.vertex_groups.new(name=bone)
    group.add(list(range(len(verts))), 1, "REPLACE")
    parts.append(obj)
    return obj


def shell(name, rings, bone, material=0, sides=16, gap=0):
    verts, faces = [], []
    for z, rx, ry, cy in rings:
        for i in range(sides):
            angle = -math.pi / 2 + gap + (2 * math.pi - 2 * gap) * i / (sides - 1 if gap else sides)
            verts.append((rx * math.cos(angle), cy + ry * math.sin(angle), z))
    for j in range(len(rings) - 1):
        for i in range(sides - 1 if gap else sides):
            a, b = j * sides + i, j * sides + (i + 1) % sides
            faces.append((a, b, b + sides, a + sides))
    if not gap:
        faces.extend([tuple(reversed(range(sides))), tuple(range((len(rings) - 1) * sides, len(rings) * sides))])
    return mesh_part(name, verts, faces, bone, material)


def ellipsoid(name, center, radii, bone, material=0):
    verts, faces = [], []
    for j in range(9):
        latitude = -.5 * math.pi + math.pi * (.002 + .996 * j / 8)
        for i in range(16):
            angle = i * 2 * math.pi / 16
            verts.append(tuple(center[k] + radii[k] * v for k, v in enumerate((
                math.cos(latitude) * math.cos(angle), math.cos(latitude) * math.sin(angle), math.sin(latitude)))))
    for j in range(8):
        for i in range(16):
            a, b = j * 16 + i, j * 16 + (i + 1) % 16
            faces.append((a, b, b + 16, a + 16))
    faces.extend([tuple(reversed(range(16))), tuple(range(128, 144))])
    return mesh_part(name, verts, faces, bone, material)


def limb(name, bone, radii, reference_start=None, reference_end=None, material=0):
    b = rig.data.bones[bone]
    a, end = b.head_local, b.tail_local
    axis = (end - a).normalized()
    u = axis.cross(Vector((0, 1, 0))).normalized()
    v = axis.cross(u).normalized()
    verts, faces, virtuals = [], [], []
    for j, (t, radius) in enumerate(radii):
        point = a.lerp(end, t)
        for i in range(12):
            angle = i * 2 * math.pi / 12
            offset = radius * (u * math.cos(angle) + .87 * v * math.sin(angle))
            verts.append(tuple(point + offset))
            if reference_start:
                neutral = Vector(reference_start).lerp(Vector(reference_end), t)
                neutral += Vector((offset.z, offset.y, 0))
                virtuals.append(tuple(neutral))
    for j in range(len(radii) - 1):
        for i in range(12):
            a0, b0 = j * 12 + i, j * 12 + (i + 1) % 12
            faces.append((a0, b0, b0 + 12, a0 + 12))
    faces.extend([tuple(reversed(range(12))), tuple(range(len(verts) - 12, len(verts)))])
    return mesh_part(name, verts, faces, bone, material, virtuals or None)


# Closed torso with a narrow neck and layered waist: volumes precede ornament.
shell("Brigandine", [(0.96,.17,.115,.027),(1.05,.19,.125,.02),
      (1.25,.232,.145,.018),(1.4,.22,.132,.022),(1.48,.13,.10,.022)], "spine_02")
shell("Sash", [(.96,.185,.13,.027),(1.005,.196,.14,.02),(1.06,.185,.128,.02)], "pelvis")
shell("Hood shoulder cowl", [(1.38,.25,.145,.025),(1.46,.27,.15,.03),
      (1.53,.15,.12,.025),(1.57,.115,.105,.025)], "spine_03")
ellipsoid("Masked head", (0,-.012,1.686), (.121,.111,.173), "Head")
shell("Hood shell", [(1.51,.155,.125,.016),(1.62,.17,.153,.021),
      (1.76,.151,.14,.024),(1.854,.087,.09,.03),(1.89,.009,.018,.035)],
      "Head", gap=.82)
# Hood crown closes the open shell above the brow, leaving a face opening.
shell("Hood brow", [(1.79,.143,.138,.026),(1.854,.087,.09,.03),
      (1.89,.009,.018,.035)], "Head")

for side, sign in [("l",1),("r",-1)]:
    limb("Cloth upper sleeve_"+side, "upperarm_"+side,
         [(-.08,.097),(.1,.107),(.55,.095),(.96,.072),(1.03,.072)],
         (sign*.23,.025,1.44),(sign*.31,.025,1.15))
    limb("Leather forearm_"+side, "lowerarm_"+side,
         [(-.05,.073),(.12,.078),(.48,.074),(.85,.057),(1.04,.053)],
         (sign*.31,.02,1.15),(sign*.38,0,.91))
    wrist = rig.data.bones["hand_"+side].head_local
    ellipsoid("Glove_"+side, tuple(wrist + Vector((sign*.038,-.003,0))),
              (.084,.056,.062), "hand_"+side, dark)
    limb("Padded trousers_"+side, "thigh_"+side,
         [(-.03,.094),(.14,.105),(.46,.108),(.76,.091),(1.025,.076)])
    limb("Boot shaft_"+side, "calf_"+side,
         [(-.02,.085),(.12,.092),(.3,.078),(.68,.07),(1.05,.067)])
    ellipsoid("Boot foot_"+side, (sign*.089,-.055,.075), (.085,.15,.08), "foot_"+side)
    # Split tassets follow the thigh so walking does not pin the two legs together.
    x = sign * .11
    mesh_part("Split tasset_"+side,
              [(x-sign*.095,-.132,.99),(x+sign*.1,-.13,.99),
               (x+sign*.115,-.15,.78),(x-sign*.085,-.15,.79),
               (x-sign*.095,-.115,.99),(x+sign*.1,-.115,.99),
               (x+sign*.115,-.128,.78),(x-sign*.085,-.128,.79)],
              [(0,1,2,3),(4,7,6,5),(0,4,5,1),(3,2,6,7),(0,3,7,4),(1,5,6,2)], "thigh_"+side)

# The right shoulder plate is genuine shell geometry; source atlas supplies wear.
shoulder = rig.data.bones["upperarm_r"].head_local
ellipsoid("Asymmetric right pauldron", tuple(shoulder + Vector((-.018,0,.018))),
          (.141,.122,.116), "upperarm_r", 1)
for z in (1.13,1.27,1.37):
    for x in (-.14,.11):
        ellipsoid("Brigandine rivet", (x,-.133,z), (.012,.009,.012), "spine_02", brass)
mesh_part("Sash hanging end", [(.055,-.148,1.01),(.125,-.146,.99),(.142,-.16,.74),
          (.095,-.165,.7),(.07,-.16,.82)], [(0,1,2,3,4)], "pelvis", red)
solid_buckle = ellipsoid("Waist buckle", (-.045,-.147,1.01), (.032,.013,.023), "pelvis", brass)

# Place a real cleaver in the animated hand, then convert its vertices to bind
# space. The palm socket is evaluated from the selected idle pose, not guessed
# from an unrelated global arm orientation.
idle = bpy.data.actions["Sword_Idle"]
rig.animation_data.action = idle
bpy.context.scene.frame_set(8)
bpy.context.view_layer.update()
hand = rig.pose.bones["hand_r"]
deform = hand.matrix @ rig.data.bones["hand_r"].matrix_local.inverted()
to_bind = deform.inverted()
grip = hand.head + (hand.tail - hand.head).normalized() * .045
blade_axis = Vector((-.08,-.26,-.96)).normalized()
wide = Vector((1,0,-.08)).normalized()
thick = blade_axis.cross(wide).normalized()


def weapon_prism(name, points, thickness, material):
    verts = [tuple(to_bind @ (grip + wide*x + blade_axis*y + thick*z))
             for z in (-thickness/2, thickness/2) for x,y in points]
    n = len(points)
    faces = [tuple(reversed(range(n))), tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh_part(name, verts, faces, "hand_r", material)


weapon_prism("Cleaver leather grip", [(-.022,-.11),(.022,-.11),(.022,.07),(-.022,.07)], .042, dark)
weapon_prism("Cleaver iron guard", [(-.085,.055),(.085,.055),(.085,.084),(-.085,.084)], .04, steel)
weapon_prism("Cleaver blade", [(-.04,.085),(.055,.085),(.12,.39),(.08,.56),(-.065,.50)], .025, steel)
weapon_prism("Cleaver bevel edge", [(.055,.09),(.12,.39),(.08,.56),(.058,.534),(.099,.385)], .027, edge)

# Join to one weighted render mesh, preserving all semantic material slots/UVs.
rig.animation_data.action = None
bpy.ops.object.select_all(action="DESELECT")
for part in parts: part.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.join()
actor = bpy.context.object
actor.name = "AshRaider_OriginalMesh"
modifier = actor.modifiers.new("Deform", "ARMATURE")
modifier.object = rig
actor.parent = rig
for action in bpy.data.actions:
    action.use_fake_user = True

actions = {"pose":("Sword_Idle",4),"walk":("Walk_Loop",8),
           "combat":("Sword_Attack",8),"hit":("Hit_Chest",4),"death":("Death01",8)}
selected_actions = [bpy.data.actions[name] for name, _ in actions.values()]
for action in list(bpy.data.actions):
    if action not in selected_actions:
        bpy.data.actions.remove(action)

scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 12
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.view_settings.view_transform = "Khronos PBR Neutral"
scene.world = bpy.data.worlds.new("Neutral studio")
scene.world.use_nodes = True
scene.world.node_tree.nodes.get("Background").inputs[0].default_value = (.28,.28,.28,1)
scene.world.node_tree.nodes.get("Background").inputs[1].default_value = .65
for name, location, energy, size in [("Key",(-3,-4,6),420,4),("Fill",(4,-1,3),140,4),("Rim",(0,4,4),280,3)]:
    bpy.ops.object.light_add(type="AREA", location=location)
    light = bpy.context.object
    light.name = name
    light.data.energy = energy
    light.data.shape = "DISK"
    light.data.size = size
    light.rotation_euler = (-light.location + Vector((0,0,1))).to_track_quat("-Z","Y").to_euler()
bpy.ops.object.camera_add()
camera = bpy.context.object
camera.name = "Directional orthographic camera"
camera.data.type = "ORTHO"
scene.camera = camera


def set_action(action_name, t):
    action = bpy.data.actions[action_name]
    rig.animation_data.action = action
    start, end = action.frame_range
    frame = float(start + (end-start)*t)
    scene.frame_set(math.floor(frame), subframe=frame % 1)
    bpy.context.view_layer.update()
    rig.location = (0,0,0)
    if action_name == "Death01":
        pelvis = rig.pose.bones["pelvis"].head
        rest = rig.data.bones["pelvis"].head_local
        rig.location.x = rest.x - pelvis.x
        rig.location.y = rest.y - pelvis.y
    bpy.context.view_layer.update()


def camera_view(yaw, elevation=27, target_z=.95, ortho=4.2):
    azimuth, pitch = math.radians(yaw), math.radians(elevation)
    target = Vector((0,0,target_z))
    camera.location = target + Vector((math.sin(azimuth)*6*math.cos(pitch),
                                      -math.cos(azimuth)*6*math.cos(pitch),6*math.sin(pitch)))
    camera.rotation_euler = (target-camera.location).to_track_quat("-Z","Y").to_euler()
    camera.data.ortho_scale = ortho
    bpy.context.view_layer.update()


set_action("Sword_Idle", .2)
camera_view(315)
scene.render.resolution_x = scene.render.resolution_y = 512
SOURCE.mkdir(parents=True, exist_ok=True)
# Preserve a useful editable source with its complete rig/clips and relative atlas.
image.filepath = "//textures/ash_raider_albedo.png"
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "ash_raider.blend"))
triangles = sum(len(p.vertices)-2 for p in actor.data.polygons)
assert triangles < 15000
assert all(v.groups for v in actor.data.vertices)
report = {"character":"ash_raider","triangles":triangles,"vertices":len(actor.data.vertices),
          "bones":len(rig.data.bones),"visible_source":"original authored mesh; no mannequin",
          "actions":{key:{"clip":clip,"frames":count} for key,(clip,count) in actions.items()},
          "texture":"textures/ash_raider_albedo.png","reference":"reference.png",
          "source_motion":"Quaternius UAL1 Standard CC0","frame_size":[448,352],
          "pivot":[224,266],"orthographic_scale":4.2,"camera_elevation":27,
          "frame_count":sum(c for _,c in actions.values())*8}

if args.preview:
    for label, yaw, elev in [("front",0,4),("side",90,4),("rear",180,4),("game",315,27)]:
        camera_view(yaw,elev,ortho=2.3)
        scene.render.filepath = str(OUT / ("model-"+label+".png"))
        bpy.ops.render.render(write_still=True)
    for label, clip, t in [("attack","Sword_Attack",.55),("hit","Hit_Chest",.5),("death","Death01",1)]:
        set_action(clip,t)
        camera_view(315)
        scene.render.filepath = str(OUT / ("model-"+label+".png"))
        bpy.ops.render.render(write_still=True)
else:
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 4
    scene.render.resolution_x, scene.render.resolution_y = 448,352
    directions = {"south":0,"south_west":45,"west":90,"north_west":135,
                  "north":180,"north_east":225,"east":270,"south_east":315}
    for action,(clip,count) in actions.items():
        folder = RAW/action
        folder.mkdir(parents=True,exist_ok=True)
        for direction, yaw in directions.items():
            camera_view(yaw)
            for index in range(count):
                t = index / (count if action in ("pose","walk") else count-1)
                set_action(clip,t)
                scene.render.filepath = str(folder/f"ash_raider_{direction}_{action}_{index:03}.png")
                bpy.ops.render.render(write_still=True)
            print("SDD_RENDER",action,direction,flush=True)

# Export only deliverable mesh/rig, with all five compatible clips and no studio.
set_action("Sword_Idle", .2)
bpy.ops.object.select_all(action="DESELECT")
actor.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.fbx(filepath=str(SOURCE/"ash_raider.fbx"), use_selection=True,
                        object_types={"MESH","ARMATURE"}, add_leaf_bones=False,
                        axis_forward="-Z",axis_up="Y",path_mode="RELATIVE",
                        bake_anim=True,bake_anim_use_all_actions=True,bake_anim_use_nla_strips=False)
(SOURCE/"model-manifest.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
print("SDD_MODEL_COMPLETE",json.dumps(report),flush=True)
