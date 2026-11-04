# Latest handoff: published UI workshop and native Ashen exploration

The user asked to publish the UI skill to its own repository and continue the
next tasks. Publication and native stage75 implementation are delivered.
Owner034/slice034. See [native QA](../qa/2026-11-04-ashen-native-ui.md) for exact
commands, limits and evidence. Stage75 is automated PASS, awaiting native user
visual review and actual physical play; concept-family approval is already given.

Workshop is PRIVATE: https://github.com/KarolBautrel/dark-fantasy-ui-workshop.
v0.1.0 preserves the initial approved-reference/preparation baseline. Current
main/tag/release v0.2.0 is 0f98595a437e406eed6086b7fa496a23c0441ee7: 59 production
components, 70 admitted Aseprite sources/11 plates, prompts/fonts/notices and native
evidence. Six portable tests, clean remote checkout, all four Windows/Linux CI
jobs and actual independent Aseprite 59-PNG byte reproduction PASS. Installed
`$dark-fantasy-game-ui` is v0.2.0; prior installation is backed up. In-game fallback
remains packages/dark-fantasy-ui-workshop/. Do not revert to its former maturity.

CURRENT GAME UI is Ashen, replacing temporary textured72. New composer
ashen_expedition.gd preserves existing model/preview/confirm/event rules; maps use
independent vignettes, native labels and actual graph paths. All four visual themes
render in native fixtures. Actual campaign content is still Old Mine; the other
theme fixtures do not create playable forest/castle/dungeon adventures.
Existing nine accepted runtime templates and saved-seed behavior are unchanged.
The 15-layout library is still preparation data, NOT promoted runtime content.

Checks: focused378/0, cohesion692/0, route31/0, art99/0, party/HUD/session/domain/
beta-loop PASS, 300-seed generation quality PASS. Native delivery173checks/
30engine-local clicks/28captures and final modal61/18/12 PASS without errors or
warnings. Larger-resolution family proof258/45/42 PASS. These are no-focus native
fixtures, NOT physical desktop play. Last inspected 720p packing/event fixes:
fixed-cap padding, pinned Start, modal above every new root decoration, readable
focus text. World UI, approved actors, real saves and previous local changes stay
preserved. Only the workshop repository was committed/pushed; game work is local.

Review command: `& .\tools\qa\start_game.ps1 -Scene dungeon` from game root.
Default is generated; **Use Old Mine** gives the seven-location reference graph.
Native four-theme gallery: docs/design/exploration-native/2026-11-04/index.html.
Review1/L67-01 is pending actual user review;2..6 remain pending. Do not reopen
family concept selection, rejected72b or the expired two-hour/town batch.

Next unfinished implementation: domain adapter and acceptance promotion of the
15-layout library, versioned deterministic saves and independent length/difficulty.
Do not silently swap the legacy pool or reinterpret authored route_length as BFS
distance. Native UI feedback should be handled against034 before further visual
redesign. New game commits/pushes require the user's current instruction.
