# Stage71A: full town plan and isolated courtyard pilot

Status: DESIGN_COMPLETE / A_IMPLEMENTED / AUTOMATED_PASS /
AGENT_GPU_VISUAL_REVIEW / AWAITING_INTERACTIVE. B/C are pending. Owner world008,
slice008; authorized only after the preceding timed-session priorities.
Stage70 was published20e8c82e50b61bf5d1c3a8c5432400b12d4c04ca before this build.

The plan defines small courtyard/inn spaces,2:1 projection, normalized named
WASD actions, collision, breadcrumb followers, source-facing/timing rules,
blocking NPC conversations and the later guarded campaign/service bridge.
The first implementation is a separate launcher scene: three party members,
three NPC stand-ins, authored TMX/map-v2/space data and current art. No campaign
save load/write, economy mutation, new battle direction or art regeneration.

Focused town1445/0: projection roundtrip,30/60/144step one-second104px motion,
normalized diagonals, large-timestep wall sweep, boundary/corner routes, stable
nearest NPC, source textures, dialogue blocking/cancel and unchanged campaign.
All three validator negative/safety tests PASS; full Python suite56tests PASS.
Complete source regression autonomous-polish-71-final:67/67checks PASS,
0errors/warnings, including all suites, import and6scene boots. Validator and
whitespace checks PASS. Current full source report includes the final1445test.

Native town-pilot-71-v3:87checks/24engine key events/9captures PASS at720p,
1080p/1440p. Actual viewport key events hold/release A, sample all8walk cels,
approach watch, E dialog, blocked D movement and Escape close/no stale motion.
Reviewed actual courtyard and720p dialogue. Fixed initial zero-scale world before
container allocation, cleared released actions and made wrapped parchment size
settle inside the viewport with scrollable speech and reachable Continue.
Earlier failed views remain in ignored artifacts and are not PASS evidence.

Final Windows EXE/PCK smoke autonomous-polish-71-final PASS, independent exported
directory and all6scene/campaign/trade/interface tokens;0errors/warnings.
EXE103055872bytes SHA256
`6b580a72cca9c31922ff4f7f1519a42debdd856e6852eec39ae46ce0e709231d`;
PCK274598180bytes SHA256
`5ef1242746a0ea653019896d6f02c87807c8575c131633b8c9ce7c5ba9a70bb1`.

Native reviews of this exact packaged pair at1080p/720p:
- packaged-polish-play-final:301checks/30pointer events/16key events/26captures
  PASS, dungeon route/event/hazard/loot, both arena moves and town movement/talk.
- packaged-polish-campaign-final:106checks/50pointer events/12captures PASS,
  region preview/commit/return plus stash/equipment/services. Both report the
  same PCK hash above, no errors/warnings and no focus/save acquisition.

OS activation is still blocked as in67. Engine key events are not physical
keyboard gameplay; L71-01 and earlier cases stay open. NPC art, inn interior and
campaign bridge are explicitly unfinished future work. Next: review these
controls, then world008B optional campaign entry/service return anchors, preserving
all existing atomic transactions and the current default service-card interface.

Late source-window check: launcher created task PID7348, town preview on DISPLAY1
with the expected larger-left physical screen mapping. Sky captured the real
window. A key/click call then returned without the earlier activation error,
but no movement/close outcome was visually confirmed. OS delivery is unverified;
no physical case was closed. This observation supersedes an assumption that every
later input necessarily returns the identical activation error.
