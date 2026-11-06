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
| `tests/test_terrain_node.gd` | `UPTGTerrain`: figli `UPTGMesh` e `UPTGBody/UPTGShape` senza owner, materiale predefinito, modalità e layer della collisione, segnali, statistiche, quota in spazio mondo, una generazione fallita conserva il terreno precedente, 20 rigenerazioni senza crescita di nodi, oggetti, risorse o memoria statica | A5b, A10 |

## Test di collisione

La collisione richiede la fisica in esecuzione, quindi è una scena e non una suite:

```
godot --headless --path . --fixed-fps 60 res://tests/collision/collision_test.tscn
```

`--fixed-fps 60` esegue un passo di fisica per frame, così il test non aspetta il tempo reale. Formato dell'output e codice d'uscita sono gli stessi di `run_tests.gd`. Verifica:

- **A8:** 2000 raggi verticali per caso confrontati con `UPTGTerrainData.get_height_at()`, tolleranza 1 cm, in `HEIGHTMAP` e `TRIMESH`, su una griglia quadrata (128 × 128, cella 4 m) e una non quadrata (96 × 48, cella 2.5 m), con il nodo del terreno spostato dall'origine; nessuna collisione fuori dalla griglia; nessuna collisione con `NONE`.
- **A9:** 25 sfere lasciate cadere su una griglia di punti si fermano sulla superficie (`HEIGHTMAP` e `TRIMESH`); una capsula `CharacterBody3D` sale per 15 s sul fianco della montagna senza affondare.

**Altro backend fisico.** Il progetto usa il backend predefinito (Godot Physics). Per ripetere il test con Jolt, creare nella cartella del modulo un `override.cfg` temporaneo con:

```
[physics]

3d/physics_engine="Jolt Physics"
```

eseguire di nuovo la scena e poi eliminare `override.cfg` (non va mai committato). La prima riga dell'output mostra il backend impostato.

**Risultati del 2026-11-06** (Godot 4.7.2, Windows, 15 controlli, 0 falliti su entrambi i backend):

| Verifica | Godot Physics (predefinito) | Jolt |
|---|---|---|
| A8 errore massimo dei raggi, HEIGHTMAP 128 × 128 / 96 × 48 | 0.178 / 0.173 mm | 0.190 / 0.249 mm |
| A8 errore massimo dei raggi, TRIMESH 128 × 128 / 96 × 48 | 0.178 / 0.219 mm | 0.300 / 0.237 mm |
| A9 sfere: cadute attraverso, distanza massima, velocità finale massima | 0, 28.5 mm, 0.061 m/s | 0, 38.3 mm, 0.000 m/s |
| A9 capsula: frame a terra, distanza, pendenza massima | 894/900, 64.4 m, 35.4° | 894/900, 64.4 m, 35.4° |

La distanza delle sfere è misurata dalla superficie sotto il centro lungo la normale, quindi sui terreni curvi sovrastima quella reale; resta comunque ben sotto il limite di 5 cm.

## Verifica manuale della demo

Aprire il progetto in Godot 4.7.2 ed eseguire `res://demo/uptg_demo.tscn` (F6 con la scena aperta). Verificare che:

1. la demo parta da sola e mostri un'isola circondata dal mare (A2, A3);
2. la costa sia irregolare, con colline e un rilievo attorno alla regione montuosa (A3, A4);
3. **Regenerate** con un altro seed, oppure **Random seed**, cambi l'isola, e il pannello mostri seed, griglia, vertici, triangoli, tempi e checksum;
4. **Wireframe** mostri la griglia dei triangoli;
5. **Drop balls** faccia cadere 20 sfere che si fermano sul terreno, anche sotto l'acqua (collisione, A9);
6. trascinando con il mouse la camera ruoti attorno all'isola e la rotellina faccia zoom.

Piano d'acqua, cielo, luce e camera appartengono solo alla demo, non all'addon.

## Aggiungere una suite

1. Creare `tests/test_<argomento>.gd` che estende `RefCounted`, con `func run(t: Object) -> void`.
2. Dentro `run`, chiamare `t.check(nome, condizione, dettaglio)` per ogni controllo e `t.info(nome, dettaglio)` per le misure.
3. Aggiungere il percorso a `SUITES` in `tests/run_tests.gd`.
4. Committare lo script insieme al suo file `.gd.uid`, che Godot crea durante l'importazione.
