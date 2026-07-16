# Combat HUD Restructure V1

Status: active

## Intent

Combat HUD should move from debug controls toward a fantasy tactical game UI using the provided combat UI atlas and example mockup.

The first implementation pass skins existing combat debug controls without changing combat rules.

## Source Assets

- UI atlas: `assets/ui/combat/assets/call_9exrXDuBoixt7ysV19RVDrhl.png`
- Direction example: `assets/ui/combat/example/call_L7YEenP4zhVXAauf7NNYVkRq.png`
- Processed UI exports: `assets/ui/combat/processed/`

## Rules

- The atlas is treated as source material and must be cut into named transparent PNG exports before use in scene code.
- Processed UI assets must include a manifest with crop rectangles and stable IDs.
- Combat debug V1 may skin the existing HUD rather than fully matching the example layout.
- Action buttons use atlas-backed slot frames and action icons when available.
- Main action slots are icon-first: visible action names are omitted from the slot when an icon exists, with tooltips/detail panel carrying the text label.
- Hovering an action slot updates the action detail panel with the action name, shortcut slot, and current AP/MP context.
- Primary combat panels use atlas-backed fantasy frames or deterministic fallback StyleBoxes.
- Combat log, action feed, and turn order text must wrap or clip inside their panel bounds and must not spill outside frames.
- The active unit's HP/AP/MP is summarized in the board overlay HUD while temporary unit-overhead resource labels remain available on the board.
- Processed HP/AP/MP bar art from `assets/ui/combat/processed/bars/` is used for active-unit UI presentation only; unit-overhead board information remains compact text for now.
- Active-unit resource bars should be a readable top-left board overlay using generated `384x56` mini bar PNGs; they must stay smaller than the oversized native `bar_hp/bar_ap/bar_mp` atlas exports and must not include text that expands the panel.
- Board-overlay log/feed should occupy a separate compact panel away from the active resource bars.
- Board-overlay log/feed and framed log panels must always render fallback or recent event text; empty framed log boxes are not acceptable.
- Combat debug may use board-overlay HUD panels instead of stretching every UI surface across the full viewport.
- The board should claim the available screen area after overlay HUD placement; UI panels must not unnecessarily shrink the board.
- Processed character animation frames should render on a stable foot-anchored canvas so walk, attack, hit, idle, and death frames do not resize the unit mid-animation.
- Processed character visuals should be normalized to the player `warrior` pose height, so enemies and mercenaries keep a consistent in-combat scale unless a future unit definition explicitly opts into a different boss/large-creature scale.
- Defeated processed-sheet units may settle into a slightly smaller corpse pose, but the corpse must remain visibly present and must not collapse to a tiny final fade frame.
- Debug-only controls remain available, but should not dominate the main battle actions.
- Text must remain readable and must not overflow the action slot at 2560x1440.

## V1 Scope

- Extract:
  - normal action slot;
  - selected/gold action slot;
  - dark panel frame;
  - large side panel frame;
  - HP/AP/MP bars;
  - core action/resource icons.
- Apply:
  - bottom HUD/action panel fantasy frame;
  - turn order/action panel frame;
  - action button slot frames;
  - enlarged icon-only slots for main combat actions;
  - hover-driven action detail copy;
  - bounded text for log/feed/turn-order surfaces;
  - board-overlay active-unit HP/AP/MP summary;
  - processed HP/AP/MP bars for the active-unit UI overlay;
  - compact, separately positioned board-overlay action feed/log panel;
  - icons for move, strike/basic attack, aimed/ranged, defend, end, bag, settings where available.

## Acceptance

- `tools/ui/extract_combat_ui_assets.ps1` regenerates the processed assets.
- Combat debug action buttons use processed slot art and icons.
- Combat panels use processed frame art where practical.
- Scene still loads headlessly.

## Proof

- Slice: `docs/specs/combat/slices/087_combat_hud_restructure_v1.md`
- Godot headless scene load.
- `python tools\validators\validate_all.py`
- Manual screenshot/playthrough review for visual quality.
