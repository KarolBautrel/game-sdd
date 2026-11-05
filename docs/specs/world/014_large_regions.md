# Large region geography

Stage81,2026-11-05: user approves stage80's map style and requests larger maps
that can be scrolled, with changing biomes. Preserve existing authored and v1
regions. Owners world010..013 retain simulation, costs, snapshots and contracts.

Generator version2 builds384x216 semantic cells: twice the width/height and four
times the terrain area of v1. Terrain/river/crossing/site/road order and safety
gates remain. Regional wet/dry climate zones and a second hill belt create
distinct forest/open-country/upland stretches within one seed; presets bias
their balance. Store three climate-zone centers/radii in the immutable snapshot
so renderer and generation agree. No expansion of current role/contract counts.

Keep v1 generation deterministic, existing snapshot bytes and authored r9 intact.
The foundry offers Classic(v1) and Large(v2), default Large for a fresh selector;
an active generated company selects its own version. Separate slots:
`qa_living_world_generated_v<version>_<preset>_<seed>.json`. Never overwrite v1
progress to create the larger variant. Unsupported/corrupt snapshots stay blocked.

Large regions have twice the physical distance per normalized coordinate.
Navigation movement/time traces, route estimates and every NPC use the same
scale; base character pace and terrain speed ratios remain. Camera operations
never advance time, issue courses or mutate campaign/resources/geography.

Proof: slice014, large_region_tests, generated session tests, schema examples,
v1 checksum fixtures, native larger-region travel and preservation receipts.
