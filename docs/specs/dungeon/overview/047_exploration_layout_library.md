# Exploration layout library

Date:2026-11-04. Stage74, PREPARATION_LIBRARY. User approves all four art samples
and requests random maps/configurations plus a reusable UI workflow.

Keep environment art, length, graph family and difficulty distinct. Initial
portable library:15authored families,5per length, reused across4themes (60base
combinations). Seeds vary entrance/exit orientation, room roles/identities,
optional locks/key locations and art variants. No artwork generation in gameplay.
Short5..7rooms, medium8..10, long11..14are design presets, not replacements for
existing short_mine/medium_mine/deep_mine defaults. Difficulty is budget metadata,
not a forced longer graph.

Use versioned stable seed hashing and template ids. Graphs are connected, have
unique ids/positions/edges and reachable exits.
Authored diagram edges must not cross or pass through unrelated room centers.
Native routing still needs clearance for the actual artwork and labels.
Locks are optional leaf rooms; planned keys are reachable without that lock.
Slots/keys/budgets are abstract preparation data. Existing domains own concrete
combat/items/costs/balancing.
Save version/seed/template/theme/options and the resolved graph. Keep computed
shortest path separate from existing authored pacing.route_length. Version any
pool change rather than silently changing saved-seed results.

This portable preparation library is NOT the active runtime pool. Preserve the9
accepted Old Mine templates, seed behavior and saves. Native content needs domain
adaptation/validation/promotion under046before use. Unproduced art keys are not
working textures or proof of a playable forest/castle. Proof: slice055.
