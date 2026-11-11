[English](ADR-0013-uprg-rings-and-connected-network.md) | **Italiano**

# ADR-0013: Gli anelli partono lontano dagli incroci, e un mondo può richiedere un'unica rete collegata

**Stato:** Accettata
**Data:** 2026-11-11
**Modulo:** UPRG

## Contesto

I circuiti sono strade chiuse. Stefano ha anche fissato una regola per i suoi mondi: ogni circuito e strada deve far parte di un'unica rete percorribile, e un circuito staccato non deve esistere.

## Opzioni considerate

1. Gestire gli incroci a cavallo del punto di chiusura di un anello: generale / ogni calcolo sugli incroci deve girare attorno.
2. Far partire ogni anello dal suo punto più lontano da altre strade e luoghi, così nessun incrocio cade sulla chiusura: semplice, codice degli incroci invariato / un anello toccato ovunque da altre strade non si sistema bene.

Per la regola: un controllo nel bake, attivabile per mondo (`connected_roads`), invece che sempre attivo, perché anche una strada singola resta utile da sola.

## Decisione

Opzione 2, e il controllo `connected_roads`, che indica le strade non collegate. Stefano ha dato la regola il 2026-11-11.

## Conseguenze

Anelli, incroci e vie funzionano insieme. I mondi che usano il controllo non possono contenere per errore strade staccate.

Fonte: `UPRG/UniversalProceduralRoadGenerator/documentation/UPRG_ARCHITECTURE_0.2.it.md`
