# Dark fantasy sample v2 — original design inspired by Bloodlines

Latest user steering: use game-ui-design and take inspiration especially from
the free Bloodlines pack, without1:1copying. DESIGN_ONLY; textured72 remains
temporary current. Previous Ledger concept remains a separate comparison.

Target: Windows desktop tactical-RPG exploration, mouse/keyboard,16:9preview.
Player decision: select an adjacent room, inspect light cost, confirm passage.

Inspected the publisher's public button/icon/bar/slider preview sheets. Borrow
the high-level charcoal/ash/crimson relationship, distressed edge energy and
Gothic mood. Author original frames, location markers, seals and composition;
do not extract buttons, repeat its diamond/sliders, font treatment or UI layout.
Source: https://xgaida.itch.io/bloodlines-ui . Public previews stay in ignored
research artifacts; no third-party component pack is redistributed here.

Direction: **Ashen Cartographer**. A soot-dark field chart with etched iron
fittings, worn gray parchment and muted red wax. Keep painted cave vignettes
and the approved character style; the palette is cooler/darker than Ledgerv1.
Palette: charcoal#141516, ash#6a6963, ivory#e0d8c8, crimson#8d2e2b,
iron#353535, ember#b5894f. Ember belongs mainly to lamps. Cinzel-like headings
and a readable humanist body; ornamental Gothic lettering is limited to title.

Layout: map dominates left~70%; selected destination on right~26%. Compact
shared supply rail, two whole portraits and explicit red HP at bottom. Map
labels are small, high-contrast slips; the cave artwork remains visible. Original
mining/wax-seal detail provides identity, with material depth and native-scale
grain. Avoid nested wire boxes, flat default buttons, repeated square grain,
glowing paths and gratuitous skulls.

State plan: current room has an explicit marker; selected adjacent destination
has a rough crimson outline plus shape/text distinction; locked armory has a
lock and muted state. Inspector shows only selected destination and4to3light
cost, one primary Travel action, secondary Back. Runtime will use native labels,
buttons and the existing domain graph; no invented rules, timers or loot.

Input plan for later implementation: Tab through relevant room hits/actions,
visible focus, Back/Escape returns to current detail. Preserve existing modal
event input ownership and confirmation/cost guards. This image proves only look,
not navigation or responsive behavior; production must be checked at720p..4K.

Self-review: an all-black image would lose map reading and repeat the rejected
flat72b problem. Give the chart a distinct mid-value ash surface and retain
material depth, while pale labels/portraits carry readability. Red is reserved
for health and selected-action emphasis, paired with labels/shapes.
