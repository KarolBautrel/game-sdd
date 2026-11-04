# Resume: autonomous polish and courtyard pilot

Date2026-11-04. Active repo game_dir/sdd-game, main branch master. User authorized
about two hours (23:12Z..01:12Z), full computer control, ordered polish and push
after each episode. They rejected ugly dungeon connectors and allowed a different
representation. Do not restore the discarded graph pipes or flat UI prototype.

## Delivered checkpoint

-66 world-family dungeon redesign, published049ee82a: exact approved campaign
 materials/fonts, imagegen/Aseprite illustrated mine, editable sources and prompts.
-67 native dungeon UI, published48552c0a: illustration for the exact authored
 graph, restrained room states and passage list, preview before explicit travel,
 truthful light/cost/event decisions and exclusive pending-event focus.
-68 equipment, published97d95456: free/equipped counts and named owners, exact
 two-hand/offhand conflict reasons, stable item focus/category/scroll after changes.
-69 world, published016e99bb: route preview/confirm/cancel, food/time/danger,
 forecast arrival and return reserve; underfunded routes inspectable, no preview
 costs/rerolls. Source/release smoke inputs follow confirmation.
-70 forest/mine arenas, published20e8c82e50b61bf5d1c3a8c5432400b12d4c04ca:
 canonical TMX/derived maps, seven unchanged accepted actors, meaningful routes,
 cover/rises, proper woodland floor/names and compact720p battle chrome.
-71 full town plan world008 followed by isolatedA courtyard pilot: WASD/arrows,
 three party members following valid breadcrumbs, collision and three NPC
 conversations. Source art and eight archived town facings retained; tactical
 battle still SE/SW. This handoff is part of its publication commit.

No accepted character PNG/Aseprite/stride/pose edits. Source manifest metadata
newline drift was verified and repaired with old/new receipts; original visual
assets stayed byte-exact. No player campaign save used or overwritten by tests.

## Proof and limits

Full final regression:67/67checks PASS,56Python tests, all Godot suites/import/
6scene boots. Town1445/0; source town87native checks/24engine key events/9captures.
Arena2292/0, four normal simulated outcomes; native normal animated victories
48/43commands,718checks/205pointer events, complete attack/hit/death/walk clips.
Final Windows export/runtime smoke PASS, then exact PCK native play301checks /
30pointer events/16key events/26captures and campaign106checks/50pointer events/
12captures PASS. Both1080p/720p. PCK SHA256
5ef1242746a0ea653019896d6f02c87807c8575c131633b8c9ce7c5ba9a70bb1.
Reports: docs/qa/2026-11-04-*. Raw artifacts are ignored, not remote deliverables.

Physical acceptance stays OPEN. Earlier Sky/official CUA activation failed,
including a separately launched Project Manager. A fresh visible town preview
was launched near the end (task PID7348, window3145770, DISPLAY1) and its real
window was captured. Later Sky key/click calls returned, but no game action was
visually confirmed; do not call this completed gameplay or mark L67..71 passed.
The preview may still be open. Do not close unrelated processes or weaken OS
policy. Prior Project Manager window1902872 is also session-owned but left alone.

## Next work

Review commands: docs/qa/2026-11-04-preview-guide.md. Main campaign review uses
start_game.ps1 -Scene app -HeroEquipmentPilot, with a separate resumable QA save.
Dungeon/arena/courtyard modes are isolated. Courtyard: -Scene town-preview.

The town plan is complete; onlyA is implemented. B is optional App entry/NPC
service routing and safe return anchors through existing campaign transactions;
C is the inn interior and final civilian/environment art. Current town service
cards remain default. Do not describe the prototype as a finished city or infer
new art approval. Preserve user feedback before selecting the next bounded stage.
Physical source/campaign/art cases remain in live-test-scenarios.md. Full source
and package proofs permit the checkpoint publication but do not replace them.
