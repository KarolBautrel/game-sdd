"""Validate versioned strategy registries and obligations, without simulating time."""
from __future__ import annotations

from collections import Counter
from itertools import combinations
import json
import math
from pathlib import Path

from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parents[2]
STOCKS = ("coin", "food", "ore", "timber")


def pair_key(a: str, b: str) -> str:
    return "~".join(sorted((a, b)))


def reference_errors(data: object) -> list[str]:
    schema = json.loads((ROOT / "resources/schemas/strategy_world.schema.json").read_text(encoding="utf-8"))
    errors = [f"strategy shape: {e.message}" for e in Draft202012Validator(schema).iter_errors(data)]
    if errors:
        return errors
    factions, towns = data["factions"], data["settlements"]
    tick, sequence = data["tick"], int(data["command_seq"])
    if set(data["company_reputation"]) != set(factions):
        errors.append("company reputation must match faction registry")
    for town in towns.values():
        if town["owner_id"] not in factions:
            errors.append("unknown settlement owner")
        if not all(math.isfinite(town[axis]) for axis in ("x", "y")):
            errors.append("nonfinite settlement coordinate")
    adjacent = {town_id: set() for town_id in towns}
    edges: set[str] = set()
    for edge in data["routes"].values():
        a, b = edge["a"], edge["b"]
        key = pair_key(a, b)
        if a not in towns or b not in towns or a == b or key in edges:
            errors.append("unknown/self/duplicate route endpoint")
            continue
        edges.add(key)
        adjacent[a].add(b)
        adjacent[b].add(a)
    reached, pending = set(), [next(iter(towns))]
    while pending:
        town_id = pending.pop()
        if town_id not in reached:
            reached.add(town_id)
            pending.extend(adjacent[town_id] - reached)
    if reached != set(towns):
        errors.append("disconnected strategy graph")
    headcount = Counter()
    for party in data["parties"].values():
        if party["faction_id"] not in factions or party["settlement_id"] not in towns:
            errors.append("unknown party faction/settlement")
        headcount[party["faction_id"]] += party["headcount"]
    if any(headcount[fid] > faction["manpower"] for fid, faction in factions.items()):
        errors.append("party commitments exceed manpower")
    expected_pairs = {pair_key(a, b) for a, b in combinations(sorted(factions), 2)}
    if set(data["diplomacy"]) != expected_pairs:
        errors.append("diplomacy must contain every canonical pair exactly once")
    treaties = {}
    for key, pair in data["diplomacy"].items():
        if pair["a"] not in factions or pair["b"] not in factions or pair["a"] >= pair["b"] or key != pair_key(pair["a"], pair["b"]):
            errors.append("noncanonical diplomacy endpoints")
        active_kinds = set()
        for treaty in pair["treaties"]:
            tid = treaty["id"]
            if tid in treaties or treaty["start_tick"] > tick or treaty["end_tick"] <= treaty["start_tick"]:
                errors.append("invalid treaty identity/ticks")
            if treaty["end_tick"] > tick:
                if pair["stance"] == "war" or treaty["kind"] in active_kinds:
                    errors.append("conflicting active treaty")
                active_kinds.add(treaty["kind"])
            treaties[tid] = (key, treaty)
    pending_terms = set()
    for oid, offer in data["pact_offers"].items():
        a, b = offer["proposer"], offer["recipient"]
        if offer["id"] != oid or a not in factions or b not in factions or a == b:
            errors.append("invalid offer identity/parties")
        if offer["created_tick"] > tick or not 1 <= offer["expires_tick"] - offer["created_tick"] <= 672:
            errors.append("invalid offer window")
        if offer["status"] == "accepted":
            accepted = offer["accepted_tick"]
            if offer["signed_by"] != sorted((a, b)) or accepted is None or not offer["created_tick"] <= accepted < offer["expires_tick"] or accepted > tick:
                errors.append("accepted offer requires both signatures within its window")
            expected = {"id": oid, "kind": offer["kind"], "start_tick": accepted,
                        "end_tick": None if accepted is None else accepted + offer["duration_ticks"]}
            if treaties.get(oid) != (pair_key(a, b), expected):
                errors.append("accepted offer and treaty terms differ")
        elif offer["signed_by"] != [a] or offer["accepted_tick"] is not None or oid in treaties:
            errors.append("unaccepted proposal cannot grant a treaty")
        if offer["status"] == "pending" and offer["expires_tick"] > tick:
            key, kind = pair_key(a, b), offer["kind"]
            pair = data["diplomacy"].get(key, {})
            active = any(t["kind"] == kind and t["end_tick"] > tick for t in pair.get("treaties", []))
            if pair.get("stance") == "war" or active or (key, kind) in pending_terms:
                errors.append("duplicate/conflicting pending pact")
            pending_terms.add((key, kind))
    if set(treaties) - set(data["pact_offers"]):
        errors.append("treaty has no consent record")
    held = Counter()
    for hid, hold in data["reservations"].items():
        if hold["id"] != hid or hold["faction_id"] not in factions or hold["created_seq"] > sequence:
            errors.append("invalid reservation identity/owner/sequence")
        if hold["status"] == "reserved":
            if hold["closed_seq"] is not None:
                errors.append("open reservation has closing sequence")
            held[hold["faction_id"], hold["resource"]] += hold["amount"]
        elif hold["closed_seq"] is None or not hold["created_seq"] <= hold["closed_seq"] <= sequence:
            errors.append("released reservation has invalid closing sequence")
    if any(held[fid, resource] > faction["stocks"][resource] for fid, faction in factions.items() for resource in STOCKS):
        errors.append("reserved budget exceeds stock")
    receipts = data["receipts"]
    if len(receipts) != min(sequence, 64):
        errors.append("receipt tail length does not match command watermark")
    for expected, receipt in enumerate(receipts, start=sequence - len(receipts) + 1):
        registry = data["reservations"] if receipt["action"] in ("reserve_budget", "release_budget") else data["pact_offers"]
        if receipt["sequence"] != expected or receipt["id"] != f"order_{expected:08d}" or receipt["actor_id"] not in factions or receipt["target_id"] not in registry or receipt["tick"] > tick:
            errors.append("invalid receipt tail identity/reference/sequence/tick")
    return errors
