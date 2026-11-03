"""Rebuild the isolated six-role battle review using existing combat rules."""
import copy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCENARIO = "drawn_roster_skirmish"


def read(relative):
    return json.loads((ROOT / relative).read_text(encoding="utf-8-sig"))


def melee(item_id):
    return {
        "id": item_id, "slot": "main_hand", "grants_actions": ["basic_attack"],
        "action_profiles": {"basic_attack": {
            "id": item_id + "_basic_attack", "action_id": "basic_attack",
            "range": 1, "ap_cost": 1, "damage_bonus": 0,
        }},
    }


def unit(unit_id, character, team, position, hp, strength, defense, initiative,
         weapon, shield=None, armor=None):
    return {
        "id": unit_id, "team": team,
        "position": {"x": position[0], "y": position[1]},
        "stats": {"max_hp": hp, "strength": strength, "defense": defense,
                  "initiative": initiative, "move_points": 4, "max_ap": 2,
                  "accuracy": 12 if character == "archer_1" else 0, "evasion": 0},
        "resources": {"hp": hp, "ap": 2, "mp": 4}, "statuses": [],
        "available_actions": ["move", "defend", "end_turn"],
        "loadout": {"main_hand": weapon, "off_hand": shield, "armor": armor},
        "visual": {"faction": "heroes" if team == "player" else "villains",
                   "character": character},
    }


def main():
    base = read("resources/data/combat_encounters/debug_full_combat_showcase.json")
    items = copy.deepcopy(base["item_profiles"])
    items.pop("raider_bow")
    catalogue = read("resources/data/items/catalogue.json")
    items["hero_bow"] = next(i["combat_profile"] for i in catalogue["items"]
                             if i["id"] == "hero_bow")
    items["greatsword"] = read("resources/data/combat_encounters/"
                              "slice_56_two_handed_blocks_shield.json")["item_profiles"]["greatsword"]
    # Two painted daggers are one existing melee action, not a new dual-wield rule.
    items["review_paired_daggers"] = melee("review_paired_daggers")
    items["review_spear"] = melee("review_spear")
    items["review_spear"]["two_handed"] = True
    units = [
        unit("unit_knight_pilot", "knight", "player", (5, 8), 14, 5, 1, 12,
             "greatsword", armor="hero_chainmail"),
        unit("unit_player_001", "warrior", "player", (5, 5), 14, 5, 2, 11,
             "hero_sword", "hero_shield", "hero_chainmail"),
        unit("unit_player_002", "archer_1", "player", (3, 7), 10, 3, 0, 10, "hero_bow"),
        unit("unit_rogue_pilot", "rogue_1", "player", (5, 2), 10, 4, 0, 9,
             "review_paired_daggers"),
        unit("unit_enemy_axe_1", "axe_bandit", "enemy", (10, 8), 14, 4, 1, 8, "raider_axe"),
        unit("unit_enemy_spear_1", "bandit_spearman", "enemy", (11, 6), 12, 4, 1, 7,
             "review_spear"),
        unit("unit_enemy_axe_2", "axe_bandit", "enemy", (10, 2), 14, 4, 1, 6, "raider_axe"),
        unit("unit_enemy_spear_2", "bandit_spearman", "enemy", (11, 1), 12, 4, 1, 5,
             "review_spear"),
    ]
    encounter = {
        "id": SCENARIO, "seed": 2001, "background_path": base["background_path"],
        "item_profiles": items, "grid": base["grid"], "units": units,
        "turn_state": {"active_unit_id": units[0]["id"], "round": 1,
                       "turn_order": [u["id"] for u in units]}, "event_log": [],
    }
    destination = ROOT / "resources/data/combat_encounters" / (SCENARIO + ".json")
    destination.write_text(json.dumps(encounter, indent=2) + "\n", encoding="utf-8")
    path = ROOT / "resources/data/combat_scenarios/catalogue.json"
    scenarios = read("resources/data/combat_scenarios/catalogue.json")
    if not any(s["id"] == SCENARIO for s in scenarios["scenarios"]):
        scenarios["scenarios"].insert(1, {
            "id": SCENARIO, "label": "Painted Six - Old Mine",
            "path": "res://resources/data/combat_encounters/" + SCENARIO + ".json",
        })
        path.write_text(json.dumps(scenarios, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("DRAWN_BATTLE_REVIEW_BUILD_PASS: 8 actors / 6 painted roles")


if __name__ == "__main__":
    main()
