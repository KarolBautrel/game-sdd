# Dungeon UI skill research

Checked: 2026-11-03. Primary sources were opened and read; search-directory
listings alone were not treated as proof. No external installer was executed and
no additional agent skill/plugin was installed during this design task.

The previous world-map workflow already installed the two useful native game UI
skills. Its reproducible record is [campaign UI tooling](../campaign-ui/TOOLING.md).
We retain that foundation rather than duplicate installations under new names.

| Source | Relevant contribution | Decision for this project |
|---|---|---|
| [gamedev-skills/game-ui-ux](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/game-ui-ux/SKILL.md) | HUD hierarchy, responsive layout, screen stack, focus and event-driven updates | Use the already installed skill; complement with installed godot-ui-control |
| [OpenAI game-ui-frontend](https://github.com/openai/plugins/blob/main/plugins/game-studio/skills/game-ui-frontend/SKILL.md) | Protect route/playfield reading, contextual disclosure, theme before coding, restrained motion | Best additional research reference for this game's interface composition; browser guidance, not a Godot implementation package |
| [Anthropic frontend-design](https://github.com/anthropics/skills/blob/main/skills/frontend-design/SKILL.md) | Deliberate material/typographic identity, real content, design-plan critique before building | Useful visual review checklist for the browser mockup; no web framework dependency in the game |
| [Scenario Godot UI](https://github.com/scenario-labs/skills/blob/main/skills/game-engines/godot/scenario-godot-ui/SKILL.md) | Native themes, containers, focus, scale and screenshot review | Supplementary technical reference; much overlaps installed skills and its mobile/macOS assumptions do not set this Windows desktop project's scope |

## Version receipts

Last commit affecting each inspected file at research time (GitHub API):

- openai/plugins game-ui-frontend: `d965fdc57d1f872f52bcdb10c9e1cbf922a8a761`.
- anthropics/skills frontend-design: `41bbe19d1a1a7eaab5e7bb9050a417e5c6cffc8f`.
- gamedev-skills game-ui-ux: `1b71e6315900d9a4729fa4c0bb40f24052caa24b`.
- scenario-labs scenario-godot-ui: `b8544b9c86e0685844cc6effbb27f3885f744d3a`.

These are research pointers, not vendored skill copies or claims of a new
installation. The frontend-design sibling LICENSE.txt was checked (Apache-2.0);
Scenario declares MIT in its skill header. No third-party skill is redistributed
here, and future installation/redistribution should preserve its complete terms.

## Adaptation decisions

The browser HUD reference's low overlay budget applies to a 3D playfield. Our
room graph is itself the exploration interface: adapt its disclosure/hierarchy
principles rather than apply a universal 25% coverage cap. Its DOM advice belongs
only to the review mockup. Production remains Godot Control/Container/Theme.

The Scenario reference targets Godot4.7.2/macOS with mobile defaults. This project
is Godot4.7/Windows, 2560x1440 design size, desktop mouse/keyboard. Do not switch
the engine, base resolution, renderer or input/device scope as a side effect.

User correction2026-11-04: the shared skills did not make the first flat mockup
visually consistent with the approved world UI. The art workflow also needs its
actual generated/Aseprite-prepared material family. The revised mockup therefore
uses those exact frame/button/leather assets and a reference-generated/Aseprite
mine illustration. External generic frontend guidance is subordinate to the
approved campaign appearance; no new skill installation is needed for that.

No searched skill establishes our dark fantasy art direction by itself. That is
an authored design choice grounded in the approved campaign materials, readable
painted characters and actual dungeon verbs/state. Research is supporting method,
not a reason to replace accepted art or import an unrelated website template.

## Official engine checks

- [Godot4.7 containers](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_containers.html):
  containers own child layout; use nested rows/columns and size flags.
- [Godot4.7 keyboard/controller focus](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_navigation.html):
  initial focus, explicit neighbors and restoring focus after hidden panels.
- [Godot4.7 multiple resolutions](https://docs.godotengine.org/en/4.7/tutorials/rendering/multiple_resolutions.html):
  design size, stretch and UI scaling are separate from the actual window size.

## Existing evidence and inspection limits

Reviewed repository screenshots: campaign inventory, illustrated world map and
implemented dungeon, plus the dungeon scene/chrome, authored Old Mine graph,
resource/packing/event/camp/loot contracts and existing rendering harness. These
are previous captured evidence, not a newly observed live user session.

The new prototype is local HTML/CSS with actual repository art. Its screenshots
prove only browser composition. No Godot UI behavior, physical pointer/gamepad
feel, campaign victory or save/settlement acceptance is claimed from this task.
