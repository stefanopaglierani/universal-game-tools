[English](ADR-0007-uptg-seed-derived-noise-offsets.md) | **Italiano**

# ADR-0007: Offset di campionamento del noise di UPTG derivati dal seed

**Stato:** Accettata
**Data:** 2026-11-06
**Modulo:** UPTG

## Contesto

Durante la Milestone A è emerso che il noise simplex vale 0 nell'origine per qualunque seed. Senza una correzione, il centro dell'isola non riceveva variazioni di costa né di rilievo e restava uguale con ogni seed.

## Opzioni considerate

1. Lasciare tutto com'è: nessun codice / il centro dell'isola ignora il seed.
2. Campionare ogni noise in `(x, z)` più un offset derivato dal seed: il centro varia con il seed e la generazione resta deterministica / due salt in più da mantenere.

## Decisione

Opzione 2 (architettura 0.2-r4, sezioni 7.1, 8.2 e 8.3). I noise di costa e rilievo sono campionati con offset ottenuti da `UPTGSeed.noise_offset()`, usando i nuovi salt `SALT_COASTLINE_OFFSET` (4) e `SALT_TERRAIN_OFFSET` (5). Ogni componente dell'offset è un numero intero di metri tra 1024 e 9215. Approvata da Stefano durante la Milestone A, 2026-11-06. Questo ADR è stato scritto in seguito, il 2026-11-08, per completare la registrazione iniziata con ADR-0004.

## Conseguenze

L'offset si somma in metri, quindi non dipende dalla risoluzione della griglia. `ALGORITHM_VERSION` è rimasta 1, perché la formula precedente non è mai stata rilasciata.

Fonte: `UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.it.md`
