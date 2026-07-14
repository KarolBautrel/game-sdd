# 011 Combat Slice 06 Defend

Status: verified  
Date: 2026-07-14

## Intent

This executable scenario proves that a unit can spend AP to apply the `defending` status.

## Scenario

Player starts with 1 AP and performs `defend`.

## Expected Result

- player AP becomes `0`;
- player receives `defending`;
- event log contains `action_performed` and `status_applied`;
- combat remains `in_progress`.

