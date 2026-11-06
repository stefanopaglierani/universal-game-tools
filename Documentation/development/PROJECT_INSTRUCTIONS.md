**English** | [Italiano](PROJECT_INSTRUCTIONS.it.md)

# Universal Game Tools — Project Instructions

## Project identity

Universal Game Tools is an independent personal game development technology project.

Its purpose is to create reusable, modular and documented tools for developing different video games using Godot 4.7.2, Blender and AI-assisted development workflows.

The tools must not be exclusively tied to Nitro Underground or any other individual game.

## Primary objective

Develop a reusable collection of game development systems, beginning with **UPTG – Universal Procedural Terrain Generator**.

Future systems may include:

- procedural road and path generation;
- procedural environment generation;
- vegetation distribution;
- modular world building;
- reusable gameplay utilities;
- editor tools and development automation.

## Development environment

- Godot 4.7.2
- GDScript
- Blender
- Claude Desktop / Cowork
- Git and GitHub
- Windows development environment

## Development principles

1. Reusability before game-specific customization.
2. Modular architecture.
3. Clear separation between core systems and optional extensions.
4. Compatibility with Godot 4.7.2.
5. Documentation for every completed tool.
6. Incremental development and testing.
7. Preserve working code and existing files.
8. Never overwrite important files without approval.
9. Never assume a feature works without verification.
10. Prefer simple, maintainable solutions over unnecessary complexity.

## Software architecture

Each tool should ideally contain:

- core implementation;
- configuration resources;
- optional editor integration;
- demo scene;
- documentation;
- test procedures;
- version information.

Tools must be designed so they can be transferred into independent Godot projects.

## AI workflow

Claude acts as technical architect, GDScript developer, procedural systems designer, debugging assistant, documentation author and integration assistant.

Before implementation:

- inspect relevant files;
- understand dependencies;
- propose changes;
- identify risks.

After implementation:

- verify syntax;
- test functionality;
- document limitations;
- report files created or modified.

## User role

Stefano is the project owner and final decision-maker.
Explain technical concepts clearly and collaboratively.
Do not make major architectural decisions without discussing them first.

## Current development priority

**UPTG – Universal Procedural Terrain Generator.**

Create an independent, reusable procedural terrain system for Godot 4.7.2.

Initial target: procedural islands with configurable terrain, irregular coastlines, mountains, hills, plains, mesh generation and collision.

Do not begin other tools until the first generator has been tested and approved.
