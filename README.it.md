[English](README.md) | **Italiano**

# Universal Game Tools

Una raccolta personale di strumenti di sviluppo videogiochi riutilizzabili, modulari e documentati, generatori procedurali e sistemi realizzati con **Godot 4.7.2**, **GDScript**, **Blender** e flussi di lavoro assistiti dall'IA.

Gli strumenti sono privati e indipendenti dal gioco: creano mondi e oggetti 3D per altri software. In un gioco entra solo ciò che generano, mai il loro codice. Nessuno dipende da un gioco specifico.

## Stato

| Modulo | Nome | Stato |
|---|---|---|
| [UPTG](UPTG/UniversalProceduralTerrainGenerator/README.it.md) | Universal Procedural Terrain Generator | Versione 0.1.0 rilasciata (tag `uptg-v0.1.0`): generatore procedurale di isole con mesh, collisione e demo |
| [UPRG](UPRG/UniversalProceduralRoadGenerator/README.it.md) | Universal Procedural Road Generator | Prima versione in sviluppo: strade sui terreni esportati |
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
│       ├── project.godot     Progetto Godot autonomo del modulo
│       ├── addons/uptg/      Addon portabile: core, builders, nodes, materials, presets
│       ├── demo/             Scena demo autonoma
│       ├── tests/            Suite di test headless, test di collisione, benchmark
│       ├── tools/            Strumento di bake: scrive un mondo su file per un gioco
│       ├── presets/          Riservata, vuota in v0.1 (il preset è in addons/uptg/presets/)
│       ├── documentation/    Architettura, test, verifiche, screenshot
│       ├── CHANGELOG.md      Modifiche del modulo
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
- [Architettura UPTG 0.2](UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.it.md) ([bozza 0.1](UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE.md), in inglese, resta come riferimento storico)
- [Guida dell'addon UPTG](UPTG/UniversalProceduralTerrainGenerator/addons/uptg/README.it.md): installazione e utilizzo
- [Test di UPTG](UPTG/UniversalProceduralTerrainGenerator/documentation/TESTING.it.md): suite di test, benchmark, verifiche manuali

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
