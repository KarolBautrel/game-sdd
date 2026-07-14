# 058 Armor V1

Status: implemented  
Date: 2026-07-14

## Intent

Make the `armor` loadout slot affect incoming combat damage without building a full inventory or item progression system.

## Rules

- Armor is defined as an `item_profile` with `slot: "armor"`.
- Armor may define `armor_reduction`.
- `armor_reduction` is a non-negative integer.
- If a unit has a valid `loadout.armor` item, its `armor_reduction` is added to incoming damage reduction.
- If the equipped armor item omits `armor_reduction`, it contributes 0 damage reduction.
- Armor reduction stacks additively with status-based `damage_reduction`.
- Damage still has a final minimum of 1.
- `damage_applied` records:
  - `raw_damage`;
  - final `damage_reduction`;
  - final `damage`;
  - `armor_id` when armor contributed or was equipped.

## Example

Given an attacker has strength 5 and no damage bonus, and the target has defense 1:

```text
raw_damage = max(1, 5 - 1) = 4
```

If the target equips armor with `armor_reduction: 2`:

```text
final_damage = max(1, 4 - 2) = 2
```

## Non-Goals

- armor durability;
- armor weight;
- armor stat requirements;
- armor changing hit chance;
- elemental or typed damage resistance;
- inventory UI.
