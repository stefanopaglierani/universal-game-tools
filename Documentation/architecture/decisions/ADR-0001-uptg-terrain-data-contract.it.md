[English](ADR-0001-uptg-terrain-data-contract.md) | **Italiano**

# ADR-0001: Contratto dati del terreno UPTG (`UPTGTerrainData`)

**Stato:** Accettata
**Data:** 2026-11-06
**Modulo:** UPTG

## Contesto

I moduli futuri (strade, vegetazione, world generation) richiedono informazioni sul terreno. Il Draft 0.1 diceva solo che il generatore avrebbe "restituito o esposto" un risultato, costringendo ogni consumatore a dipendere dai dettagli interni del generatore.

## Opzioni considerate

1. Esporre gli array interni del generatore: nessun lavoro ora / ogni modifica interna rompe i consumatori.
2. I consumatori leggono la mesh: già disponibile / lenta, con perdita di informazioni e legata al rendering.
3. Un oggetto dati dedicato in sola lettura, con campi e query documentati: un contratto stabile / va mantenuto e versionato.

## Decisione

Opzione 3. `UPTGTerrainData` (`RefCounted`) contiene altezze, maschera, dimensioni della griglia, `cell_size`, livello e profondità del mare, checksum e `ALGORITHM_VERSION`, più query come `get_height_at()`. È l'unica interfaccia tra UPTG e gli altri sistemi (architettura §9). Deciso da Stefano, 2026-11-06.

## Conseguenze

I builder di mesh e collisione ricevono questo oggetto. Le modifiche incompatibili del contratto richiedono un incremento di versione maggiore e una voce nel CHANGELOG. La modifica del terreno da parte di altri moduli non è coperta in v0.1 e richiede una decisione separata.

Fonte: `UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.md`
