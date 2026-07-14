# 011 Diagonal Attack

Status: verified  
Date: 2026-07-14

## Intent

This executable scenario proves that melee attacks can target diagonal enemies.

## Scenario

Player starts at `{ "x": 1, "y": 1 }`. Enemy starts diagonally adjacent at `{ "x": 2, "y": 2 }`. Player performs `basic_attack`.

## Expected Result

- command action is `basic_attack`;
- player AP is reduced from `1` to `0`;
- enemy HP is reduced from `6` to `4`;
- event log contains `damage_applied`;
- combat remains `in_progress`.

## Rule Proven

Melee adjacency uses Chebyshev distance 1.

