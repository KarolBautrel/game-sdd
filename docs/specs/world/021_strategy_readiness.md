# Affordable faction preparations

Stage97a,2026-11-10: logistics/readiness prerequisite for later live-model
comparison. Extends [world017](017_classic_strategy.md) and
[world019](019_model_strategist.md). Proof: [slice022](slices/022_strategy_readiness.md).

## Same preparation price for proposals and execution

Own-force observations expose a preparation quote: existing free recruits up to
the saved party cap12, saved base mobilization costs plus2coin/1food per recruit
and ceil(recruits/2)ore, minimum six troops, and affordability against available unreserved
stock. Compute it with the same helper used by the authoritative operator.
No opponent's reserves or policy are disclosed. Quotes do not reserve or spend.

Classic mobilize/protect-route proposals require a staffed, affordable quote.
An unfunded claim/defence preparation may still procure missing supplies through
the ordinary local trade rules. An already prepared border force may declare a
lawful war without paying preparation again. Do not create free troops, reduce
the saved price, force a successful plan or suppress ordinary consequences.

The bounded strategist's new capabilities inherit this same filtering. Existing
saved request/reply bytes, capability IDs, hashes and committed plans are not
rewritten. Old observations without quotes remain structurally loadable; they
do not acquire new preparation capabilities. Execution always requotes against
current stock, reservations, manpower, position and route. A once-affordable
reply can still fail after intervening spending. Both modes retain that result.

No campaign/schema migration or player-save reset. Preparation quotes are
transient own-force observation data, not a second durable treasury.

Comparison tooling is owned by [tooling006](../tooling/006_strategy_comparison.md).
Live provider/model/cost selection and actual player review remain open; this
stage cannot establish that a language model improves the campaign.
