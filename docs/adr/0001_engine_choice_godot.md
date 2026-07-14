# ADR 0001: Use Godot 4.7 With GDScript

Status: accepted  
Date: 2026-07-14

## Context

The project is a 2D pixel art RPG/roguelite with world map, town, dungeon exploration, and turn-based combat modes.

## Decision

Use Godot 4.7 stable and GDScript for the initial implementation.

## Consequences

- Fast iteration for 2D scenes, UI, input, and asset import.
- Low project setup cost.
- Domain logic must be kept separate from scene presentation code.
- C# is deferred until there is a concrete need.

