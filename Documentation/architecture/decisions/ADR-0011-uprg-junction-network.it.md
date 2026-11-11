[English](ADR-0011-uprg-junction-network.md) | **Italiano**

# ADR-0011: UPRG costruisce gli incroci come un'unica rete dopo aver pianificato tutte le strade

**Stato:** Accettata
**Data:** 2026-11-09
**Modulo:** UPRG

## Contesto

Strade separate che si attraversano devono incontrarsi alla stessa altezza, su un'unica superficie pulita, e rispettare i limiti di pendenza. Stefano ha chiesto incroci e vie dei villaggi il 2026-11-09.

## Opzioni considerate

1. Ogni strada modifica il terreno a turno, le successive sopra: semplice / gradini e superfici sovrapposte dove le strade si incrociano.
2. Pianificare prima tutte le strade, poi risolvere insieme i punti d'incontro: un'altezza per incrocio e un'unica superficie / un calcolo che può rifiutare disposizioni impossibili.

## Decisione

Opzione 2. La strada elencata per prima mantiene la sua altezza e le altre si adattano; le altezze degli incroci si spostano solo quanto serve alle pendenze. Ogni incrocio sostituisce i campioni di strada vicini con una sua superficie. Presa durante il lavoro chiesto da Stefano, e aperta alla sua revisione.

## Conseguenze

L'ordine delle strade ora indica la priorità. Disposizioni con incontri troppo stretti o incroci troppo vicini vengono rifiutate con un messaggio invece di produrre superfici rotte. I ponti richiederebbero un nuovo tipo di incrocio.

Fonte: `UPRG/UniversalProceduralRoadGenerator/documentation/UPRG_ARCHITECTURE_0.2.it.md`
