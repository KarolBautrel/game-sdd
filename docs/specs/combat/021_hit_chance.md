# 021 Hit Chance

Status: planned  
Date: 2026-07-14

## Intent

Hit chance resolves whether an attack hits, misses, grazes, or critically hits.

## Planned Scope

- deterministic RNG seed use;
- accuracy stat;
- evasion stat;
- cover modifiers;
- distance modifiers;
- hit roll event shape;
- replay stability.

## Deferred Until

- deterministic round cycle exists;
- event log is stable for at least one complete combat;
- ranged targeting and line of sight are specified.

## Initial Questions

- Should melee attacks always hit in the early slice?
- Should hit chance be shown to the player before command confirmation?
- Is the target result binary hit/miss, or hit/graze/miss/crit?
- Should random rolls be precomputed or generated at command resolution?

