# 020 Terrain Debug Visible

Status: verified  
Date: 2026-07-14

## Intent

This debug scenario proves that combat terrain is visible in the debug scene.

## Expected Debug Scene Behavior

- `floor` tiles use the default floor color.
- `blocked` tiles use a dark obstacle color.
- `highground` tiles use a distinct elevated terrain color.
- Legal target highlighting can still override base terrain color.

## Manual Acceptance

1. Start the combat debug scene.
2. Confirm at least one blocked tile is visible as dark terrain.
3. Confirm at least one highground tile is visible as a distinct elevated tile.
4. Select `move`.
5. Legal highground destinations are highlighted when reachable.

