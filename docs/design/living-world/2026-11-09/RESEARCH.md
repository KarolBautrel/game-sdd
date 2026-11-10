# Strategy architecture research

Read2026-11-09. Primary sources only. These references inform the proposal;
they do not prove our game or a chosen provider already implements it. We did
not install their code, train a model or connect a paid inference service.

## Language plus strategic reasoning

Meta's [CICERO project description](https://ai.meta.com/research/cicero/)
describes combining strategic reasoning with a language component for Diplomacy
negotiation and coordination. The [authors' source repository](https://github.com/facebookresearch/diplomacy_cicero)
links its paper and separates strategic planning, simulation/model and dialogue
work. This supports studying a hybrid architecture; it does not establish that
an unconstrained general language model can run a persistent RPG world reliably.

Our design inference: keep the game simulator authoritative and make a language
model propose structured faction plans. Recorded decisions, fallback behaviour
and campaign economy rules are our project design, not claimed CICERO features.

## Classical decision modelling

The public abstract of Kevin Dill and Dave Mark's
[GDC utility-theory session](https://gdcvault.com/play/1012841/Improving-AI-Decision-Modeling-Through)
describes response curves and weighted choices for richer agent decisions.
Only the public session description was inspected, not the complete talk.
Our proposed utility scoring, commitment and small goal plans are an independent
fit to the game's local deterministic baseline; no framework dependency follows.

## Diplomacy is also a game-design problem

Creative Assembly's [Three Kingdoms diplomacy-AI session abstract](https://www.gdcvault.com/play/1027242/AI-Summit-Intrigue-and-Betrayal)
describes implementing and tuning shifting alliances across many factions while
keeping the sandbox enjoyable. The public abstract is not detailed source code
or proof of any specific internal algorithm. Our inference: measure player-facing
clarity, motives and useful consequences alongside technical legality; avoid
treating frequent declarations or generated diplomatic prose as success.

## Project-specific evidence

The current source has a fixed two-faction/three-settlement/four-party validator,
a daily+3tension escalation and three fixed contract IDs. The earlier
[living-world proposal](../../world-atlas/2026-11-04/LIVING_WORLD_PROPOSAL.md)
records the user's travelling-company and dungeon-centred campaign vision.
The [latest headless report](../../../qa/2026-11-09-background-contracts.md)
records real service-chain costs and the remaining physical acceptance gaps.
These local constraints are the reason for a versioned strategic-world foundation
before adding more factions or a live model adapter.
