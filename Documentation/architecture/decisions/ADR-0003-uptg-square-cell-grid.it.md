[English](ADR-0003-uptg-square-cell-grid.md) | **Italiano**

# ADR-0003: Griglia UPTG: celle quadrate definite da numero di celle e `cell_size`

**Stato:** Accettata
**Data:** 2026-11-06
**Modulo:** UPTG

## Contesto

Il Draft 0.1 usava dimensione e risoluzione indipendenti per asse, permettendo celle non quadrate (incompatibili con la scala uniforme della heightmap) e senza chiarire se la risoluzione contasse vertici o celle.

## Opzioni considerate

1. Mantenere `terrain_size_x/z` + `resolution_x/z`: familiare / celle non quadrate, ambiguità di uno.
2. `grid_cells_x`, `grid_cells_z` e un solo `cell_size`: celle sempre quadrate, dimensione derivata / la dimensione non si imposta direttamente.

## Decisione

Opzione 2. La risoluzione è il numero di celle; i vertici sono sempre celle + 1. Il terreno è centrato sull'origine del nodo; il vertice `(ix, iz)` si trova in `((ix - celle_x/2) * cell_size, h, (iz - celle_z/2) * cell_size)` ed è memorizzato all'indice `iz * (celle_x + 1) + ix`. Deciso da Stefano, 2026-11-06.

## Conseguenze

Coincide esattamente con `HeightMapShape3D` (verificato in Milestone 0). Noise e maschera lavorano in coordinate mondo, quindi cambiare il numero di celle cambia il dettaglio e non la forma dell'isola. La dimensione della griglia è limitata dalla protezione dei costi (ADR-0006).

Fonte: `UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.md`
