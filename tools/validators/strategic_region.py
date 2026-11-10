"""Reference checks for the new native-region format; no old-profile migration."""
from __future__ import annotations
import json
import math
from pathlib import Path
from jsonschema import Draft202012Validator
from tools.validators.classic_strategy import reference_errors as classic_errors
from tools.validators.terrain import terrain_errors, PASSABLE

ROOT = Path(__file__).resolve().parents[2]


def rules_errors(data):
    schema = json.loads((ROOT / "resources/schemas/region_rules.schema.json").read_text())
    errors = [e.message for e in Draft202012Validator(schema).iter_errors(data)]
    if not errors and data["delivery"]["world_food"] != data["delivery"]["party_food"] * data["food_ratio"]:
        errors.append("regional food conversion differs")
    return errors


def reference_errors(s, extra_sites=None):
    schema = json.loads((ROOT / "resources/schemas/strategic_region.schema.json").read_text())
    if extra_sites:
        schema["properties"]["run_context"]["oneOf"][1]["properties"]["site"] = {"type": "string"}
    errors = [f"regional shape: {e.message}" for e in Draft202012Validator(schema).iter_errors(s)]
    if errors:
        return errors
    world, region = s["strategy_world"], s["region"]
    core = world["core"]
    known_sites = dict(region["sites"], **(extra_sites or {}))
    errors.extend(classic_errors(world))
    errors.extend(rules_errors(s["region_rules"]))
    terrain = region["base"]["terrain"]
    errors.extend(terrain_errors(terrain, region["sites"].values()))
    w, h = int(terrain["width"]), int(terrain["height"])
    def free(point):
        return terrain["rows"][min(h-1,int(point["y"]*h))][min(w-1,int(point["x"]*w))] in PASSABLE
    if set(core["routes"]) != set(region["routes"]) or len(region["sites"]) != 9:
        errors.append("regional graph/anchor count mismatch")
    if s["company"]["world"]["seed"] != core["seed"] or s["company"]["world"]["elapsed_hours"] != int(core["tick"]) // 4:
        errors.append("regional company/world clock mismatch")
    if s["company"].get("living_world") or s["company"]["world"]["pending_event"]:
        errors.append("regional campaign cannot contain a legacy living/event block")
    for fid in s["scouting"]:
        if fid not in core["factions"] or set(s["scouting"][fid]) - set(region["sites"]) or any(t > core["tick"] for t in s["scouting"][fid].values()):
            errors.append("invalid faction scouting references")
    for sid, town in core["settlements"].items():
        site = region["sites"].get(sid, {})
        if site.get("owner") != town["owner_id"] or site.get("position") != dict(x=town["x"], y=town["y"]):
            errors.append("core settlement differs from physical binding")
    for key, path in region["routes"].items():
        edge = core["routes"].get(key, {})
        if edge.get("a") != path["a"] or edge.get("b") != path["b"] or edge.get("travel_ticks") != path["ticks"]:
            errors.append("core route differs from physical binding")
        if path["a"] not in region["sites"] or path["b"] not in region["sites"]:
            errors.append("unknown physical route endpoints")
            continue
        if path["points"][0] != region["sites"][path["a"]]["position"] or path["points"][-1] != region["sites"][path["b"]]["position"]:
            errors.append("physical route endpoints differ")
        scale=2 if region['base']['version']==3 else 1
        if not math.isfinite(path["cost"]) or path["cost"] <= 0 or path["ticks"] != math.ceil(path["cost"]/(.007/scale)):
            errors.append("physical route cost/ticks differ")
        # Runtime Godot proves exact grid-cut safety/cost/checksum; sample densely
        # here too, rejecting modified water/peak crossings in portable fixtures.
        for a, b in zip(path["points"],path["points"][1:]):
            distance = max(abs(a["x"]-b["x"])*w,abs(a["y"]-b["y"])*h)
            steps = max(1,math.ceil(distance*3))
            for index in range(steps+1):
                t=index/steps
                if not free(dict(x=a["x"]+(b["x"]-a["x"])*t,y=a["y"]+(b["y"]-a["y"])*t)):
                    errors.append("physical route crosses blocked terrain")
                    break
    if not free(s["travel"]["position"]):
        errors.append("company position is blocked")
    if s["current_settlement_id"] and s["current_settlement_id"] not in known_sites:
        errors.append("unknown regional location")
    if s["travel"]["goal"] and s["travel"]["goal"] not in known_sites:
        errors.append("unknown company course target")
    for identifier, job in s["jobs"].items():
        if identifier != f"job_{int(job['number']):08d}" or job["number"] > s["job_seq"] or job["id"] != identifier:
            errors.append("job id violates watermark")
        if job["issuer"] not in core["factions"] or core["settlements"].get(job["issuer_town"],{}).get("owner_id") != job["issuer"] or job["target"] not in region["sites"]:
            errors.append("unknown job issuer/target")
        if job["cause"]["tick"] > job["created_tick"] or job["created_tick"] > core["tick"] or job["expires_tick"] != job["created_tick"] + s["region_rules"]["offer_ticks"]:
            errors.append("job cause/window mismatch")
        if job["status"] in ("accepted","objective","paid"):
            accepted=job["accepted_tick"]
            if accepted is None or not job["created_tick"] <= accepted < job["expires_tick"] or accepted > core["tick"]:
                errors.append("job acceptance window mismatch")
        elif job["accepted_tick"] is not None:
            errors.append("unaccepted job has false acceptance")
        if job["kind"] == "delivery" and job["world_food"] != job["party_food"] * s["region_rules"]["food_ratio"]:
            errors.append("job food conversion mismatch")
        if job["kind"] == "restoration" and (job["target"] != "dungeon_old_mine" or job["issuer"] != "river_league" or job["cause"]["kind"] != "site_occupied" or (job["status"] in ("objective","paid") and s["mine"]["status"] != "restored")):
            errors.append("restoration target/cause/outcome mismatch")
        if job["kind"] == "recon" and job["status"] in ("objective","paid") and (job["accepted_tick"] is None or s["scouting"].get(job["issuer"],{}).get(job["target"],-1) <= job["accepted_tick"]):
            errors.append("recon has no subsequent verified visit")
        hold=core["reservations"].get(job["hold"],{})
        if job["status"] in ("offered","accepted","objective"):
            if hold.get("status") != "reserved" or hold.get("resource") != "coin" or hold.get("faction_id") != job["issuer"] or hold.get("amount") != job["gold"] or hold.get("purpose") != identifier:
                errors.append("job lacks its funded immutable reward")
        elif hold and hold["status"] != "released":
            errors.append("closed job still holds budget")
    expected_rate=s["mine"]["ore_rate"] if s["mine"]["status"] == "restored" else 0
    if world["rules"]["policies"]["river_league"]["production"]["ore"] != expected_rate:
        errors.append("mine status/production mismatch")
    receipts=s["request_receipts"]
    if len(receipts) != min(s["request_seq"],64):
        errors.append("regional receipt tail length mismatch")
    for expected, r in enumerate(receipts,start=int(s["request_seq"])-len(receipts)+1):
        if r["sequence"] != expected or r["id"] != f"region_{expected:08d}" or r["tick"] > core["tick"]:
            errors.append("regional receipt identity/tick mismatch")
    return errors
