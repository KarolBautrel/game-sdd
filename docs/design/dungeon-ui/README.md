# Dungeon interface redesign proposal

Date: 2026-11-04. Status: WORLD-FAMILY REVISION / AUTOMATED_PASS / AGENT_VISUAL_REVIEW.
The user requests internet skill research and a fresh dark fantasy exploration
interface plan before further combat play. The first flat proposal was rejected
as unlike the approved world-travel UI. The user then authorized about two hours
of staged native/gameplay polish, actual desktop control and a push after each
verified episode. See milestone022 for the active implementation queue.

Open [prototype.html](prototype.html) in a browser. It uses local project fonts,
portraits, room illustrations and supply icons. The review bar switches between
exploration, low light, corridor event, packing and reward fixtures. It is a
clickable composition study, not Godot runtime evidence or a working expedition.
Skill/source evaluation: [RESEARCH.md](RESEARCH.md).
Proposed durable contract: [presentation026](../../specs/presentation/026_dungeon_interface_redesign.md).
Design screenshots: [exploration](exploration-1920x1080.png),
[corridor obstacle](corridor-event-1920x1080.png), [packing](packing-1920x1080.png),
[low light](low-light-1920x1080.png), [reward](reward-1920x1080.png).
Browser evidence: [dated QA record](../../qa/2026-11-03-dungeon-ui-design.md).
Native stage67 GPU captures: [Old Mine](native-route.png) and
[destination preview](native-preview.png). The illustrated native backing is
enabled only for the exact matching authored graph; generated dungeons keep
data-driven room layouts and passage lists. Heavy decorative connectors are gone.

```powershell
Start-Process -FilePath "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\docs\design\dungeon-ui\prototype.html"
```

## Direction: the approved world-travel family, underground

An illustrated parchment chart carried through a cold abandoned mine. Use the
world UI's exact textured leather, engraved brass/iron corners and button exports,
with warm paper, sepia rock hatching, timber ruins, sparse lamp light and ominous
recesses. The party's lamp is the visual anchor. The map remains the main activity;
portrait health and supply pressure remain readable without opening a sheet.

Carry forward the approved campaign's Cinzel headings, Source Sans3 body type,
ivory text, leather, brass and familiar heroes. Recompose the dungeon while
preserving that concrete material system. The native-labeled illustrated mine
map parallels the region map; a parchment room inspector parallels the inventory
inspector. This supersedes the flat olive field and minimal hairline controls.
The rejected first composition is retained as prototype-v1-flat.html and
rejected-v1-exploration.png, not an accepted fallback or future style target.

This targets the existing connected-room exploration mode. It does not introduce
free walking, a city, a new camera, fog/scouting, stress, stamina or a new clock.
The previously drawn character directions and tactical SE/SW policy are untouched.

## Information hierarchy

1. Where the company is and what it can do next: current room, route and one
   primary room action. Selected destination and current location look different.
2. Whether it is safe to continue: light with its numeric level and named state,
   living party HP/effects and the supplies needed for the selected route/event.
3. What has been earned: compact expedition loot access and recent feedback.
4. Details on demand: journal, full effects, item descriptions and developer tools.

| Region | Normal exploration | Expanded state |
|---|---|---|
| Header | Dungeon name, current location, light, journal/loot/retreat access | Light tooltip explains existing effects; retreat confirmation uses real rules |
| Supply rail | Six semantic icons, owned carried counts, readable names/tooltips | Packing before departure; use actions after departure only when legal |
| Main field | Illustrated mine parchment, native room plates/states, real corridor links | Scroll through long maps without shrinking labels |
| Room inspector | Selected room image, short note, route consequence, one primary action | Known destination preview, combat entry, reward claim or finish at exit |
| Company rail | Bran and Torin portraits, numerical HP, effect badges | Read-only character/effect detail; no new formation editing |
| Feedback | One latest sentence, expandable expedition journal | Complete existing log, not a permanent wall of state data |

The browser game's 20–25% HUD budget found in research is not a literal quota
here: this game's room chart is itself an interactive interface. The transferable
rule is to protect route reading and avoid opening every detail surface at once.

## Layout and native size

- Design primary: 1920x1080. Retain the project's 2560x1440 reference and
  `canvas_items`/`expand`; do not change global project settings for one scene.
- At 1080p, reserve about 350–390px for a contextual inspector, 80–100px for the
  location/light header and 110–140px for the company rail. The remaining width
  and height belong to the chart. Figures are design targets, not fixed Godot
  offsets; implement with anchors and containers.
- Body and essential numerical values: at least 18 rendered pixels at 1080p
  (24 logical units at the existing 1440 reference), preferably 20 for decisions.
  Secondary notes may be 16px; no action, cost or lock relies on tiny captions.
- Use the two existing party members. Do not fill unused space with invented
  characters, slots or stats. Room art stays near its native 160x120 footprint;
  portraits near 128x128. New larger art needs a separate source/export pass.
- 1280x720: collapse the inspector to a focused drawer, compact the company rail,
  keep named supply tooltips, preserve normal room size and horizontal scrolling.
  Do not shrink the whole 1080p screen into unreadable text.
- 2560x1440 and 3840x2160: scale text and controls coherently and reveal more chart.
  3440x1440: extra width goes to the chart, not oversized sidebars.
- UI scale 125% and long Polish strings are implementation acceptance cases;
  this desktop proposal does not add mobile/touch requirements.

## Materials, palette and states

| Role | Target |
|---|---|
| Main substrate | Charcoal #151512 / deep worn leather, low texture contrast |
| Raised surface | #24231d, iron-dark edges and sparing engraved corners |
| Main text | Warm ivory #f1e7d2 |
| Secondary text | Warm grey #beb39b; check contrast over the final backing |
| Selection / lamp | Restrained brass #d9b773, clear outline and location symbol |
| Danger | Dried blood #a54f45 with a threat icon and a written state |
| Completed / safe | Desaturated sage #91a28a with a check mark/label |
| Note paper | Small warm vellum areas, dark readable ink #30231a |

Visited, current, selected, combat, locked and reward-ready must differ by shape,
icon or label as well as color. Selected is a brass outline; current has the
company marker and 'You are here'. Keyboard focus is an additional visible ring,
never confused with either. Avoid glowing edges around every room, animated
background noise, gold filigree around every number and decorative Gothic body text.

## Required screens and transitions

1. **Preparation:** same shell, a dedicated packing view with all six real supply
   counts, min/max/ownership limits, per-item packing costs, used/total capacity
   and a single Start expedition action. Current authored default is 7/7 points.
   No purchases or item grants inside this view.
2. **Exploration:** connected chart and compact room inspector. Clicking a room
   previews it; an explicit travel button commits the existing enter-room command.
   This preview/commit distinction is a proposed presentation change for review,
   not an implemented replacement for the current immediate room click.
3. **Route selection:** highlight the actual connecting corridor, show its existing
   light cost when known and explain non-adjacent/locked destinations. The fixture
   uses the authored crossing-to-guarded route with light_decay=1.
4. **Low light:** keep text/map/navigation readable; emphasize the lamp state and
   legal Use oil action. Atmospheric darkness must not hide critical UI or imply
   an unimplemented fog/scouting mechanic. No invented countdown timer.
5. **Corridor obstacle / room event:** one focused decision sheet; dim and disable
   background travel/supply/retreat commands. Show the actual event message,
   resource consumption and real available choices, including unavailable reasons.
   A forced decision cannot be bypassed by Escape or a decorative close button.
6. **Combat pending:** inspect current room, highlight Enter Combat, prevent
   travel/retreat exactly as the existing model requires. No combat rules move
   into the HUD. Preserve return to the same dungeon state after battle.
7. **Reward:** distinguish a claimable reward from already claimed expedition loot.
   One claim action, then a concise receipt. No fictional rarity, carry weight or
   guarantee of keeping loot before settlement. The fixture uses the real guarded
   cache payload: 7 gold, 12 XP and rusty_key.
8. **Recovery/camp:** show only legal commands with truthful prerequisites. Current
   camp requires a kit and food, a recoverable effect and no pending event/combat;
   consumes one kit, one food and one light. Do not promise individual healing
   target selection while the existing aggregate/target effect model owns it.
9. **Exit/retreat/result:** clearly separate finishing at a legal exit, permitted
   retreat and returning to the world after a settled run. Show actual kept/lost
   loot and injury consequences from the result; never a generic exit shortcut
   that silently abandons or duplicates a managed run.

The mockup illustrates exploration, low light, obstacle, preparation and reward.
Combat pending, recovery and result are specified here for a later Godot pilot;
they are not all simulated by the browser composition.

## Motion and sound brief

Use 120–180ms transitions for selection and drawer opening, with faster closing.
Only a change of light, a resolved event, injury or reward earns an emphasized
animation. A subtle lamp flicker is optional and disabled by reduced motion.
Room travel feedback follows a committed command; never consume supplies at the
end of an unrelated visual delay. Restrained iron/leather/paper UI sounds may
be sourced later; no audio asset production is part of this proposal.

## Asset production plan

Reuse existing fonts, portraits, glyph meanings, room illustrations and exact
campaign frame/button/leather exports. Added: built-in imagegen reference edit
of the approved world map into an underground mine chart, plus Aseprite-saved
1280x570 map and320x240 cave-in vignette. Prompt, reference, hashes and source
paths are retained in art/GENERATION.md and art/manifest.json. No accepted game
asset was overwritten. New art is a design candidate, not native acceptance.
Text, values and interaction stay native. Future state-symbol/light polish uses
the same controlled sources rather than introducing another UI skin.

## Ordered implementation proposal (not started)

1. Review this exploration composition plus obstacle and packing states; settle
   the approved world-family composition and explicit preview/travel interaction.
2. Build one opt-in Godot exploration pilot from existing assets, using the real
   room graph and session state, without changing the normal entry scene.
3. Add the native packing/event/loot/recovery/result family and keyboard focus,
   then verify every existing domain guard and campaign/save boundary.
4. Produce the approved final material/marker family in Aseprite and verify
   native GPU captures at 720p,1080p,1440p,4K/ultrawide with text scaling.
5. Play one ordinary managed expedition: packing, choice, battle, reward, exit,
   settlement/restart; retain deferred physical cases until actually played.

The user has now delegated implementation/review/publication within the staged
time box. Existing character approval remains intact; follow milestone022's
ordered native work and evidence gates, including actual visible game input.
