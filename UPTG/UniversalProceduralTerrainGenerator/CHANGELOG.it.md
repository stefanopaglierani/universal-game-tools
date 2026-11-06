[English](CHANGELOG.md) | **Italiano**

# Changelog di UPTG

Qui sono documentate tutte le modifiche rilevanti a UPTG.
Il formato segue [Keep a Changelog](https://keepachangelog.com/it-IT/1.1.0/) e il modulo usa il [Versionamento Semantico](https://semver.org/lang/it/).

## [Non rilasciato]

### Aggiunto
- Progetto Godot 4.7.2 (`project.godot`) del modulo.
- Struttura dell'addon `addons/uptg/` (`core/`, `builders/`, `nodes/`, `materials/`, `presets/`) e cartella `tests/`, come definito nell'architettura 0.2 (R12).
- `addons/uptg/LICENSE`, copia della licenza del repository (tutti i diritti riservati).
- Specifica di architettura 0.2 (`documentation/UPTG_ARCHITECTURE_0.2.md`, in italiano), revisione 0.2-r3 con i risultati della Milestone 0.
- Risultati della verifica della Milestone 0 (`documentation/M0_VERIFICATION.md`).
- ADR-0001 … ADR-0006 in `Documentation/architecture/decisions/`.
- Milestone A, dati e height field (ancora senza scena), in `addons/uptg/core/`: `UPTGConfig` (parametri, validazione, stima dei costi), `UPTGMountainRegion`, `UPTGSeed` (derivazione dei sub-seed), `UPTGTerrainData` (height field, maschera della terra, checksum, interrogazioni di altezza e normale) e `UPTGHeightfieldGenerator`.
- Esecutore dei test headless e suite in `tests/` (seed, validazione e protezione dai costi, determinismo), documentati in `documentation/TESTING.it.md`.
