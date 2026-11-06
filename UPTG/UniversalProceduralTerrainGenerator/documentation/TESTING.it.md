[English](TESTING.md) | **Italiano**

# Test di UPTG

I test di UPTG sono semplici file GDScript eseguiti da Godot 4.7.2 in modalità headless. Non servono framework né plugin di test.

## Eseguire i test

Dalla cartella del modulo (`UPTG/UniversalProceduralTerrainGenerator/`):

```
godot --headless --editor --quit
godot --headless --path . -s res://tests/run_tests.gd
```

- Il primo comando importa il progetto e registra gli script con `class_name`. Serve solo dopo aver aggiunto o rinominato script, oppure su un clone nuovo (la cache `.godot/` non è in Git).
- `godot` è l'eseguibile di Godot 4.7.2. Su Windows va usata la versione `_console.exe`, così l'output e il codice d'uscita arrivano al terminale.
- Il codice d'uscita è `0` se tutti i controlli passano e `1` se almeno un controllo fallisce o uno script non compila.

## Output

Ogni controllo stampa una riga:

- `PASS <nome> | <dettaglio>`: controllo superato.
- `FAIL <nome> | <dettaglio>`: controllo fallito; il dettaglio mostra il valore trovato.
- `INFO <nome> | <dettaglio>`: una misura, non un controllo (per esempio i tempi).

L'ultima riga è `SUMMARY checks=<n> failures=<n>`.

Alcuni test passano di proposito configurazioni non valide. Il generatore le segnala con `push_error`, quindi anche un'esecuzione riuscita stampa due righe `ERROR: UPTG: ...` (un `cell_size` non valido e una configurazione grande senza `allow_large_terrain`). Sono previste.

## Suite di test

| File | Cosa verifica | Criteri |
|---|---|---|
| `tests/test_seed.gd` | Valori di riferimento di `UPTGSeed.derive()`, intervallo, sub-seed distinti | A7 |
| `tests/test_validation.gd` | `UPTGConfig.validate()` rifiuta ogni tipo di valore non valido; livelli di costo OK / LARGE / REJECTED e rifiuto senza generare | A5, A5b |
| `tests/test_determinism.gd` | Stesso seed, stesse altezze e stessi checksum; bordo al fondale; interrogazioni dell'altezza sulla diagonale verificata; indipendenza dalla risoluzione; salvataggio e ricaricamento del preset `.tres`; tempi | A7, A11, A12 |

## Aggiungere una suite

1. Creare `tests/test_<argomento>.gd` che estende `RefCounted`, con `func run(t: Object) -> void`.
2. Dentro `run`, chiamare `t.check(nome, condizione, dettaglio)` per ogni controllo e `t.info(nome, dettaglio)` per le misure.
3. Aggiungere il percorso a `SUITES` in `tests/run_tests.gd`.
4. Committare lo script insieme al suo file `.gd.uid`, che Godot crea durante l'importazione.
