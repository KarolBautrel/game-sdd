# Reusable HUD components

Status: accepted; stage3 automated and interactive gates passed
Date: 2026-11-01

Dungeon party cards and combat resource meters are reusable PackedScenes under
`scenes/ui/`. Their scripts accept already-resolved presentation values and do
not reference the combat resolver, dungeon model or session autoload. Controllers
own state selection and call configure/set_hp or set_amount. Components must
support independent instances, zero HP/resources and repeated refreshes.

`PixelSkin` centralizes imported texture scaling and nine-slice StyleBoxTexture
construction, using AssetCatalog. Cache keys include path, size and margins.
Style caches are per skin instance; callers may tune a returned style locally
without mutating another screen's skin. Flat fallback frames retain their
existing colors/margins. No new art or gameplay behavior is introduced.

Preserve the current party names/portraits/HP, passive input handling, compact
8px HP bars, combat meter geometry/tints and action feedback. Existing HUD
references may remain aliases during the incremental extraction. This stage
extracts bounded components, not the entire board/animation controller.

Proof: slice001; component isolation/zero-value tests, existing HUD/layout suites,
full regression and actual source dungeon/event/combat interaction on DISPLAY1.
