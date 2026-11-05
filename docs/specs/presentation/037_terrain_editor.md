# Living-world terrain editor

Stage78. Domain owner: world/011_terrain_navigation.md.

Keep the accepted world illustration and leather/brass typography. A separate
native editor displays the exact map with a translucent optional semantic
overlay. Brush tools: road, plains, forest, hills, mountain slopes, water, peaks,
bridge/ford. A radius control, continuous drag strokes, sample by right-click,
undo/redo, overlay opacity, zoom/pan, reload, save and route-probe mode make
terrain corrections usable without editing JSON. The legend states movement
speed percentages and blocked classes. One drag is one undo operation.

Probe mode chooses start then destination and draws the actual weighted route,
or explains blocked/unreachable input. Save validates all required destinations
and uses the owning domain's atomic persistence. Feedback distinguishes saved,
unsaved, invalid and reloaded states. The editor never advances strategic time.
720p/1080p must fit readable controls with a large independent map viewport.
Provide a launcher scene `terrain-editor`; returning to the living pilot reloads
the semantic map, preserving the campaign. In the game, show terrain/cost under
the pointer and available bridge/ford positions without changing the artwork.

Proof: slice037, interface tests and minimized native GPU pointer review.
