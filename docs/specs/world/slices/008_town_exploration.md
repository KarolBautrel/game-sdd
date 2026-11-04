# Town exploration acceptance sequence

Owner: ../008_town_exploration.md. Start with isolated stageA only.

1. Canonical TMX/map/space references validate; all three NPC approaches and gate
   connect, no spawn on a blocker. Projection/inverse roundtrip, diagonal input
   normalization and one-second distance are deterministic at30/60/144steps.
2. Held WASD/arrow actions walk, release/focus loss stops; wall/corner tests never
   tunnel out of authored cells. Distinct continuous feet, original cel durations
   and stable idle contacts. Followers follow valid breadcrumbs around obstacles.
3. Only nearest eligible NPC prompts. One interact press opens exact speaker/text;
   modal blocks motion, cancel restores movement without repeat. Current campaign
   profile and existing save bytes stay unchanged; no service transaction inA.
4. Native source render at720p/1080p/1440p: full characters, no cut heads, honest
   pilot label, visible exit/prompt, readable dialogue and focus/scroll bounds.
   Actual OS WASD +E/Escape is a separately recorded physical acceptance case.
5. StageB only: App entry/service/return at the town; no entry from mine/active run
   or pending road event. Purchases/recovery charge once through existing owners,
   failed writes remain atomic; travel costs remain in world002/003. Ordinary
   roundtrip/restart required before enabling a new default presentation.
6. StageC only: courtyard/inn door transition, retained anchor on return, wall/
   roof occlusion and final native-scale NPC/party art accepted separately.

Planned proof paths forA: town_exploration_tests.gd, native --views townpilot and
source map conversion check. StagesB/C are pending and must add their concrete
automated bridge/content proofs before implementation.
