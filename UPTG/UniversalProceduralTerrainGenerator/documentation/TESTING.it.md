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

Alcuni test passano di proposito configurazioni non valide. Il generatore e il nodo le segnalano con `push_error`, quindi anche un'esecuzione riuscita stampa quattro righe `ERROR: UPTG: ...`: un `cell_size` non valido e una configurazione grande senza `allow_large_terrain`, una volta da `test_validation.gd` e una volta da `test_terrain_node.gd`. Sono previste.

## Suite di test

| File | Cosa verifica | Criteri |
|---|---|---|
| `tests/test_seed.gd` | Valori di riferimento di `UPTGSeed.derive()`, intervallo, sub-seed distinti | A7 |
| `tests/test_validation.gd` | `UPTGConfig.validate()` rifiuta ogni tipo di valore non valido; livelli di costo OK / LARGE / REJECTED e rifiuto senza generare | A5, A5b |
| `tests/test_determinism.gd` | Stesso seed, stesse altezze e stessi checksum; bordo al fondale; interrogazioni dell'altezza sulla diagonale verificata; indipendenza dalla risoluzione; salvataggio e ricaricamento del preset `.tres`; tempi | A7, A11, A12 |
| `tests/test_mesh.gd` | `UPTGMeshBuilder`: numero di vertici e triangoli, limiti degli indici, nessun NaN, normali unitarie, winding orario visto da +Y, diagonale comune, UV, ingombro, vertex colors | A6 |
| `tests/test_terrain_node.gd` | `UPTGTerrain`: figlio `UPTGMesh` senza owner, materiale predefinito, segnali, statistiche, quota in spazio mondo, una generazione fallita conserva il terreno precedente, 20 rigenerazioni senza crescita di nodi, oggetti, risorse o memoria statica | A5b, A10 |

## Verifica manuale della demo

Aprire il progetto in Godot 4.7.2 ed eseguire `res://demo/uptg_demo.tscn` (F6 con la scena aperta). Verificare che:

1. la demo parta da sola e mostri un'isola circondata dal mare (A2, A3);
2. la costa sia irregolare, con colline e un rilievo attorno alla regione montuosa (A3, A4);
3. **Regenerate** con un altro seed, oppure **Random seed**, cambi l'isola, e il pannello mostri seed, griglia, vertici, triangoli, tempi e checksum;
4. **Wireframe** mostri la griglia dei triangoli;
5. trascinando con il mouse la camera ruoti attorno all'isola e la rotellina faccia zoom.

Piano d'acqua, cielo, luce e camera appartengono solo alla demo, non all'addon.

## Aggiungere una suite

1. Creare `tests/test_<argomento>.gd` che estende `RefCounted`, con `func run(t: Object) -> void`.
2. Dentro `run`, chiamare `t.check(nome, condizione, dettaglio)` per ogni controllo e `t.info(nome, dettaglio)` per le misure.
3. Aggiungere il percorso a `SUITES` in `tests/run_tests.gd`.
4. Committare lo script insieme al suo file `.gd.uid`, che Godot crea durante l'importazione.
