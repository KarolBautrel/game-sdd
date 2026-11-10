# Vast generated worlds

User reprioritizes larger maps after96b; follow-up96c. Keep the current save and
defer strategist retesting/reset. Proof [slice021](slices/021_vast_regions.md),
presentation [048](../presentation/048_vast_worlds.md). No new provider or content
family; faction simulation/comparison remains a later task.

## Immutable geometry and compatibility

Generatorv3 adds Vast:768x432semantic cells, twice each dimension of Largev2 /
384x216, four times its area,16times Classicv1. Generate actual higher-density
terrain, rivers, safe crossings and roads, not a zoomed copy or stretched mask.
Retain the approved painted renderer/assets, three stored climate zones and
distinct forest/plain/hill/mountain terrain. Keep all existing functional roles:
six base anchors; strategic binding still has six towns/three adventure anchors.
Do not advertise extra playable sites without real domain content.

V1/v2 generation, hashes, authored192x108mask and stored snapshots remain unchanged.
Generic terrain capacity expands to768x432; authored mask writers keep their
specific192x108gate. V3 keeps all connectivity, no-corner-cut, river descent,
bridge-bank, site separation, snapshot checksum and exact persistence checks.
New snapshots use the existing explicit version field; no migration or mutation
of saved geography. Old saves remain on their exact old map.

## Physical scale

Physical multipliers: Classic1, Large2, Vast4. Company/NPC path integration,
fatigue/upkeep, route estimates and terrain speed ratios share that scale.
Strategic Large budgets remain .0225company/.007caravan-normalized units;
Vast halves both normalized budgets for the same local physical pace. Bind real
core edge ticks to ceil(path cost / (.007/(scale/2))). Routes store their actual
normalized terrain cost; actor sampling still follows cost along the safe path.
Strategic stopped-site tolerance also divides by scale/2. No travel chord or
teleport, stock/rules retune or implicit aid to make longer journeys look busy.
Longer distances can alter logistics; conservation/validity proof is not balance.

## Explicit separate creation

Foundry adds Classic/Large/Vast; old active campaigns retain their choice.
Legacy generated slots already distinguish generator versions. Strategic v3/v4
constructors accept Large2(default) or Vast3 explicitly; existing default paths
and creation remain. Vast uses a new seed/preset-specific `_g3_` slot for each
campaign format. No reset, overwrite or relocation of the player's current
company. UI selects the size and New/Resume targets that size's independent slot.
Packing/checkpoint/completion/report and return keep the same owning format /
size. Schema/reference validation accepts all supported sizes without relabelling
old reference files. Provider/AI protocol semantics remain world019.

Physical appearance/input still awaits user review; source/headless only.
