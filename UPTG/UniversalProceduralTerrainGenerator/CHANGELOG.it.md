[English](CHANGELOG.md) | **Italiano**

# Changelog di UPTG

Qui sono documentate tutte le modifiche rilevanti a UPTG.
Il formato segue [Keep a Changelog](https://keepachangelog.com/it-IT/1.1.0/) e il modulo usa il [Versionamento Semantico](https://semver.org/lang/it/).

## [Non rilasciato]

### Aggiunto
- Versione inglese dell'architettura 0.2 (`documentation/UPTG_ARCHITECTURE_0.2.md`). Il testo italiano, invariato, è ora in `documentation/UPTG_ARCHITECTURE_0.2.it.md`.
- Screenshot della demo delle Milestone B, C e D in `documentation/screenshots/`, elencati in `documentation/TESTING.it.md`.

### Modificato
- README del modulo aggiornato per la versione 0.1.0 e per la struttura R12 dell'addon.

## [0.1.0] - 2026-11-06

Primo generatore di isole funzionante. `ALGORITHM_VERSION` vale 1.

### Aggiunto
- Progetto Godot 4.7.2 (`project.godot`) del modulo.
- Struttura dell'addon `addons/uptg/` (`core/`, `builders/`, `nodes/`, `materials/`, `presets/`) e cartella `tests/`, come definito nell'architettura 0.2 (R12).
- `addons/uptg/LICENSE`, copia della licenza del repository (tutti i diritti riservati).
- Specifica di architettura 0.2 (`documentation/UPTG_ARCHITECTURE_0.2.md`, in italiano), revisione 0.2-r3 con i risultati della Milestone 0.
- Risultati della verifica della Milestone 0 (`documentation/M0_VERIFICATION.md`).
- ADR-0001 … ADR-0006 in `Documentation/architecture/decisions/`.
- Milestone A, dati e height field (ancora senza scena), in `addons/uptg/core/`: `UPTGConfig` (parametri, validazione, stima dei costi), `UPTGMountainRegion`, `UPTGSeed` (derivazione dei sub-seed), `UPTGTerrainData` (height field, maschera della terra, checksum, interrogazioni di altezza e normale) e `UPTGHeightfieldGenerator`. Il noise è campionato con offset derivati dal seed (architettura 0.2-r4), quindi anche il centro dell'isola cambia con il seed.
- Esecutore dei test headless e suite in `tests/` (seed, validazione e protezione dai costi, determinismo), documentati in `documentation/TESTING.it.md`.
- Milestone B: `UPTGMeshBuilder` (mesh indicizzata, normali dall'height field, UV planari, vertex colors sabbia/erba/roccia), materiale predefinito `addons/uptg/materials/uptg_terrain_default.tres`, nodo `UPTGTerrain` (rigenerazione atomica, segnali, statistiche, quota in spazio mondo; la collisione arriva nella Milestone C), scena demo `demo/uptg_demo.tscn`, test `test_mesh.gd` e `test_terrain_node.gd`.
- Milestone C: `UPTGCollisionBuilder` (`HEIGHTMAP`, `TRIMESH`, `NONE`), nodi di collisione `UPTGBody/UPTGShape` con `collision_layer` e `collision_mask` esportati in `UPTGTerrain`, scena di test `tests/collision/collision_test.tscn` (A8, A9, verificata con Godot Physics e Jolt), "Drop balls" nella demo.
- Milestone D: preset isola `addons/uptg/presets/uptg_island_default.tres`, usato dalla demo; guida dell'addon `addons/uptg/README.it.md`; script di misura `tests/benchmark.gd` con le misure della sezione 13 dell'architettura in `documentation/TESTING.it.md`.

### Modificato
- Preset isola tarato dopo la demo (D7): `land_base_height` 8 m, `min_land_height` 2.5 m, `terrain_noise_amplitude` 10 m, `rock_slope_degrees` 38, `rock_height` 60 m; regione montuosa predefinita con `radius` 0.22, `peak_height` 80 m, `falloff` 1.2.
- Vertex colors: la sabbia ha ora la precedenza sulla roccia, così le scarpate costiere basse restano sabbia.
- Stima dei costi calibrata con misure reali: `BYTES_PER_CELL` 48 (prima 24), `BYTES_PER_CELL_TRIMESH` 320 (prima 72); soglie invariate. Revisione dell'architettura 0.2-r5.
- `UPTGTerrain.generate()` ignora, con un avviso, una chiamata fatta durante una generazione in corso, e avvisa quando genera una configurazione `LARGE`; la demo mostra la stima dei costi prima di generare.
- Le verifiche di collisione A9 usano un proprio terreno moderato, indipendente dalla taratura del preset.
