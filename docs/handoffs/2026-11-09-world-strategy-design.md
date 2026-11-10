# World strategy: classic simulation plus AI faction strategists

Latest user steering: focus on the whole world-travel/simulation scene,
geopolitics, trade, alliances, war and long-term faction decisions. They selected
**a language model as faction strategist, with complete classic mode underneath**.
The earlier isolated contract-pool proposal is now a downstream part of this
broader design. Desktop control remains withheld. No commit/push request.

## Delivered in this stage

Stage92 is DESIGN COMPLETE, not a playable world-system implementation:

- [Product brief and examples](../design/living-world/2026-11-09/WORLD_STRATEGY_PLAN.md).
- [Proposed rule owner world015](../specs/world/015_world_strategy.md).
- [Planned acceptance slice016](../specs/world/slices/016_world_strategy.md).
- [Primary-source research](../design/living-world/2026-11-09/RESEARCH.md).
- [Design verification](../qa/2026-11-09-world-strategy-design.md).

One authoritative simulator, two interchangeable planners. Both modes have the
same economic/movement/diplomacy rules. Model proposals cannot manufacture facts,
resources, victories or another faction's treaty consent. Long-term plans,
asynchronous bounded inference, classic fallback, recorded decisions/replay and
safe paused mode switching are specified. Provider and live request budget are
not chosen; no service was connected or charged.

Four-faction/six-settlement experimental foundation is proposed, preserving
existing factions, authored terrain, saved geography and pilot progress. Extra
faction names and tuning values are working design choices. Current running
code still has two political factions, three settlements, four fixed world
parties, three fixed contract IDs and a single escalation counter. Do not claim
new alliances, AI mode, extra towns or dynamic contract families are playable.

## Next recommended implementation

Stage93: versioned strategy-world registries, canonical diplomatic pair facts,
economy/decision receipts and explicit legacy dispatch, in an isolated opt-in
fixture. Refine executable schemas/tests before coding. Then94: complete classic
four-faction model;95: real strategic scene/contract consequences;96: recorded
model-reply adapter followed by configured live inference;97: matched long-run
comparison and actual play. Do not skip the classic foundation to call a model
that can only narrate unimplemented events.

The current request was for design/preparation. An implementation continuation
should start with93, not silently rewrite the whole campaign or activate a
provider. All work remains without desktop input unless the user releases it.
Earlier L91-01/L91-02, remaining L77-01 and user motion/map/prop acceptance remain
open; they are required before default campaign promotion.

## Preserved baseline

Local master583ebc84; earlier stages85..91 remain uncommitted and preserved.
Stage91's prior full92/92PASS is historical runtime proof, not proof of this new
world design. This stage edits documentation only. Current validators/link/
whitespace checks are recorded in the design QA report. No new game launch,
OS input, save mutation, source/runtime change, commit or push occurred.
