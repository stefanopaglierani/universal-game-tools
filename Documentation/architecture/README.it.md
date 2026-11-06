[English](README.md) | **Italiano**

# Panoramica dell'architettura

Regole di architettura comuni che valgono per ogni modulo di Universal Game Tools.

## Anatomia di un modulo

Ogni strumento vive in `<CODICE>/<NomeCompleto>/` e idealmente contiene:

- **Implementazione core**: codice runtime in `addons/<codice>/runtime/`
- **Risorse di configurazione**: script `Resource` personalizzati in `addons/<codice>/resources/`, preset come `.tres`
- **Integrazione opzionale con l'editor**: separata dal codice runtime
- **Scena demo**: autonoma, eseguibile senza altri moduli
- **Documentazione**: architettura, utilizzo, test
- **Procedure di test**: `documentation/TESTING.md`
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
| UPTG | [UPTG_ARCHITECTURE.md](../../UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE.md) (in inglese) |
| UPRG | Non ancora scritto |
| UPWG | Non ancora scritto |

## Decisioni

Le decisioni architetturali importanti sono registrate come ADR in [`decisions/`](decisions/), usando il [modello](decisions/ADR-0000-template.it.md).
