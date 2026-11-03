# Slice017: exact baseline restoration with boots-only reduction

Owner presentation017.

1. Source is the exact stage41 delivery; stage42 remains marked rejected.
2. Compare actual old/new meshes: only selected low-boot vertices change XY;
   all Z, non-boot vertices, topology, UVs and material bindings remain identical.
   Retain all four head/eye/hair/brow identities and all texture bytes.
3. Main boot footprint depth/width reduces modestly, at most6%; upper shaft fit
   and ground height remain unchanged. Inspect whole-body and boot closeups at
   matched camera/light; no new leg stance or armor is introduced.
4. Export/reimport the actual FBX, verify triangles/bounds/maps/UV and inspect its
   render. Preserve prior source/roster/world hashes; project checks pass.
5. Persist stage43 and milestone012; the next gate is user feedback, not automatic
   resumption of rejected outfit/animation/cast work. No live game cases closed.
