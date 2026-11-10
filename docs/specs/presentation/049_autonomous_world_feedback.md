# Autonomous world feedback

Domain authority: [world025](../world/025_world_life_runtime.md). Stage103 adds
an explicit `autonomous-world` launch, separate v5 slot and native World inspector
tab to the accepted strategic map. Old default scenes and v3/v4 controls remain.

The same Ashen parchment/iron/crimson assets, serif, camera, minimap and safe
routes frame extra camp/ruin/outpost markers and moving rival/migration parties.
Interpolation uses the actual per-tick navigation trace, including turns; do not
draw straight shortcuts through blocked terrain. Extra sites do not mutate the
immutable original atlas. Inspect/focus is read-only; travel remains explicit.

World shows causal dated situations, exclusive contract deadlines and issuer,
earned payment, known rival actions, outpost control and dated district reports.
No exact secret treasury/enemy strength is exposed. One-day wait is an explicit
96tick ordinary advance that spends normal time/provisions/wages and is disabled
in a managed expedition. Existing pause and Jobs/Company clock rules remain.

Fixed occupied-site preparation has no reroll/source/difficulty controls. Its
forest/ruin skin and encounter derive from the same owned site data. Normal
combat and return settle through StrategicSession. A cleared entrance is disabled
until a new actor arrives with a new episode. Current save incompatibility is an
error; never silently reset or replace it.

Automated acceptance: world_life_interface_tests, life_expedition_tests and the
new scene boots. Physical review at720p/1080p/1440p remains AWAITING_INTERACTIVE.
