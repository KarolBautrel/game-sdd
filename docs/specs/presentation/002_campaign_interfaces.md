# Campaign interface system

Stage19,2026-11-01. Implemented/automated PASS; AWAITING_INTERACTIVE.
Extends world001..007 and presentation001 without owning game rules.

Stages20..22/presentation003..005 supersede the original list/form treatment,
oversized header counters and always-present party rail. Current UI uses visual
inventory/service tiles, portrait slots/comparisons, compact counters, warm
typography/ornament and a region-only contextual rail. Original stage19 evidence
remains historical; stage22 report/CONTINUE_HERE is the current technical build.

Direction: existing dark fantasy portrait/icon art; charcoal background, layered
slate panels, warm ivory type, muted brass borders, amber primary actions, sage
success and rust warnings. Reuse imported assets via AssetCatalog; no new raster
art. Central CampaignSkin owns palette, spacing/type sizes and controls/states.
Keyboard focus is clearly outlined; disabled controls remain readable. No emoji
or raw resource paths as player labels. Each important action includes cost/state.

CampaignShell provides fixed left navigation, top title/location/clock and resource
summary, independently scrolling main content and compact party/supply rail, and
fixed feedback footer. Location/pending/active gates stay in controllers. Region,
Town, Stash, Trading and Training have identifiable selected navigation states.
At narrow logical widths <1500, party summary moves into the scrolling content
and navigation becomes compact.1280x720 through2560x1440 must fit horizontally,
keep navigation/feedback visible and scroll overflowing content vertically.

Region has a framed map and separate journey/event action cards, current location
and day/time. Town uses grouped supply market, inn/trading/training cards with
availability reasons. Stash displays icon/name/quantity/category/value cards and
filters beside a framed equipment editor; equipment slots and hero summaries use
existing portraits/icons. Large inventory lists scroll within their own bounded
pane so equipment is not stretched into a huge empty column.
Equipment editing controls precede the detailed hero summaries; at wide sizes
Equip/Unequip are visible in the initial viewport without scrolling.
Trading splits Buy/Sell into framed sections with exact prices, copy counts and
persistent selections. Training has portrait/stat/next-tier
cards and available-XP summary. Large areas use a two-column container at wide
sizes, one column at narrow sizes, with bounded/wrapped text.

Normal gameplay uses the same public CampaignSession methods, never UI-side
cost/outcome mutations. Preserve existing action ids/component APIs where useful
for regression/export. Back/nav transitions do not mutate campaign state or
discard pending events. Feedback remains visible after a refresh. Subviews must
not cover other controls, create horizontal scrolling or retain freed references.

Proof presentation slice002, campaign_interface_tests (real layouts, navigation,
long legacy names/many items, scroll, disabled/focus and no state mutation), full
regression and extended exported shell/training probe. Live L19-01/02 NOT_RUN.
Headless geometry asserts layout, not visual beauty/animation/input placement.
Optional offline design reconstructions use headless geometry and existing art;
they are labelled and must not be called native game screenshots.
