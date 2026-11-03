# Slice018: fitted rig, idle/walk/sword pilot

Owner [presentation018](../018_warden_motion_pilot.md).

Stage44 — binding gate:
1. The actual approved stage43 package and production hashes remain unchanged.
2. Five rest meshes retain exact positions/topology/UVs/materials/texture bytes.
3. Fitted biped hierarchy; all vertices normalized, at most4 influences; rigid
   props/plates retain shape. No opposite-side limb influence.
4. Inspect actual placement, bent elbow/knee, raised arm, squat and head poses,
   including joint closeups. Record limits of tested joint motion.

Stage45 — motion gate (only after stage44 technical PASS):
1. Three distinct24fps clips; idle/walk close after one cycle and attack returns
   to its initial ready pose. Beat table records the attack's anticipation/strike.
2. Every-frame tests: planted sole travel<1mm in world space, no floor penetration
   below1mm, continuous quaternions and stable grip attachment. Record clearance.
3. Actual animated FBX reimport has the five original meshes plus sword, correct
   rig/three actions and non-static evaluated deformation.
4. Inspect representative actual renders, contact and joint sheets, all four
   views. Provide a local looped player at1x; report whether continuous playback
   and Godot testing actually occurred. User motion approval remains pending.
5. Validator/diff checks, persisted QA reports and handoff. All61 physical cases
   remain NOT_RUN. No runtime asset or rejected outfit change.
