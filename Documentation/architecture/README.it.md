[English](README.md) | **Italiano**

# Panoramica dell'architettura

Regole di architettura comuni che valgono per ogni modulo di Universal Game Tools.

## Anatomia di un modulo

Ogni strumento vive in `<CODICE>/<NomeCompleto>/` e idealmente contiene:

- **Implementazione core**: codice runtime in `addons/<codice>/`, diviso per responsabilità (UPTG: `core/`, `builders/`, `nodes/`, `materials/`)
- **Risorse di configurazione**: script `Resource` personalizzati dentro l'addon (UPTG: `core/`), preset come `.tres` in `addons/<codice>/presets/`
- **Integrazione opzionale con l'editor**: separata dal codice runtime
- **Scena demo**: autonoma, eseguibile senza altri moduli
- **Documentazione**: architettura, utilizzo, test
- **Procedure di test**: `documentation/TESTING.md`, suite automatiche in `tests/`
- **Informazioni di versione**: `CHANGELOG.md` del modulo con versioni semantiche

## Regole

- I moduli sono indipendenti dal gioco: nel core non c'è logica di gameplay, veicoli, missioni o altro legato a un gioco specifico.
- Un modulo deve poter essere trasferito in un progetto Godot indipendente seguendo passaggi documentati.
- Sistemi core ed estensioni opzionali sono chiaramente separati.
- Le dipendenze tra moduli vanno in una sola direzione e sono documentate (per esempio UPRG può dipendere dall'output di UPTG, mai il contrario).
- Quando c'è casualità, la generazione è deterministica a partire da un seed.

## Moduli

| Modulo | Documento di architettura |
|---|---|
| UPTG | [UPTG_ARCHITECTURE_0.2.it.md](../../UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.it.md); sostituisce la [bozza 0.1](../../UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE.md), in inglese |
| UPRG | Non ancora scritto |
| UPWG | Non ancora scritto |

## Decisioni

Le decisioni architetturali importanti sono registrate come ADR in [`decisions/`](decisions/), usando il [modello](decisions/ADR-0000-template.it.md).

- [ADR-0001: Contratto dati del terreno UPTG (`UPTGTerrainData`)](decisions/ADR-0001-uptg-terrain-data-contract.it.md)
- [ADR-0002: Collisione UPTG: `HeightMapShape3D` come predefinita](decisions/ADR-0002-uptg-heightmap-collision.it.md)
- [ADR-0003: Griglia UPTG: celle quadrate definite da numero di celle e `cell_size`](decisions/ADR-0003-uptg-square-cell-grid.it.md)
- [ADR-0004: Gestione del seed e garanzia di determinismo di UPTG](decisions/ADR-0004-uptg-seed-and-determinism.it.md)
- [ADR-0005: Struttura dell'addon UPTG (R12)](decisions/ADR-0005-uptg-addon-layout.it.md)
- [ADR-0006: Protezione di UPTG da configurazioni troppo costose](decisions/ADR-0006-uptg-cost-protection.it.md)
- [ADR-0007: Offset di campionamento del noise di UPTG derivati dal seed](decisions/ADR-0007-uptg-seed-derived-noise-offsets.it.md)
- [ADR-0008: Calibrazione della stima dei costi di UPTG con misure reali](decisions/ADR-0008-uptg-cost-calibration.it.md)
