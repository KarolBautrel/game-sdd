# 016 Strategic world: planned acceptance

Date:2026-11-09. Owner: [world015](../015_world_strategy.md).
Status: DESIGN ONLY. Scenarios below are planned, not executed tests or claims
of playable factions/model integration. No runtime implementation in stage92.

## Foundation and save boundary

- Load every existing authored/v1/v2 geography/living profile without rewriting
  it. Existing paid contracts, restored Old Mine, party gear/effects and current
  UI continue under world010. New strategy mode uses its own versioned fixture /
  campaign path. Unknown/corrupt versions reject without replacement.
- A four-faction/six-settlement fixture validates independent of registry order.
  No actor-index assumptions; the same commands/ticks/seed and simulator version
  reproduce classic-mode facts, resources, positions and diplomatic decisions.
- Dynamic strategy locations never enter the legacy atlas validator as unknown
  IDs. Ownership/danger updates preserve geography checksums and designer terrain.
- Failure at persistence rolls back the full transition, including clock,
  escrow, diplomacy, decision receipts, contracts and moving parties.

## Economics and classical decisions

1. **Trade interest:** two complementary shortages and a legal route produce
   feasible trade candidates. Acceptance reserves finite stock/coin; neither
   side receives transported goods before an actual arrival.
2. **Physical disruption:** raid a convoy/cut a route using a real supported
   event. Lost cargo is deducted once, reports carry provenance, scarcity affects
   subsequent plans/contracts, and inaccessible water/peaks remain blocked.
3. **Deterrence:** a faction without reachable/logistically supported force
   cannot declare a valid offensive action, even if its planner requests one.
4. **Conflict:** a configured aggressive/contested-border fixture can mobilize
   and enter war when the prerequisites and utility scores support it. Record
   intent, warning, costs, movement and consequences rather than flipping a
   tension-triggered global flag.
5. **Peace:** a loss/exhaustion fixture exposes useful ceasefire candidates.
   Both sides must consent to the same terms. A betrayal carries declared trust
   costs; signed pacts do not disappear during history pruning or reload.
6. **Four-power coalition:** A/B conflict and C/D trade dependence can motivate
   C/D's bilateral defensive pact. One-sided signatures, transitive alliance
   shortcuts and armies created by dialogue reject atomically.
7. **Simultaneous budgets:** conflicting plans cannot double-spend treasury,
   cargo or manpower. Tie resolution is stable and does not permanently favour
   alphabetically earlier IDs. Hold/rebuild remains available.

## Language-model interface and replay

- Feed a bounded faction observation to a provider-neutral adapter. Another
  faction's private plans and the player's hidden inventory do not appear.
- Begin with recorded valid/rejected response fixtures, not a live paid model.
  Same request IDs and duplicated/out-of-order responses cannot apply twice.
- Reject unknown targets, forged evidence, invalid values, unsupported operators,
  too many actions/branches, invalid versions and obsolete mode/campaign tokens.
- Recheck current resources/agreements when a structurally valid earlier plan
  is applied. Stale stock/expired offers cannot be forced through by prose.
- Timeout, offline provider and exhausted request budget continue with a valid
  classic plan. Movement/menus do not block or advance time while waiting.
- Applied decisions are saved before effects. Reload/replay uses their receipt
  stream, not a new inference. Seed-only reproducibility is asserted for classic
  mode; AI mode requires the recorded decisions.
- Switching modes while safely paused preserves current wars, stock, treaties,
  paid/active contracts and simulation time; previous pending replies are inert.

## Campaign relevance and ordinary play

Each accepted player-facing consequence must cite a committed fact: a new job,
shipment, closed road, changed price, patrol order or public treaty. A long model
explanation with no executable consequence does not pass. Map/inspector reports
distinguish facts from rumours and do not reveal secret plans.

Prove real dungeon results affect an eligible world need once, and bypass /
retreat/failure cannot fabricate completion. Keep the canonical restored mine
cleared; a new site episode needs an actual supported world cause. Accepted
contract terms survive political changes and restart. Normal travel, supplies,
camping and tactical return still work without a central mandatory hub.

The first headless campaign matrix should cover at least16seeds x180strategic
days, plus longer soak runs. Track illegal-applied actions (must be0), resource
violations (0), duplicate payments (0), war/peace transitions and durations,
trade volume/losses, plan churn, concentration of power, viable neutral-company
routes and actionable contract variety. These are diagnostics; successful
balance/fun cannot be inferred from a target number of wars or alliances.

Compare classic and model modes with identical initial geography/resources /
personalities, observation rules and a recorded player-command schedule. Allow
different subsequent outcomes; judge coherence, consequence diversity, planning
stability, continuation without the provider, latency and actual configured
inference cost. No unsupported claim that model mode is inherently better.

Before default promotion, ordinary visible play must show a trade dispute,
bilateral agreement, mobilization/conflict, an actual company expedition and
its consequence, and a restart preserving the political state. L91-01/L91-02 /
remaining L77-01 and user art/motion review remain separate existing gates.

## Intended proof locations

The staged implementation adds `world_strategy_tests.gd`,
`faction_planner_tests.gd`, `strategy_campaign_session_tests.gd` and native
strategy-scene checks through the existing headless runner. Those names describe
planned suites in the original design. Stage93/world016 now owns the foundation
proof, and stage94/world017 owns classic simulation proof. The broader player /
model checklist above is still not fully implemented. Implement and
verify one complete prerequisite at a time under stages93..97, preserving the
world010 legacy suites. Record actual results in a new QA report when built.
