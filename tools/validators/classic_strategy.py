"""Independent structural/reference/accounting checks for the classic fixture."""
from __future__ import annotations
import json
from pathlib import Path
from jsonschema import Draft202012Validator
from tools.validators.strategy_world import reference_errors as core_errors, pair_key

ROOT = Path(__file__).resolve().parents[2]
STOCKS = ("coin", "food", "ore", "timber")


def _shape_errors(data, schema):
    definition = json.loads((ROOT / f"resources/schemas/{schema}.schema.json").read_text())
    return [f"classic shape: {error.message}" for error in Draft202012Validator(definition).iter_errors(data)]


def configuration_errors(data, core=None):
    errors = _shape_errors(data, "classic_rules")
    if errors:
        return errors
    if core is None:
        core = json.loads((ROOT / "resources/data/strategy_worlds/four_factions_foundation_v1.json").read_text())
    if set(data["policies"]) != set(core["factions"]):
        errors.append("classic policies must match factions")
    for fid, policy in data["policies"].items():
        if policy["home"] not in core["settlements"] or core["settlements"].get(policy["home"], {}).get("owner_id") != fid:
            errors.append("classic home must be owned by faction")
        if policy["claim_route"] and policy["claim_route"] not in core["routes"]:
            errors.append("unknown classic claim route")
    seen = set()
    for premise in data["premises"]:
        if premise["id"] in seen:
            errors.append("duplicate opening premise")
        seen.add(premise["id"])
        if set(premise["stocks"]) - set(core["factions"]):
            errors.append("premise refers to unknown faction")
    return errors


def reference_errors(s):
    errors = _shape_errors(s, "classic_world")
    if errors:
        return errors
    core, rules = s["core"], s["rules"]
    errors.extend(core_errors(core))
    errors.extend(configuration_errors(rules, core))
    factions, towns = core["factions"], core["settlements"]
    if s["premise"] not in {p["id"] for p in rules["premises"]}:
        errors.append("unknown saved premise")
    for key in ("relations", "shortfalls", "decisions"):
        if set(s[key]) != set(factions):
            errors.append("classic registry differs from factions")
    if set(s["forces"]) != set(core["parties"]) or set(s["wars"]) != set(core["diplomacy"]):
        errors.append("classic forces/war facts differ from core")
    def journey(record):
        a, b = record["at"], record["edge_to"]
        weights = [edge["travel_ticks"] for edge in core["routes"].values() if {edge["a"], edge["b"]} == {a, b}]
        if a not in towns or record["objective"] not in towns or (b and (not weights or not 0 < record["remaining"] <= weights[0])) or (not b and record["remaining"] != 0):
            errors.append("invalid persisted journey")
    for fid, relations in s["relations"].items():
        if set(relations) != set(factions) - {fid}:
            errors.append("directional relation endpoints mismatch")
    for pid, force in s["forces"].items():
        journey(force)
        if core["parties"].get(pid, {}).get("settlement_id") != force["at"]:
            errors.append("core party and force position differ")
    numbers = set()
    for records, prefix in ((s["trades"], "trade"), (s["peace_offers"], "peace"), (s["aid"], "aid"), (core["pact_offers"], "pact"), (core["reservations"], "hold")):
        for identifier in records:
            try:
                tag, digits = identifier.split("_")
                number = int(digits)
                valid = tag == prefix and identifier == f"{prefix}_{number:08d}" and 0 < number <= s["entity_seq"] and number not in numbers
            except (ValueError, TypeError):
                valid, number = False, -1
            if not valid:
                errors.append("entity id violates durable sequence")
            numbers.add(number)
    total = {resource: sum(f["stocks"][resource] for f in factions.values()) for resource in STOCKS}
    active = 0
    for tid, t in s["trades"].items():
        journey(t)
        if tid != t["id"] or t["seller"] not in factions or t["buyer"] not in factions or t["seller"] == t["buyer"] or t["proposer"] not in (t["seller"], t["buyer"]):
            errors.append("invalid trade identities")
        if towns.get(t["source"], {}).get("owner_id") != t["seller"] or towns.get(t["target"], {}).get("owner_id") != t["buyer"] or t["objective"] != t["target"]:
            errors.append("invalid trade ownership/target")
        if t["created_tick"] > core["tick"] or t["expires_tick"] != t["created_tick"] + 96:
            errors.append("invalid trade window")
        accepted = t["status"] in ("transit", "waiting", "delivered", "lost")
        if accepted:
            if t["signed_by"] != sorted((t["seller"], t["buyer"])) or t["accepted_tick"] is None or not t["created_tick"] <= t["accepted_tick"] < t["expires_tick"] or t["accepted_tick"] > core["tick"]:
                errors.append("trade lacks bilateral timely consent")
        elif t["signed_by"] != [t["proposer"]] or t["accepted_tick"] is not None:
            errors.append("proposal grants unearned consent")
        if t["status"] in ("transit", "waiting"):
            active += 1
            if t["cargo"] != t["amount"] or t["escrow"] != t["amount"] * t["unit_price"]:
                errors.append("shipment cargo/escrow differs from signed terms")
        elif t["cargo"] or t["escrow"] or t["remaining"] or t["edge_to"]:
            errors.append("closed/proposed shipment still carries resources")
        total[t["resource"]] += t["cargo"]
        total["coin"] += t["escrow"]
    if active > 32:
        errors.append("too many live shipments")
    for key, war in s["wars"].items():
        pair = core["diplomacy"].get(key, {})
        if set(war["exhaustion"]) != {pair.get("a"), pair.get("b")}:
            errors.append("exhaustion endpoints differ")
        if pair.get("stance") == "war":
            if war["started_tick"] is None or war["started_tick"] > core["tick"] or war["aggressor"] not in (pair.get("a"), pair.get("b")) or war["route"] not in core["routes"] or war["truce_until"] > core["tick"]:
                errors.append("invalid active war metadata")
        elif war["started_tick"] is not None or war["aggressor"] or war["route"]:
            errors.append("peace pair still has active war metadata")
        if war["peace_id"]:
            peace = s["peace_offers"].get(war["peace_id"], {})
            if peace.get("status") != "accepted" or peace.get("accepted_tick") is None or pair_key(peace.get("proposer", ""), peace.get("recipient", "")) != key or peace["accepted_tick"] + rules["ceasefire_ticks"] != war["truce_until"]:
                errors.append("ceasefire lacks matching bilateral fact")
    for offer in s["peace_offers"].values():
        a, b = offer["proposer"], offer["recipient"]
        if a not in factions or b not in factions or a == b or offer["expires_tick"] != offer["created_tick"] + 96 or offer["created_tick"] > core["tick"]:
            errors.append("invalid peace parties/window")
        if offer["status"] == "accepted":
            accepted = offer["accepted_tick"]
            if offer["signed_by"] != sorted((a, b)) or accepted is None or not offer["created_tick"] <= accepted < offer["expires_tick"] or accepted > core["tick"]:
                errors.append("peace lacks bilateral timely consent")
        elif offer["signed_by"] != [a] or offer["accepted_tick"] is not None:
            errors.append("unaccepted peace has false consent")
    for request in s["aid"].values():
        a, b, ally = request["protected"], request["aggressor"], request["ally"]
        if a not in factions or b not in factions or ally not in factions or len({a, b, ally}) != 3 or request["war_pair"] != pair_key(a, b) or request["war_tick"] > core["tick"]:
            errors.append("invalid defensive aid references")
    for plan in list(s["plans"].values()) + [p for records in s["decisions"].values() for p in records]:
        if (plan["target"] and plan["target"] not in factions) or plan["selected_tick"] > core["tick"] or plan["commit_until"] != plan["selected_tick"] + 288 or plan["review_tick"] != plan["selected_tick"] + 672 or plan["horizon_tick"] != plan["selected_tick"] + 1344:
            errors.append("invalid plan target/commitment/review")
    for resource in STOCKS:
        ledger = s["ledger"]
        if total[resource] != ledger["opening"][resource] + ledger["produced"][resource] - ledger["consumed"][resource] - ledger["lost"][resource]:
            errors.append("classic resource ledger does not reconcile")
    if sum(f["manpower"] for f in factions.values()) + s["metrics"]["casualties"] != s["initial_manpower"]:
        errors.append("classic manpower/casualties do not reconcile")
    for key, watermark, prefix, limit in (("events", s["event_seq"], "event", 128), ("receipts", s["sequence"], "intent", 64)):
        if len(s[key]) != min(watermark, limit):
            errors.append("history tail does not match watermark")
        for sequence, record in enumerate(s[key], start=int(watermark) - len(s[key]) + 1):
            digits = 10 if key == "events" else 8
            if record["sequence"] != sequence or record["id"] != f"{prefix}_{sequence:0{digits}d}" or record["tick"] > core["tick"]:
                errors.append("history tail sequence/tick mismatch")
    return errors
