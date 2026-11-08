[English](ADR-0008-uptg-cost-calibration.md) | **Italiano**

# ADR-0008: Calibrazione della stima dei costi di UPTG con misure reali

**Stato:** Accettata
**Data:** 2026-11-06
**Modulo:** UPTG

## Contesto

ADR-0006 ha introdotto la stima preventiva dei costi e ha lasciato i coefficienti di memoria come stime, da calibrare con misure in Milestone D, previa approvazione.

## Opzioni considerate

1. Tenere i coefficienti iniziali: nessuna modifica / il costo della trimesh era sottostimato di oltre 4 volte.
2. Sostituire i coefficienti con i valori misurati e mantenere le soglie: la stima corrisponde alla realtà e i livelli di protezione restano quelli approvati / i valori dipendono dagli interni di Godot 4.7.2.

## Decisione

Opzione 2 (architettura 0.2-r5, sezione 5.4). `estimated_bytes` vale `vertices * 112 + cells * 48`, più `cells * 320` con `TRIMESH`. Il coefficiente per cella passa da 24 a 48 perché gli indici sono presenti sia sulla CPU sia sulla GPU, quello della trimesh da 72 a 320 come misurato per `ConcavePolygonShape3D`. Le soglie non cambiano. Approvata da Stefano con la merge della Milestone D (pull request #5), 2026-11-06. Questo ADR è stato scritto in seguito, il 2026-11-08, per chiudere il punto lasciato aperto da ADR-0006.

## Conseguenze

512 × 512 celle in `HEIGHTMAP` stimano circa 40 MB (`OK`), e il caso più grande accettato, 1024 × 1024 celle in `TRIMESH`, circa 480 MB. Non è stata aggiunta alcuna soglia in secondi. Le misure sono in `documentation/TESTING.it.md`.

Fonte: `UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.md`
