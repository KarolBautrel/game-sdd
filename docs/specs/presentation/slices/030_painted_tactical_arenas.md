# Slice030: two authored arena pilots

Owner: ../030_painted_tactical_arenas.md. Stage70, authorized timed polish.

1. Export each canonical TMX and compare with checked-in map JSON. Match each
   unit to its unblocked unique spawn. Preserve pilot actor data except position.
2. Flood-fill all walkable cells and prove upper/lower crossing routes remain
   available. Verify cover/highground and current tile movement costs.
3. Run both teams with the existing deterministic AI policy to normal victory;
   run passive allies to normal defeat. No Debug Win, direct resource edits or
   rejected commands. Fail on stall/800-command ceiling.
4. Load each scenario through CombatDebug; verify seven accepted actor visuals,
   unchanged domain after rendering, native floor/prop assets. Select Move and
   a legal cell via engine-local button input; complete animation and spend the
   resolver MP cost. Recheck invalid destination leaves state unchanged.
5. Inspect720p/1080p/1440p captures. Actual OS play is a separate open L70-01
   case if window activation still fails; automated input never substitutes it.
6. Additional native --views arenabattles --exercise proof: drive each active
   battle through ordinary action/tile controls, existing AI chooses commands for
   both teams, wait for complete animation and compare every result with resolver.
   Reach normal victory with no Debug Win, rejected command or input lock; capture
   terminal boards. This remains engine-local input, not physical acceptance.

Proof entry points: tests/test_painted_arenas.py,
scripts/presentation/painted_arena_tests.gd, tools/qa/render_campaign.py --suite
play --views arenas --exercise. Existing domain combat slices remain required.
