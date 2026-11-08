[English](README.md) | **Italiano**

# UPRG — Universal Procedural Road Generator

**Stato:** prima versione in sviluppo (0.1.0, non ancora taggata)
**Motore:** Godot 4.7.2 (GDScript)

Uno strumento di sviluppo privato: aggiunge strade a un terreno esportato da UPTG e scrive un nuovo file del mondo. Spiana il terreno sotto la strada e aggiunge la superficie stradale e la sua collisione. Un gioco apre il risultato senza codice UPTG o UPRG.

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
godot --headless --path . -s res://tools/uprg_bake.gd -- --in=C:/Temp/isola.scn --road=res://presets/example_road_island.tres --out=C:/Temp/isola_strada.scn
godot --path . res://demo/uprg_viewer.tscn -- --file=C:/Temp/isola_strada.scn
```

La strada segue i punti del file `.tres`, in metri dal centro del terreno. Aprilo nell'editor di Godot per cambiare punti, larghezza e pendenza, oppure duplicalo per una nuova strada. Ripeti `--road=` per aggiungere altre strade.

## Documentazione

- [Architettura](documentation/UPRG_ARCHITECTURE_0.1.it.md)
- [Test](documentation/TESTING.it.md)
- [Changelog](CHANGELOG.it.md)
