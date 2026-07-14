# 017 Debug Legal Target Feedback

Status: verified  
Date: 2026-07-14

## Intent

This executable/debug scenario proves that the combat debug scene exposes resolver-backed feedback instead of hiding legal state in the UI.

## Expected Debug Scene Behavior

- Active unit tile is visibly highlighted.
- When `move` is selected, legal move destinations are visibly highlighted.
- When `basic_attack` is selected, legal enemy targets are visibly highlighted.
- Rejected commands show the last rejection reason in a visible feedback label.
- Highlighting is derived by testing commands through the combat resolver, not by duplicating combat legality rules in presentation code.

## Manual Acceptance

1. Start the combat debug scene.
2. Select `move`.
3. Adjacent legal tiles are highlighted.
4. Click an illegal tile.
5. Feedback label shows the rejection reason.
6. Select `basic_attack`.
7. Legal enemy targets are highlighted when in range.

