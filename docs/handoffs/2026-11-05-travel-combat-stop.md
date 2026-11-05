# Travel/combat polish — explicit stop and publication

Latest instruction: user returned, stopped autonomous work, asked to save the
resume point and push all completed local work. The two-hour desktop delegation
has ended. Do not resume desktop input or start more implementation in this turn.
Branch master; prior published base564dbdae. Publication and final test receipt:
../qa/2026-11-05-session-close.md. User-approved Git identity remains Karol Bautrel
<93617105+KarolBautrel@users.noreply.github.com>.

## Delivered scope

-78: weighted terrain navigation, authored mask painter/probes, bridge/river/peak
  restrictions, forest/hill/slope travel costs. Preserve designer revision9.
-79: continuous company/NPC motion, fractional waypoints, pause/rate continuity.
-80: seeded geography-first illustrated Classic regions, three presets, preserved
  snapshots and separate pilot profiles. User approved the map style.
-81: Large384x216 regions (four times Classic area), mixed climate/biomes, physical
  travel scale2, scroll/zoom, cursor-anchored wheel, Overview/Company/mini chart,
  separate v1/v2 slots and unchanged v1 frozen generation fixtures.
-82:18% faster tactical translation, distance-driven authored foot phase carried
  across moves, reset-safe interpolation. Original sprites/weapons/idles/attacks
  and SE/SW tactical facing remain intact. User feel review remains pending.
-83:16muted painted props, retained originals, raw generation, English prompt,
  manifest, reproducible editable Aseprite export, accurate terrain explanations.
  This environment family is agent-selected; user visual approval is pending.
-84: live native tooltip HP/status refresh; actual Forest and Mine victories;
  correction of misleading blocked-cell LOS explanation against combat/grid022.
  Third ordinary skirmish remains unfinished. No global combat-ready claim.

## Actual desktop results and exact stop

On left DISPLAY1, Sky controlled normal-permission Godot. Ordinary Forest Ambush
and Mine Breach each won round2 with all4allies alive, no Debug Win or forced
state. Details/decisions/HP/captures: ../qa/2026-11-05-ordinary-skirmishes.md.
Mine verifies blocked LOS, two routes around pillars, Defend/Shield wall and
Deep cut. Native automated battles are separate receipts, not physical play.

Third scenario drawn_roster_skirmish, seed2001, title Painted Six - Old Mine.
Last agent-controlled state round1 Rogue turn: Rogue5,2 HP10 AP2 MP4, Move
selected, no destination committed. Knight9,8 HP13 AP0 MP0; Bran9,5 HP14 AP1 MP0
Shield wall; Torin7,7 HP10 AP0 MP0 Defend. Southern axe10,8 HP2/14; southern
spear11,6 HP12/12; north axe10,2 HP14/14, north spear11,1 HP12/12. No enemy turn
yet. Torin's arrow intercepted Knight on shot line (1damage), another shot was
rejected for blocked LOS. Ordinary log game-20261105T004854774.log.
User resumed desktop input; next attempted click was prevented. No more game
input was sent. User then changed scenarios. This transient debug battle is not
saved for runtime resumption and must be restarted next session. A user-triggered
Debug victory in a different scenario does not count as the third played result.

Actual travel: unique QA seed20261105/Marches/Large, mine arrival Day1 17:45/tick39,
80gold/15food/fatigue13. Space pause, wheel zoom, Overview/Company/mini chart work;
paused navigation spends nothing. Existing player campaign slots untouched.
Physical RMB/MMB drag still untested; native RMB gesture passes.

## Tomorrow, in order

1. Review the Large world and tactical sample gallery with user; retain requested
   style, avoid changing accepted actor poses. Get feedback on18% pace/new props.
2. Restart and finish the third ordinary drawn_roster_skirmish battle, documenting
   outcome and ranged interception. Do not mark it completed from partial evidence.
3. Review action-tray instability: unaffordable actions currently disappear and
   shift buttons/shortcuts. It caused review friction; scope a stable disabled-slot
   solution through owner/slice/tests before implementation.
4. Finish still-open L77-01 ordinary campaign mine-contract victory/rewards/return,
   and remaining large-map physical gestures. Isolated battles do not close it.
5. Choose the next combat/world increment with user after these checks; do not
   treat the expired autonomous window as fresh implementation permission.

Launchers (PowerShell from repository):

```powershell
& .\tools\qa\start_game.ps1 -Scene regions
& .\tools\qa\start_game.ps1 -Scene combat -CombatScenario painted_forest_ambush
& .\tools\qa\start_game.ps1 -Scene combat -CombatScenario painted_mine_breach
& .\tools\qa\start_game.ps1 -Scene combat -CombatScenario drawn_roster_skirmish
Start-Process .\docs\design\tactical-polish\2026-11-05\index.html
```

The launcher checks left DISPLAY1 and configures a separate selected debug scene.
Local desktop QA helper is in ignored artifacts/qa-runs/live-control-2026-11-05;
it starts Godot directly at normal permission without shell commands, input,
save edits or security-setting changes. Do not publish the temporary EXE/helper.
Do not overwrite existing player saves. Never regenerate the user's terrain mask.

## Durable references

New source specs world011..014, presentation037..043 and their slices own rules.
Milestone022 tracks acceptance. QA reports and galleries are under docs/qa and
docs/design. Tactical gallery includes44unchanged native GPU frames/timestamps
and a sampled-sequence player (not a smooth desktop video), new props/arenas,
two actual victories and portable native receipts. Gallery browser playback review
was not completed before the user's stop; do not claim it was.

Authored r9 SHA a5d90d2ff4dbf36d0f3b46856fc30be0812767876cc407e72c3c0067a8a8f327.
Approved atlas SHA516bdc4ad1635f931c79fac9eaaaba0ac041607dc5aacc501593907cd41ea9a5.
Immutable stage76 archive SHA d208ceb651294cc56318d4aa32bee7a5caa44a7cf9c7ec76d8f54bbf9280e777.
Keep private packages/dark-fantasy-ui-workshop ignored and retain all old assets.
