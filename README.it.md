[English](README.md) | **Italiano**

# Universal Game Tools

Una raccolta personale di strumenti di sviluppo videogiochi riutilizzabili, modulari e documentati, generatori procedurali e sistemi realizzati con **Godot 4.7.2**, **GDScript**, **Blender** e flussi di lavoro assistiti dall'IA.

Gli strumenti sono indipendenti dal gioco: ognuno è progettato per poter essere copiato in un progetto Godot indipendente, o installato come addon. Nessuno dipende da un gioco specifico.

## Stato

| Modulo | Nome | Stato |
|---|---|---|
| [UPTG](UPTG/UniversalProceduralTerrainGenerator/README.it.md) | Universal Procedural Terrain Generator | Bozza di architettura 0.1, non ancora implementato |
| [UPRG](UPRG/UniversalProceduralRoadGenerator/README.it.md) | Universal Procedural Road Generator | Pianificato, non iniziato |
| [UPWG](UPWG/UniversalProceduralWorldGenerator/README.it.md) | Universal Procedural World Generator | Pianificato, non iniziato |

La priorità attuale è **UPTG**. Gli altri moduli non partiranno finché il primo generatore non sarà stato testato e approvato.

## Struttura del repository

```text
universal-game-tools/
├── README.md                 Questo file (inglese; README.it.md in italiano)
├── CHANGELOG.md              Modifiche a livello di repository
├── LICENSE
├── UPTG/
│   └── UniversalProceduralTerrainGenerator/
│       ├── addons/           Codice dell'addon Godot (runtime, risorse)
│       ├── demo/             Scene demo / di test autonome
│       ├── presets/          Preset di configurazione (.tres)
│       ├── documentation/    Architettura, test, documenti del modulo
│       └── README.md
├── UPRG/
│   └── UniversalProceduralRoadGenerator/    (segnaposto)
├── UPWG/
│   └── UniversalProceduralWorldGenerator/   (segnaposto)
└── Documentation/
    ├── architecture/         Architettura e decisioni comuni ai moduli
    └── development/          Istruzioni di progetto, workflow, convenzioni
```

Ogni strumento dovrebbe contenere: implementazione core, risorse di configurazione, integrazione opzionale con l'editor, una scena demo, documentazione, procedure di test e informazioni di versione.

## Ambiente di sviluppo

- Godot 4.7.2 (GDScript)
- Blender
- Claude Desktop / Cowork
- Git e GitHub
- Windows

## Documentazione

- [Istruzioni di progetto](Documentation/development/PROJECT_INSTRUCTIONS.it.md): identità, principi e workflow con l'IA
- [Workflow di sviluppo](Documentation/development/WORKFLOW.it.md): branch, commit, versionamento
- [Panoramica dell'architettura](Documentation/architecture/README.it.md): convenzioni comuni ai moduli
- [Architettura UPTG](UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE.md) (solo in inglese, in revisione)

## Principi di sviluppo

1. Riutilizzabilità prima della personalizzazione per un singolo gioco.
2. Architettura modulare.
3. Separazione netta tra sistemi core ed estensioni opzionali.
4. Compatibilità con Godot 4.7.2.
5. Documentazione per ogni strumento completato.
6. Sviluppo e test incrementali.
7. Preservare il codice funzionante e i file esistenti.
8. Non sovrascrivere mai file importanti senza approvazione.
9. Non dare mai per scontato che una funzione funzioni senza verificarla.
10. Preferire soluzioni semplici e manutenibili alla complessità superflua.
