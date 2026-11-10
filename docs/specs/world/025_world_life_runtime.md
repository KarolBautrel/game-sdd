# Autonomous campaign runtime

Owner for stages99..103; extends [world024](024_autonomous_world_life.md).
Acceptance: [slice026](slices/026_world_life_runtime.md).

## Isolation and time

Opt-in campaign version5 uses its own `qa_strategy_world_life_v5_*` slot. Versions
1..4, immutable geography, Old Mine restoration and original company files stay
unchanged. One classic world owns stocks, diplomacy and time. Additional actors
are independent mercenary companies, not copies of standing faction manpower.
Every tick, including managed dungeon time, advances the same episode authority.
No offline time, provider, automatic save migration or desktop operation.

## Threat and response

The first road camp starts occupied by a finite bandit force. Episode phases are
pressure, warning, commitment, action, resolution and aftermath. Warning after
48ticks offers a funded commission. NPC response starts after a further96ticks
if a free, sufficiently strong rival can be hired. A rival physically travels on
the same terrain navigation, spends12ticks at the target and resolves a seeded
bounded strength contest; losses persist. Failure weakens the camp, closes that
attempt and permits a new paid attempt after192ticks. Success clears once.
An occupied camp can intercept one physically nearby unprotected convoy per day.
Nearby funded friendly standing guards can prevent it. Lost cargo and returned
escrow use the existing world ledger; clearing ends that camp's interception.
Mapped encounters resolve their background from the referenced map when needed.

## Means, contracts and recovery

A commission reserves24coin in the ordinary world ledger. Company acceptance
at the issuer grants an explicit480tick exclusive claim; being in the owned
expedition protects the claim. NPCs cannot resolve a company-claimed target.
Completion earns24gold/8XP on reporting to the issuer, even after the deadline.
Rewards, loot and site resolution each settle once, under the same atomic save.
An NPC success receives24coin; failure receives8coin and releases the remainder.
NPC recruitment consumes its own wallet: one strength per48ticks at2coin each,
up to its initial strength. Hiring/strength never creates core faction soldiers.
Initial strength and a finite migration reserve are explicit opening premises.
Two rival companies and one political retainer start with70total strength and
8coin each. Retainers do not compete for ordinary camp commissions.

## Politics and provinces

Later stages add defended outposts with local finite garrisons. Only an existing
war permits hostile capture. A funded campaign warns96ticks, travels, clashes,
occupies and recovers; peace cancels an uncommitted offensive, and each outpost
has a672tick occupation cooldown. Capitals and original map bindings cannot swap.
Garrison reinforcement costs actual faction coin, a finite18person-per-faction
local reserve and48ticks per recruit. These local garrisons are a separate
explicit36person opening, not duplicates of core standing forces.

A v5 Iron March corridor dispute opens only with an actual ore shortage, no
active agreement and no protecting truce. It requests a corridor nonaggression settlement first using an
ordinary pact offer. An actual refusal adds grievance and gives a96tick warning.
Only continuing shortage, real affordable border mobilization and a legal ready
force permit the existing classic war operator. Recovery to the full published ore target, an accepted settlement,
protected peace or failed preparation settle/cancel the dispute. One opening
claim has one resolution; no calendar forces recurring wars.

Three named contiguous districts partition the same continuous world terrain;
they are not three separately generated continents. Camp, ruined shrine and
outposts are supported content families. All parties progress globally on their
actual paths; daily district summaries are a projection, not a second simulator.
Entry changes knowledge, never actors, progress, layout or rewards. A cleared
site can be reoccupied only by a finite reserve party physically arriving after
at least14days, producing a new episode ID and preserving its earlier history.

## Knowledge and presentation

Reuse the accepted Ashen map, serif, parchment/iron/crimson controls and dungeon
archetypes. Public dated notices identify issuer/source, target, cause, action
and outcome. Remote summaries are dated reports; exact live enemy strength and
private plans are not published. Direct arrival records an observation. Read-only
inspection never advances time. Contracts publish exclusive deadline and frozen
terms. World-life tab shows current situations, rivals and district reports;
the existing chronicle and faction diplomacy remain available.

No live model is activated. Recorded examples retain their old separate mode.

## Current bounded content and review limit

The opt-in prototype contains two expedition sites and three political outposts
beyond the nine immutable anchors. The90day review can exhaust the finite
displaced bands and leave both sites permanently cleared. This is an intentional
finite source, not a claim of unlimited late-game adventures. Additional authored
site pools, actor sources and non-economic political motives are subsequent
content/balance work. The current prototype demonstrates causal autonomous
threats, diplomacy, expeditions, defended control and recovery without a model.
