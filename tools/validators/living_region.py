"""Reference integrity for the versioned living-region configuration."""
from pathlib import Path


def reference_errors(data: dict, atlas_ids: set[str], root: Path) -> list[str]:
    errors: list[str] = []
    sites = data.get("sites", [])
    ids = {site["id"] for site in sites}
    towns = {site["id"] for site in sites if site["kind"] == "town"}
    if len(ids) != len(sites):
        errors.append("duplicate living site ids")
    if ids - atlas_ids:
        errors.append(f"living sites missing from persistent atlas: {sorted(ids - atlas_ids)}")
    if len(towns) != 3:
        errors.append("living pilot requires three settlements")
    if not (root / data["map"].removeprefix("res://")).is_file():
        errors.append("living region map texture is missing")
    contract_ids: set[str] = set()
    for contract in data.get("contracts", []):
        if contract["id"] in contract_ids:
            errors.append("duplicate living contract id")
        contract_ids.add(contract["id"])
        if contract["issuer"] not in towns or contract["target"] not in ids:
            errors.append(f"contract {contract['id']} has an invalid issuer/target")
        if contract["faction"] not in {"river_league", "iron_march"}:
            errors.append(f"contract {contract['id']} has an unknown faction")
        if contract["kind"] not in {"restoration", "scout", "delivery"}:
            errors.append(f"contract {contract['id']} has an unknown objective")
    return errors
