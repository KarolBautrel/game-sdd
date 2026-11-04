# Latest handoff: dungeon visually accepted, return to the saved review queue

PUBLISHED: game-sdd/master checkpoint
`f0afad7cf534a12a4f69c038e8e7c7164e5c34e5`. Remote ref matches;175LFS objects/
154MB uploaded, no pending LFS push or uncommitted game changes after publication.
Full verification69/69 PASS, zero diagnostic errors. The current publication
request is handled; do not repeat it on a generic resume. Next is the equipment
review described below, after the user chooses to continue.

The user says the current dungeon work looks good and can be considered finished
for now. They request publication to the game repository and a reminder of the
points that preceded the detailed dungeon review. This is publication plus an
explanation request; do not start another implementation batch automatically.

Current Ashen dungeon appearance is USER_APPROVED_FOR_CURRENT_STAGE. Keep the
accepted art, fonts, frames, native state/route/cost behavior and portraits. Do
not reopen visual selection. Detailed physical full-flow actions were not
reported, so retain that technical QA gap without treating it as missing visual
approval. Existing automated/native evidence remains in
[stage75 QA](../qa/2026-11-04-ashen-native-ui.md).

Publish the coherent local dungeon work on game-sdd/master after checks. The game
repo is public. The full optional local `packages/dark-fantasy-ui-workshop/` copy
is ignored and remains preserved locally/in its separate private repository;
do not accidentally duplicate that private package into the public game repo.
The public game contains its own production assets, sources, prompts, research,
approved/rejected art history and native implementation. Checksummed historical
source files retain exact bytes. No force push or history rewrite is needed.

The original review queue is [saved here](../qa/2026-11-04-player-review-checklist.md).
Point1 (dungeon appearance) is accepted for now. Next is point2, equipment:

1. Equipment: ownership, hero assignments, two-handed/off-hand conflicts, retained
   selection/scroll, changing loadouts and persistence.
2. World journey: route preview/cancel/confirm, real costs, return reserve and
   returning to Ravenford, with UI/readability checks.
3. Forest Ambush: routes/cover, readable movement and attacks, ordinary victory
   or defeat without Debug Win.
4. Mine Breach: crossings, occlusion, movement/turn completion and normal battle.
5. Courtyard pilot: WASD, party followers/collision, three NPC conversations.
   Services/inn/final NPC art are future work, not delivered content.

Next review command from the game root:
`& .\tools\qa\start_game.ps1 -Scene app -HeroEquipmentPilot`.
The pilot uses a separate resumable QA campaign, preserving the real player's
save. The user's current request does not ask the agent to launch/control it.

The15-layout adapter, independent length/difficulty and further playable biomes
remain backlog; nine accepted runtime templates are still active. Do not let
that newer backlog replace the user's requested return to the earlier review
queue. The expired autonomous timer/town batch remains inactive. Private skill
v0.2.0 is already published and installed; no new skill publication is needed.
