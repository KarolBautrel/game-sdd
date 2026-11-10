# Desktop follow-up evidence

Read [the stage report](../../../../qa/2026-11-05-playtest-followup.md) for scope,
source identity, commands, defects and deferred physical tests.

- [Victory image](painted-six-victory.jpg): unmodified ordinary DISPLAY1 capture,
  round3 Painted Six victory with four survivors, before stages87..89 fixes.
- [Physical receipt](physical-play-receipt.json): scenario/seed, survivors,
  capture SHA256, desktop stop, existing-save comparisons and incomplete fresh
  campaign attempt. [Closed runtime log](painted-six-runtime.log).
- [First full run](first-full-failed.json): retained failed Mine regression,
  which exposed the unaffordable AI fallback fixed in stage89.
- [Godot arena simulations](godot-arenas.json):1415checks/0failures, Forest/Mine
  normal active-policy victories and passive-player defeats.
- [Python arena simulations](python-arenas.json): same four expected outcomes
  and no rejected commands. Deterministic command counts differ between the
  existing implementations; this is outcome/legality proof, not parity of rolls.
- [Final full-source verification](source-verification.json): full automated
  result and source fingerprint. Logs remain in the named ignored QA run.
- [Preservation receipt](preservation.json): unchanged designer revision9 mask
  and approved world atlas hashes.

Automated battle simulations do not establish post-fix physical play or user
approval of appearance/movement. Controls remain reserved by the user.
