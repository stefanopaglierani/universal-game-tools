[English](README.md) | **Italiano**

# UPTG — Universal Procedural Terrain Generator

**Stato:** versione 0.1.0 rilasciata (tag `uptg-v0.1.0`)
**Motore:** Godot 4.7.2 (GDScript)

Un modulo di generazione del terreno per Godot, riutilizzabile e indipendente dal gioco. La versione 0.1 è un generatore procedurale di isole deterministico e configurabile: costa irregolare, colline, pianure, regioni montuose, generazione della mesh e collisione statica.

## Cartelle

| Cartella | Contenuto |
|---|---|
| `addons/uptg/` | Il generatore: `core/`, `builders/`, `nodes/`, `materials/`, `presets/` |
| `demo/` | Scena demo autonoma |
| `tests/` | Suite di test headless, test di collisione e benchmark |
| `tools/` | Strumento di bake: scrive un mondo generato su file per un gioco |
| `presets/` | Riservata e vuota in v0.1: il preset predefinito è `addons/uptg/presets/uptg_island_default.tres` |
| `documentation/` | Architettura, procedure di test, risultati delle verifiche e screenshot |

## Documentazione

- [Guida dell'addon](addons/uptg/README.it.md): installazione, avvio rapido, configurazione
- [Specifica di architettura 0.2](documentation/UPTG_ARCHITECTURE_0.2.it.md)
- [Bozza di architettura 0.1](documentation/UPTG_ARCHITECTURE.md), in inglese, conservata come riferimento storico
- [Test](documentation/TESTING.it.md): suite di test, benchmark, verifiche manuali, screenshot
- [Verifica della Milestone 0](documentation/M0_VERIFICATION.it.md)
- [Changelog](CHANGELOG.it.md)

## Utilizzo

UPTG è uno strumento di sviluppo privato e non entra in un gioco (ADR-0009). Per vederlo in funzione, apri questa cartella come progetto ed esegui `res://demo/uptg_demo.tscn`.

Per dare un mondo a un gioco, esportalo da questa cartella (il primo comando serve una volta, dopo un nuovo clone o un nuovo script):

```
godot --headless --editor --quit
godot --headless --path . -s res://tools/uptg_bake.gd -- --out=C:/percorso/del/gioco/mondo/isola.scn --seed=12345
```

Il file `.scn` contiene mesh, materiale, collisione e altezze, senza script e senza riferimenti a UPTG. Nel gioco si istanzia come qualsiasi altra scena. Dopo un aggiornamento di Godot va esportato di nuovo.
