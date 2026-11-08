[English](ADR-0009-uptg-tool-only-baked-output.md) | **Italiano**

# ADR-0009: UPTG è uno strumento privato, in un gioco entra solo il risultato esportato

**Stato:** Accettata
**Data:** 2026-11-08
**Modulo:** tutto il repository

## Contesto

La versione 0.1.0 genera il terreno durante l'esecuzione e la sua guida descrive la copia dell'addon in un gioco. UPTG è privato e non è in vendita, mentre Nitro Underground è un prodotto destinato alla vendita. I due programmi devono restare separati.

## Opzioni considerate

1. Includere l'addon nel gioco e generare durante l'esecuzione: nessun passaggio di esportazione / lo strumento diventa parte del prodotto e la generazione gira sul telefono del giocatore.
2. Generare nel progetto UPTG e dare al gioco normali file Godot: il gioco non contiene codice UPTG e carica un mondo finito / per cambiare il mondo bisogna esportarlo di nuovo.

## Decisione

Opzione 2. UPTG e tutti i suoi sotto-programmi sono strumenti di sviluppo che creano mondi e oggetti 3D per altri software. Uno strumento di bake fuori dall'addon scrive un file `.scn` autonomo, senza script e senza riferimenti a UPTG (architettura 0.2-r6, sezione 12.5). Le licenze restano come sono. Decisione di Stefano, 2026-11-08.

## Conseguenze

Il codice di generatore, seed, mesh e collisione non cambia. I futuri sotto-programmi (strade, modifiche al terreno, luoghi e villaggi, skin e texture) seguono la stessa regola. Il file esportato dipende dalla versione di Godot che lo ha scritto.

Fonte: `UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.it.md`
