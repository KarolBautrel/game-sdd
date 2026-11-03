# Stage62: tactical two-view selection

Owner: [presentation024](../024_tactical_two_facings.md).

1. Start an ordinary tactical scene with enemies above, below and to either side.
   Every displayed unit uses SE or SW. Initial nearest-opponent selection, direct
   facing overrides and a board with no opponents all obey the same boundary.
2. A northward path and its per-step facing callbacks continue to display a front
   three-quarter walk. The move reaches the resolver destination and unlocks.
3. Bow attacks towards above-left/right show SW/SE respectively; hit/death frames
   and final corpses remain in the same two-view policy. Damage/terminal result
   are resolver-owned; no injected result counts as a legal fight.
4. Legacy families and Bran's equipment variant obey the same policy. All eight
   source views still resolve in galleries; every PNG/Aseprite remains unchanged.
5. Run tactical_facing_tests.gd, drawn/runtime/battle/lifecycle/combat regressions,
   identity/campaign equipment tests and validate_all. Record physical L62-01
   separately; automated sprite routing does not approve the visual result.
