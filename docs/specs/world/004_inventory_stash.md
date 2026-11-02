# Item catalogue and readable stash

Status: implemented, automated PASS; AWAITING_INTERACTIVE. Stage15,2026-11-01.

Campaign items remain the existing durable string array: duplicates represent
quantities. Do not convert, drop, consume or rename saved items in this view
slice. Supplies remain their existing separate owned counts.

Schema-validated campaign item catalogue owns stable id, name, description,
category (valuable/quest/equipment) and appraised value. It describes every
current authored loot reward and starter weapon metadata. No buying/selling or
equipment mutation is introduced in this slice. World005 adds equipment and
world006 adds explicit trading transactions, preserving protected quest/legacy
items. Unknown legacy ids remain visible as
humanized Legacy entries, including duplicates; they are never discarded.

ItemCatalog returns isolated metadata copies and deterministic name/id-sorted
stacks with exact quantities. InventoryView is passive: copies input data,
filters All/Valuables/Quest/Equipment/Legacy and displays bounded readable name,
quantity and description. It does not access or mutate Campaign singleton.

App/town expose Open Stash and Back controls. Existing header shows supply counts;
stash shows loose-item groups with total items/stacks and an explicit empty state.
Opening/filtering/closing during a pending event is safe; it does not resolve
the event, travel or discard current location. No player-facing raw JSON paths.

Proof world slice004, inventory_stash_tests.gd (grouping/cache/legacy/filters,
actual App controls and no state mutation), schema/source validation and full
regression. Actual scrolling/filter/readability is live L15-01 NOT_RUN.
