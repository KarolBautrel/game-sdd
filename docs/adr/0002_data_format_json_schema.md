# ADR 0002: Use JSON And JSON Schema For Content Contracts

Status: accepted  
Date: 2026-07-14

## Context

The project needs content that can be validated automatically before gameplay code consumes it.

## Decision

Use JSON for runtime content data and JSON Schema for structural contracts.

## Consequences

- Data can be reviewed outside Godot.
- Validators can run without opening the editor.
- Content errors should be caught before scenes load.
- CSV can be used later for balance tables, but imported output should be JSON.

