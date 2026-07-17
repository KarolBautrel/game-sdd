# Expedition Loadout Capacity V2

Status: active
Date: 2026-07-17

## Intent

Make pre-dungeon packing choices matter without making dungeon mode own buying, pricing, crafting, or restocking.

The player is assumed to own or have access to supplies before entering the dungeon through future town/world/inventory systems. Dungeon mode only decides how much of those supplies are carried into the expedition and how they are spent inside the dungeon.

## Rules

- A dungeon may define `supply_loadout_capacity` as expedition packing points.
- Each `supply_loadout_options` entry may define `packing_cost`.
- Selected supply counts are clamped by min/max and total packing capacity.
- Capacity applies only to the carried expedition loadout, not to persistent ownership.
- Current carried supply candidates shown in dungeon UI are torch oil, pickaxe, bandages, antidote, camping kit, and food.

## Presentation

The preparation panel should show:

- selected supply counts;
- packing points used and capacity;
- compact icon-plus-count resource tiles with tooltip text for names and usage;
- enough information to see that taking one supply may require dropping another.

## Non-Goals

- supply prices;
- shop inventory;
- town restocking;
- crafting;
- durable inventory application.

## Proof

- schema validation for authored dungeon loadout data;
- domain tests for default loadout capacity and clamping;
- HUD tests for packing summary visibility.
