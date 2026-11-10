# Strategic-region interface

Stage95. Gameplay world018; proof [slice045](slices/045_strategic_region.md).
Reuse accepted campaign skin/fonts/frames, illustrated Large terrain, symbols
and camera. Reference: generated-live-1920x1080.png. No art replacement.

`StrategicWorld.tscn`, launcher `-Scene strategy`. Explicit new/resume uses a
separate seed-specific v3 slot; headless boot is memory only. Start paused.
Header: actual place/day/hour/gold/food/fatigue. Pause/1x/2x/4x, Space/numbers,
wheel zoom, RMB/MMB pan and minimap/company center match the living interface.
All six towns and three adventure anchors have native labels; actual armies /
cargo follow cost-based safe paths. Camera/inspection cannot issue travel orders.

Inspector tabs: Location, Factions, Jobs, Chronicle, Company. Independently scroll
at720p; text/actions stay clear of frame rails/footer. Jobs/Company pause time.
Rows retain focus/identity/scroll across ticks. Location has actual owner, price,
travel/inn/supplies and mine prepare/resume. Factions show public ownership /
stance/treaties/truce/military and company reputation, never hidden goals,
treasuries/inventory. Chronicle lists confirmed completed facts and time/cause.
Jobs expose actual cause, issuer/target/frozen rewards/progress and domain
rejection tooltips. Company uses owned supply/gear and existing legal services.
Keep Ashen expedition layout; return text/routes point back to this region.
No model switch before96. Native appearance/ordinary play L95-01/02 stay deferred
while desktop is withheld; headless bounds alone do not prove visual acceptance.
