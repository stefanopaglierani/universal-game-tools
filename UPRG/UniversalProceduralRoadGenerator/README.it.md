[English](README.md) | **Italiano**

# UPRG — Universal Procedural Road Generator

**Stato:** prima versione in sviluppo (0.1.0, non ancora taggata)
**Motore:** Godot 4.7.2 (GDScript)

Uno strumento di sviluppo privato: prende un terreno esportato da UPTG e scrive un nuovo file del mondo con modifiche al terreno, strade, luoghi con edifici e texture personalizzate. Un gioco apre il risultato senza codice UPTG o UPRG.

## Cartelle

| Cartella | Contenuto |
|---|---|
| `addons/uprg/` | Il generatore: `core/`, `builders/` |
| `tools/` | `uprg_bake.gd`, il punto di ingresso da riga di comando |
| `presets/` | Descrizioni delle strade salvate come `.tres` |
| `demo/` | `uprg_viewer.tscn`, mostra qualsiasi file del mondo esportato |
| `tests/` | Suite di test headless |
| `documentation/` | Architettura e test |

## Utilizzo

Apri un prompt dei comandi in questa cartella (il primo comando serve una volta, dopo un nuovo clone o un nuovo script):

```
godot --headless --editor --quit
godot --headless --path . -s res://tools/uprg_bake.gd -- --in=C:/Temp/isola.scn --world=res://presets/example_world_island.tres --out=C:/Temp/mondo.scn
godot --path . res://demo/uprg_viewer.tscn -- --file=C:/Temp/mondo.scn
```

La descrizione del mondo è un unico file `.tres`: apri `presets/example_world_island.tres` nell'editor di Godot, oppure duplicalo per un nuovo mondo.

| Sezione | Cosa imposti |
|---|---|
| `terrain_edits` | Aree circolari da alzare, abbassare (`ADD`) o livellare (`LEVEL`) |
| `places` | Nome, centro, raggio, numero e dimensioni degli edifici, colori di muri e tetti, seed |
| `roads` | Punti in metri dal centro del terreno, larghezza, pendenza |
| `skin` | Immagini per strade, terreno ed edifici, e tinte di colore |

Funziona anche una sola strada: `--road=<strada.tres>`, ripetibile.

## Documentazione

- [Architettura](documentation/UPRG_ARCHITECTURE_0.1.it.md)
- [Test](documentation/TESTING.it.md)
- [Changelog](CHANGELOG.it.md)
