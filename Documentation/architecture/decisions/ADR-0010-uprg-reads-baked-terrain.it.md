[English](ADR-0010-uprg-reads-baked-terrain.md) | **Italiano**

# ADR-0010: UPRG lavora sul file del terreno esportato

**Stato:** Accettata
**Data:** 2026-11-08
**Modulo:** UPRG

## Contesto

Le strade devono spianare il terreno, ma `UPTGTerrainData` è in sola lettura in UPTG v0.1 e le dipendenze tra moduli vanno in una sola direzione. I progetti Godot non possono condividere un addon che sta fuori da loro senza copiarlo.

## Opzioni considerate

1. Mettere le strade dentro UPTG: un solo progetto / mescola due strumenti e cambia il contratto.
2. Copiare l'addon UPTG in UPRG: accesso diretto al generatore / una copia che resta indietro.
3. Leggere il file esportato da UPTG e scriverne uno nuovo: nessun codice condiviso, UPTG invariato / UPRG dipende dal formato del file.

## Decisione

Opzione 3. Il formato del file (`format_version` 1) è il contratto tra i due strumenti. Stefano ha chiesto di procedere con il generatore di strade il 2026-11-08; questa scelta è stata fatta in quel lavoro e resta aperta alla sua revisione.

## Conseguenze

Ogni strumento si sviluppa da solo e i sotto-programmi futuri possono concatenarsi allo stesso modo. Per cambiare la modifica del terreno si riesporta partendo dal file UPTG. Un cambio di formato richiede un nuovo `format_version`.

Fonte: `UPRG/UniversalProceduralRoadGenerator/documentation/UPRG_ARCHITECTURE_0.1.it.md`
