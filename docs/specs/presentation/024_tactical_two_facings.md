# Tactical battle: two front three-quarter facings

Stage62, user-authorized2026-11-03: tactical actors display only south_east and
south_west. This supersedes presentation022/023's eight-view battle selection,
while retaining every authored view, source and gallery for future uses.

The battle sprite boundary converts east/north_east/south_east to south_east and
west/north_west/south_west to south_west. Pure north/south, coincident or absent
targets use the team's default front three-quarter view: player south_east,
enemy south_west. Thus an opponent above never makes an actor show its back or
frontal/profile drawing. All factions/families, including legacy actors and the
Bran greatsword variant, obey this rule in tactical battles.

The same policy applies to neutral/ready idle, movement path steps, attacks,
reactions and the held final corpse. Positions, path geometry, targeting, arrows,
hit resolution, damage, AP/MP and timing/stride remain owned by existing rules.
Directional events keep their full spatial information; only the displayed
sprite is reduced to two facings. Combat preloads only the two displayed views.

Raw sheet lookup, offline source players and art galleries retain all eight
views. Do not delete or regenerate raster/Aseprite files, drop registry facings,
mirror a sprite again at runtime or implement city movement as part of this task.
Archive inspection uses the original/legacy visual context (not valid battle
factions), preserving raw identity and requested direction even through icon
rendering. Normal hero/villain sprites always use the two-view battle policy.

Proof: slice024 and tactical_facing_tests.gd verify both teams/all directions,
raw archive access and actual HUD startup, northward movement, above-left/right
bow attacks and final corpses. Existing drawn/battle/lifecycle/domain and campaign
regressions plus repository validation must pass. Physical visual acceptance is
L62-01 and remains open until the user plays the changed tactical view.
