# Combat encounter authoring v1

Status: implemented; automated PASS; live tests deferred by user.
Date:2026-11-01. Stage11 / queue18.

## Ownership

Encounters remain JSON under resources/data/combat_encounters, validated by the
existing encounter schema. Maps remain TMX -> map-v2 JSON under tooling003.
Archetypes, item profiles and loadouts retain their existing domain ownership.
This spec owns discovery and authoring integrity, not combat calculations.

## Rules

The scenario picker reads an exported JSON catalogue at
`resources/data/combat_scenarios/catalogue.json`, schema sdd.combat-scenarios-v1.
Each row has a unique stable id, nonempty label and res:// encounter JSON path.
Order is explicit. Preserve existing ten scenarios and default entry; adding a
scenario requires data/catalogue changes, never controller branches/constants.
Runtime validates catalogue shape/ids/paths and fails explicitly for invalid
data. Returned options are independent copies of cached canonical entries.

Validation checks catalogue schema, duplicate ids, existing encounter/map paths,
unit ids/unique unblocked in-bounds starts, at least one living unit per team,
turn order/active-unit references, archetype references, inherited/overridden
loadout item and equipped weapon references, and referenced background/decor
files. Background is optional for legacy procedural boards; when present it
must exist. Validate mapped visual defaults too. Never rewrite TMX or canonical
encounters from the workbench's copy save path.

Reference `clearing_crossfire` uses the existing TMX clearing, two roster heroes,
melee/archer archetypes and existing item/visual profiles. It inherits map visual
defaults and demonstrates discovery without controller edits. Its authored idea
is a south-west party approach toward a north-east melee guard and east archer,
with existing cover and connected raised areas on the clearing map.

Authoring workflow: choose/create map and convert/validate -> author encounter
units/profiles -> register catalogue row -> validate -> picker load -> workbench
safe-copy edit/save/reload -> F5 play/F6 return -> actual live review. Reference
units' positions are explicit; map test-spawn metadata is an authoring aid and
does not silently relocate combat units.

## Proof

Slice100; Python negative catalogue/reference tests and full validation;
`combat_encounter_authoring_tests.gd` loads the new scenario through the actual
controller, resolves map/roles and executes normal movement. It also checks an
isolated draft save/reload. Existing map_authoring/editor suites prove draft
handoff. Actual new encounter and workbench flow: live L11-01/02, NOT_RUN.
