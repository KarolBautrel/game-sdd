# Modular illustrated region symbols

Generated through the built-in imagegen tool using the approved world_atlas.png
as a style reference. Original atlas pixels are unchanged. Prompt/provenance:
prompts.json. Raw1254x1254 transparent source is preserved as generated-source.png.

Aseprite normalization/source/export: tools/aseprite/region_symbols.lua. It
separates the4x4 cells into sixteen named layers, removes saturated red matte
residue, softens clipped ground fringes and pads to384px cells in a1536px atlas.
Ground pivots are192,350. No scene labels, navigation or collision are baked in.
Editable source: assets_src/aseprite/region_symbols/region_symbols.aseprite.
Runtime: assets/ui/world/region_symbols.png. Repeat with from_editable=1 to
export only; omit it to reproduce normalization from the raw source.

The second imagegen source, ground-wash-source.png (1672x941), is a single
continuous unlabelled earth wash, not a repeated tile. Its exact English prompt
and provenance are in ground-prompt.json. Editable ground_wash.aseprite and
runtime assets/ui/world/ground_wash.png use the same Lua export command.
manifest.json records SHA256 for both raw sources, English prompts, editable
sources, runtime PNGs and the normalization/export script. Exporting from the
editable sources has been checked for exact runtime byte equality.

The generator/renderer place these symbols from actual semantic terrain/site
positions. Native labels, rivers, roads, crossings and world parties remain data
driven. Visual approval is pending native generated-region review.
