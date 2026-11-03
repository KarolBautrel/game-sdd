# Stage61 acceptance: one hero, two weapon kits

Owner: [presentation023](../023_hero_equipment_identity.md), world005 and combat053.

1. Buy/equip a sword and shield on Bran. Launch managed combat; roster identity,
   portrait, owned gear and warrior art agree. Attack and Shield Wall use the
   authoritative item profiles.
2. Equipping a greatsword while the shield remains rejects without mutation or
   save rewrite. Remove shield, equip owned greatsword, reload, then launch:
   Bran keeps his identity and uses bran_greatsword art with two-handed attacks.
3. Both kits survive expedition snapshots/restart, launch and legal combat return.
   Equipment cannot change during a run/pending road fight. Return receipts remain
   authoritative; no debug result injection counts as a played victory.
4. Missing ownership, wrong slots and failed writes remain atomic. Old saves are
   loaded without grants/rewrites; Torin and unsupported kits retain prior fallback.
5. All112 primary clip/view combinations resolve complete native textures. New
   Aseprite sources reopen exactly; masks constrain edits to heads; idle feet,
   death pose, timing125ms walks/160px stride and old2304 PNGs remain unchanged.
6. User command opens ordinary campaign with an isolated resumable QA save and
   both kits. Startup failures must not fall through to the player save.

Executable proof: scripts/session/hero_equipment_identity_tests.gd and
tools/qa/build_bran_identity.py; full drawn and domain regressions.
Physical proof: L61-01/02 in docs/qa/live-test-scenarios.md; new art and continuous
movement await user review. Numeric/source proof does not close those cases.
