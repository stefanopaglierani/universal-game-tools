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

Alcuni test passano di proposito configurazioni non valide. Il generatore e il nodo le segnalano con `push_error`, quindi anche un'esecuzione riuscita stampa quattro righe `ERROR: UPTG: ...`: un `cell_size` non valido e una configurazione grande senza `allow_large_terrain`, una volta da `test_validation.gd` e una volta da `test_terrain_node.gd`. Sono previste, insieme a una riga `WARNING: UPTG: generate() called while a generation is running; ignored` prodotta dalla verifica della non rientranza in `test_terrain_node.gd`.

## Suite di test

| File | Cosa verifica | Criteri |
|---|---|---|
| `tests/test_seed.gd` | Valori di riferimento di `UPTGSeed.derive()`, intervallo, sub-seed distinti | A7 |
| `tests/test_validation.gd` | `UPTGConfig.validate()` rifiuta ogni tipo di valore non valido; livelli di costo OK / LARGE / REJECTED e rifiuto senza generare; il preset isola `uptg_island_default.tres` si carica, è valido e corrisponde ai valori predefiniti | A5, A5b |
| `tests/test_determinism.gd` | Stesso seed, stesse altezze e stessi checksum; bordo al fondale; interrogazioni dell'altezza sulla diagonale verificata; indipendenza dalla risoluzione; salvataggio e ricaricamento del preset `.tres`; tempi | A7, A11, A12 |
| `tests/test_mesh.gd` | `UPTGMeshBuilder`: numero di vertici e triangoli, limiti degli indici, nessun NaN, normali unitarie, winding orario visto da +Y, diagonale comune, UV, ingombro, vertex colors | A6 |
| `tests/test_terrain_node.gd` | `UPTGTerrain`: figli `UPTGMesh` e `UPTGBody/UPTGShape` senza owner, materiale predefinito, modalità e layer della collisione, segnali, statistiche, quota in spazio mondo, una generazione fallita conserva il terreno precedente, 20 rigenerazioni senza crescita di nodi, oggetti, risorse o memoria statica, una chiamata a `generate()` da `generation_finished` viene ignorata | A5b, A10 |

## Test di collisione

La collisione richiede la fisica in esecuzione, quindi è una scena e non una suite:

```
godot --headless --path . --fixed-fps 60 res://tests/collision/collision_test.tscn
```

`--fixed-fps 60` esegue un passo di fisica per frame, così il test non aspetta il tempo reale. Formato dell'output e codice d'uscita sono gli stessi di `run_tests.gd`. Verifica:

- **A8:** 2000 raggi verticali per caso confrontati con `UPTGTerrainData.get_height_at()`, tolleranza 1 cm, in `HEIGHTMAP` e `TRIMESH`, su una griglia quadrata (128 × 128, cella 4 m) e una non quadrata (96 × 48, cella 2.5 m), con il nodo del terreno spostato dall'origine; nessuna collisione fuori dalla griglia; nessuna collisione con `NONE`.
- **A9:** 25 sfere lasciate cadere su una griglia di punti si fermano sulla superficie (`HEIGHTMAP` e `TRIMESH`); una capsula `CharacterBody3D` sale per 15 s sul fianco della montagna senza affondare. A9 usa un proprio terreno moderato (base 6 m, colline 12 m, montagna 40 m), fissato in `collision_test.gd`: il criterio A9 riguarda le pendenze moderate e il test non deve cambiare quando si tara il preset isola. A8 usa il preset predefinito.

**Altro backend fisico.** Il progetto usa il backend predefinito (Godot Physics). Per ripetere il test con Jolt, creare nella cartella del modulo un `override.cfg` temporaneo con:

```
[physics]

3d/physics_engine="Jolt Physics"
```

eseguire di nuovo la scena e poi eliminare `override.cfg` (non va mai committato). La prima riga dell'output mostra il backend impostato.

**Risultati del 2026-11-06, dopo la taratura della Milestone D** (Godot 4.7.2, Windows, 15 controlli, 0 falliti su entrambi i backend):

| Verifica | Godot Physics (predefinito) | Jolt |
|---|---|---|
| A8 errore massimo dei raggi, HEIGHTMAP 128 × 128 / 96 × 48 | 0.187 / 0.177 mm | 0.171 / 0.261 mm |
| A8 errore massimo dei raggi, TRIMESH 128 × 128 / 96 × 48 | 0.187 / 0.227 mm | 0.247 / 0.305 mm |
| A9 sfere: cadute attraverso, distanza massima, velocità finale massima | 0, 28.5 mm, 0.061 m/s | 0, 38.3 mm, 0.000 m/s |
| A9 capsula: frame a terra, distanza, pendenza massima | 894/900, 64.4 m, 35.4° | 894/900, 64.4 m, 35.4° |

La distanza delle sfere è misurata dalla superficie sotto il centro lungo la normale, quindi sui terreni curvi sovrastima quella reale; resta comunque ben sotto il limite di 5 cm.

## Benchmark (sezione 13 dell'architettura)

`tests/benchmark.gd` misura tempi di generazione e memoria. Non è un test con esito e non fa parte di `run_tests.gd`. Va eseguito con una finestra, così si possono misurare la memoria GPU e il frame time della demo:

```
godot --path . --resolution 1280x720 -s res://tests/benchmark.gd
```

Funziona anche in headless; in quel caso i valori GPU e il frame time sono riportati come `n/a`. I tempi dipendono dalla macchina; i valori qui sotto sono solo un riferimento.

**Risultati del 2026-11-06** (Godot 4.7.2, Windows, portatile con Intel UHD Graphics 620, Vulkan Forward+, preset isola predefinito, `cell_size` 4 m):

| Celle | Vertici / triangoli | Stima HEIGHTMAP / TRIMESH | Height field | Mesh | Buffer GPU della mesh | HEIGHTMAP: costruzione, memoria | TRIMESH: costruzione, memoria |
|---|---|---|---|---|---|---|---|
| 128 × 128 | 16 641 / 32 768 | 2.5 / 7.5 MB | 33 ms | 80 ms | 2.5 MB | 4.5 ms, 0.8 MB | 93 ms, 5.3 MB |
| 256 × 256 | 66 049 / 131 072 | 10.1 / 30.1 MB | 166 ms | 348 ms | 3.5 MB | 11 ms, 0.3 MB | 401 ms, 21.0 MB |
| 512 × 512 | 263 169 / 524 288 | 40.1 / 120.1 MB | 524 ms | 1303 ms | 14.0 MB | 46 ms, 1.0 MB | 1478 ms, 84.0 MB |

Frame time della demo, preset predefinito 256 × 256, 300 frame, vsync disattivato: **25.5 ms (39 fps)**. Aggiungere una shape al mondo ed eseguire un frame di fisica richiede meno di 20 ms in tutti i casi.

Come si misura la memoria: la memoria CPU è la crescita di `Performance.MEMORY_STATIC` mentre l'oggetto esiste, quella GPU è la crescita di `RENDERING_INFO_BUFFER_MEM_USED`. Dopo la prima dimensione il motore riusa i blocchi liberati, quindi i valori CPU piccoli (da 0.0 a 0.5 MB) significano "riusata", non "gratuita"; i valori affidabili sono quelli della TRIMESH e di 512 × 512. La misura TRIMESH a 512 × 512 usa `allow_large_terrain = true`, perché supera la soglia `OK` della TRIMESH.

**Calibrazione della stima dei costi (sezione 5.4 dell'architettura).** Le costanti di `UPTGConfig` sono state fissate da queste misure:

- `BYTES_PER_VERTEX` resta **112**: height field e maschera (8), array della mesh lato CPU (48), copia GPU (48), altezze della collisione (4). I buffer GPU misurati sono circa 54 byte per vertice, in linea con la stima.
- `BYTES_PER_CELL` passa da 24 a **48**: gli indici esistono sia lato CPU sia lato GPU.
- `BYTES_PER_CELL_TRIMESH` passa da 72 a **320**: la `ConcavePolygonShape3D` misurata occupa circa 84 MB a 512 × 512 celle (320 byte per cella), comprese le strutture interne del motore fisico.
- Le soglie (`MAX_CELLS_*`, `MAX_BYTES_*`) restano invariate. Con i nuovi coefficienti il caso più grande ammesso, 1024 × 1024 celle in TRIMESH, è stimato in circa 480 MB, sotto il limite di 512 MB, e 512 × 512 in HEIGHTMAP in circa 40 MB, ampiamente dentro `OK`.

## Verifica manuale della demo

Aprire il progetto in Godot 4.7.2 ed eseguire `res://demo/uptg_demo.tscn` (F6 con la scena aperta). Verificare che:

1. la demo parta da sola e mostri un'isola circondata dal mare (A2, A3);
2. la costa sia irregolare, con colline e un rilievo attorno alla regione montuosa (A3, A4);
3. **Regenerate** con un altro seed, oppure **Random seed**, cambi l'isola; il pannello mostri la stima dei costi prima di generare, poi seed, griglia, vertici, triangoli, tempi e checksum;
4. **Wireframe** mostri la griglia dei triangoli;
5. **Drop balls** faccia cadere 20 sfere che si fermano sul terreno, anche sotto l'acqua (collisione, A9);
6. trascinando con il mouse la camera ruoti attorno all'isola e la rotellina faccia zoom.

Piano d'acqua, cielo, luce e camera appartengono solo alla demo, non all'addon.

## Aggiungere una suite

1. Creare `tests/test_<argomento>.gd` che estende `RefCounted`, con `func run(t: Object) -> void`.
2. Dentro `run`, chiamare `t.check(nome, condizione, dettaglio)` per ogni controllo e `t.info(nome, dettaglio)` per le misure.
3. Aggiungere il percorso a `SUITES` in `tests/run_tests.gd`.
4. Committare lo script insieme al suo file `.gd.uid`, che Godot crea durante l'importazione.
