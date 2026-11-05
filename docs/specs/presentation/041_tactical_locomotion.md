# Tactical locomotion pacing and distance-driven feet

Stage82,2026-11-05, renewed two-hour polish authorization. User asks for slightly
faster, more natural tactical movement. Retain accepted character pixels, planted
idles, rigid weapons, original Aseprite sources and SE/SW battle facing.

Agent baseline: ordinary Forest Ambush controls preview/confirm knight(2,7)->(4,7),
2MP; current painted stride160px in1s makes280px translation take1.75s. Walking
frames currently advance with an independent timer and restart at frame0 per
order. New presentation rate1.18 gives the same move about1.483s, with the original
160px physical stride. Do not stretch the declared stride to hide fast feet.

For painted units sample walk frame from actual cumulative displayed displacement
using authored per-frame duration fractions within the declared stride. Drive
root position and foot frame from the same tween sample, across every route leg;
carry per-unit stride phase across movement orders. Reset clears phase and kills
owned tweens; generation checks reject stale samples. Avoid free-running timers
for painted walking. Legacy unregistered artwork retains its existing playback.

Authoritative MP/legality/path/outcome, attack/aim/contact/recovery timing and idle
durations remain unchanged. Translation presentation accelerates18%; authored
source clips remain1s/160px and gallery/source exports stay unchanged. Dead units
and interruptions retain existing lifecycle rules. This is a runtime adapter
change, not a new art style or a published workshop revision.

Proof: slice041, locomotion tests across30/60/144FPS, affected animation/lifecycle/
arena suites, normal-speed native captured movement and ordinary visible battles.
Measure source and candidate on the same path/camera. User feel acceptance is
separate from agent observation and automated success.
