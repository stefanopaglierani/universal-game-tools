[English](CONVENTIONS.md) | **Italiano**

# Convenzioni di codice

Si segue la [guida di stile ufficiale di GDScript](https://docs.godotengine.org/it/stable/tutorials/scripting/gdscript/gdscript_styleguide.html), con queste regole di progetto.

## Nomi

| Elemento | Convenzione | Esempio |
|---|---|---|
| File | `snake_case`, con il prefisso del modulo | `uptg_generator.gd` |
| Classi (`class_name`) | `PascalCase`, con il prefisso del modulo | `UPTGGenerator` |
| Funzioni, variabili | `snake_case` | `build_height_field()` |
| Costanti | `UPPER_SNAKE_CASE` | `MIN_RESOLUTION` |
| Scene | `snake_case.tscn` | `uptg_demo.tscn` |
| Preset | `snake_case.tres` | `island_default.tres` |

Il codice (nomi, commenti) è scritto in inglese.

## GDScript

- Usare la tipizzazione statica (`var size: int = 64`, `func f() -> void`).
- Esporre la configurazione tramite classi `Resource` personalizzate con `@export` e intervalli sensati, non con valori scritti nel codice.
- Non generare mai a ogni frame; generare su richiesta esplicita o all'inizializzazione.
- Validare gli input e segnalare gli errori con `push_error()` / `push_warning()`.
- Derivare tutta la casualità da un seed configurato.

## Documentazione

- Ogni modulo ha un `README.md`, un documento di architettura, `TESTING.md` e `CHANGELOG.md`, ciascuno con la sua versione `.it.md`.
- Le classi pubbliche e le proprietà esportate hanno commenti di documentazione (`##`).
