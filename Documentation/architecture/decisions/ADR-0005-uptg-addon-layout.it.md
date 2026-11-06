[English](ADR-0005-uptg-addon-layout.md) | **Italiano**

# ADR-0005: Struttura dell'addon UPTG (R12)

**Stato:** Accettata
**Data:** 2026-11-06
**Modulo:** UPTG

## Contesto

UPTG deve poter essere copiato in altri progetti Godot con tutto ciò che gli serve. I documenti generali del repository descrivono `addons/<code>/runtime/` + `resources/` e una cartella `presets/` a livello di modulo.

## Opzioni considerate

1. Seguire i documenti generali: coerente con il testo esistente / preset predefinito fuori dall'addon, meno portabile.
2. R12: `core/`, `builders/`, `nodes/`, `materials/`, `presets/` dentro `addons/uptg/`: addon autosufficiente / documenti generali temporaneamente non aggiornati.

## Decisione

Opzione 2. Ogni modulo è un progetto Godot autonomo; `addons/uptg/` è l'unica cartella copiata nei giochi e usa solo percorsi `res://addons/uptg/...`. Nessun `plugin.cfg` in v0.1. I documenti generali del repository non vengono modificati ora; per UPTG prevale il documento di architettura. Deciso da Stefano, 2026-11-06.

## Conseguenze

La struttura è stata creata nella Milestone 0. L'allineamento dei documenti generali e il destino della cartella `presets/` di modulo sono rinviati a un aggiornamento documentale separato e approvato.

Fonte: `UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.md`
