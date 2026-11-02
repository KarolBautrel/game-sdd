# Town and region presentation polish

Stage22,2026-11-02; implemented/automated PASS, AWAITING_INTERACTIVE. Extends presentation003/004 and
world002/003/006. No new locations, quests, prices or travel rules.

Ravenford uses a place banner/crest and compact supply tiles with owned count,
icon and price; grouped inn/trade/training service cards expose cost/availability.
Region uses a warm illustrated-style road chart with compass/landmark labels,
current location marker and clickable destination markers for adjacent roads.
Map markers show quote/cost/risk in tooltip and send destination id only to App's
existing travel method. Current/nonadjacent/active/pending/insufficient-food roads
are disabled. Visible route controls remain available for keyboard/navigation.
Pending cart/ambush presentation keeps its actual choices and resume contract.

Clear primary action, compact copy and short hover/selection feedback use the
same skin. Changes preserve campaign state on navigation. Final all-stage source,
scene references and fresh exported EXE probe must exercise the new visual item
selection and service/map controls; parser requires completion evidence. Proof
slice005/journey_interface_tests and existing travel/event/interface suites.
Actual native map/service input/normal journey/return is L22-01/02 NOT_RUN.
