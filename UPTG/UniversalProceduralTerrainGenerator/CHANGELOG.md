**English** | [Italiano](CHANGELOG.it.md)

# UPTG Changelog

All notable changes to UPTG are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the module uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Godot 4.7.2 project (`project.godot`) for the module.
- Addon folder structure `addons/uptg/` (`core/`, `builders/`, `nodes/`, `materials/`, `presets/`) and `tests/`, as defined in architecture 0.2 (R12).
- `addons/uptg/LICENSE`, a copy of the repository license (all rights reserved).
- Architecture specification 0.2 (`documentation/UPTG_ARCHITECTURE_0.2.md`, Italian), revision 0.2-r3 with Milestone 0 results.
- Milestone 0 verification results (`documentation/M0_VERIFICATION.md`).
- ADR-0001 to ADR-0006 in `Documentation/architecture/decisions/`.
- Milestone A, data and height field (no scene yet), in `addons/uptg/core/`: `UPTGConfig` (parameters, validation, cost estimate), `UPTGMountainRegion`, `UPTGSeed` (sub-seed derivation), `UPTGTerrainData` (height field, land mask, checksums, height and normal queries) and `UPTGHeightfieldGenerator`.
- Headless test runner and suites in `tests/` (seed, validation and cost protection, determinism), documented in `documentation/TESTING.md`.
