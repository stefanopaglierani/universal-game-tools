[English](M0_VERIFICATION.md) | **Italiano**

# UPTG — Risultati della verifica della Milestone 0

**Data:** 2026-11-06
**Branch:** `uptg/milestone-0-setup`
**Motore:** Godot `4.7.2.stable.official.ed1daf0bf` (Windows, build console)
**GPU usata per i test di rendering:** Intel(R) UHD Graphics 620, Vulkan 1.3.215, Forward+

Ogni risultato riportato qui viene da un test realmente eseguito. Gli script temporanei (`tests/m0/`) e l'`override.cfg` temporaneo sono stati eliminati dopo l'esecuzione, come previsto; questo file documenta cosa facevano e cosa hanno restituito.

## Come sono stati eseguiti i test

| Esecuzione | Comando (dalla cartella del modulo) |
|---|---|
| Importazione del progetto | `godot --headless --editor --quit --path .` |
| Editor con interfaccia | `godot --editor --quit --path .` |
| Test di fisica e API | `godot --headless --path . -s res://tests/m0/m0_tests.gd` |
| Altro backend fisico | come sopra, con un `override.cfg` temporaneo che imposta `physics/3d/physics_engine` a `GodotPhysics3D` e poi a `Jolt Physics` |
| Test di rendering | `godot --path . -s res://tests/m0/m0_render.gd` (apre una finestra per circa un secondo) |
| Verifica del codice d'uscita | `godot --headless --path . -s <script>` con `quit(3)` e con uno script contenente un errore di parsing |

## Risultati

| # | Verifica | Risultato | Esito |
|---|---|---|---|
| T1 | Apertura del progetto in 4.7.2 | Importazione headless ed editor con interfaccia terminano con codice 0, senza errori né warning. L'editor non riscrive `project.godot` | SUPERATO |
| T2 | Backend fisico effettivamente usato | Impostazione `physics/3d/physics_engine` = `DEFAULT`. I valori dei raggi coincidono bit per bit con un'esecuzione forzata a `GodotPhysics3D` e differiscono da una forzata a `Jolt Physics`: per questo progetto il backend predefinito è **Godot Physics**. `PhysicsServer3D.get_class()` restituisce `PhysicsServer3D` con entrambi i backend e non permette di distinguerli | Registrato |
| T3 | Disponibilità delle API | `FastNoiseLite` (Simplex Smooth, FBM, ottave, lacunarity, gain, frequenza), output ripetibile, il seed cambia l'output; `ArrayMesh.add_surface_from_arrays` con vertici, normali, UV, colori e indici; `StandardMaterial3D.vertex_color_use_as_albedo`; `Resource` con `class_name`, `@export_group`, `@export_range`, enum esportato e `Array[Resource]` esportato, salvato in `.tres` e ricaricato con valori identici; proprietà di `HeightMapShape3D`; `ConcavePolygonShape3D.set_faces` e `backface_collision`; `PhysicsRayQueryParameters3D.create`; `var_to_bytes`; `PackedFloat32Array.to_byte_array`; `Time.get_ticks_usec` | SUPERATO |
| T3 | Intervallo del seed di `FastNoiseLite` | `2147483647` viene conservato. `3000000000` viene riletto come `-1294967296` (overflow a 32 bit): il limite a 31 bit di `generation_seed` è necessario | Registrato |
| T3 | Intervallo dell'output FBM | 4 ottave, 20 000 campioni: intervallo osservato [-0.7513, 0.6827] | Registrato |
| T3 | Derivazione dei seed (architettura 7.2) | I risultati in GDScript coincidono con 4 valori calcolati in modo indipendente: `derive(0,1)=33350994`, `derive(12345,1)=1868776673`, `derive(12345,2)=1162198605`, `derive(2147483647,3)=2090469116` | SUPERATO |
| T4 | Ordine di `map_data` e centratura | Mappa planare 4×4 `h = ix + 10·iz`, 25 raggi: errore massimo 0.085 mm per "righe `iz*w+ix`, centrata sull'origine"; 23.4 m per l'ordine trasposto; 16.5 m per l'origine nell'angolo. Nessuna collisione fuori dalla mappa | SUPERATO |
| T5 | Diagonale dei triangoli | Mappa 4×4 a scacchiera: tutte le 9 celle sono divise lungo la diagonale dal vertice `(ix+1, iz)` al vertice `(ix, iz+1)`; 36/36 punti fuori centro coincidono con essa, 0/36 con l'altra | SUPERATO |
| T6 | Scala uniforme | T4 e T5 ripetuti con `cell_size = 4` (altezze divise per 4, `CollisionShape3D` scalato di 4): risultati identici | SUPERATO |
| T7a | Winding, fisica | `ConcavePolygonShape3D`, `backface_collision = false`: un triangolo orario visto dall'alto viene colpito dall'alto e non dal basso; quello antiorario solo dal basso | Registrato |
| T7b | Winding, rendering | Con il `CULL_BACK` predefinito il triangolo orario sullo schermo viene disegnato, quello antiorario viene scartato; con il culling disattivato il triangolo è visibile (controllo di sanità) | SUPERATO |
| T8 | Collisione e interpolazione sui triangoli | 64×64 celle, `cell_size = 4`, altezze da noise, 2000 raggi. `HEIGHTMAP`: errore massimo 0.187 mm con la diagonale di T5, 316 mm con l'altra. `TRIMESH` costruita con ciascuna diagonale: ≤ 0.202 mm rispetto alla propria diagonale. Nessun raggio mancato | SUPERATO |
| T9 | Esecuzione headless dei test | Gli script `-s` che estendono `SceneTree` funzionano in headless, la fisica funziona in headless, `quit(3)` dà codice d'uscita 3, un errore di parsing dà codice d'uscita 1 | SUPERATO |
| T10 | Indici a 32 bit | 300×300 vertici (90 000), 536 406 indici: tutti gli indici riletti, indice massimo 89 999, AABB corretto; headless e Forward+ | SUPERATO |
| T11 | Altro backend (Jolt) | T4–T8 ripetuti con `Jolt Physics`: stesso ordine, centratura, diagonale, winding e scala. Errori: 0.134 mm (T4), 0.153 mm (`HEIGHTMAP`, T8), ≤ 0.169 mm (`TRIMESH`, T8). `GodotPhysics3D` forzato esplicitamente dà gli stessi valori di `DEFAULT` | SUPERATO |
| T12 | Heightmap non quadrate (aggiunto durante la revisione finale) | 7×4, 4×9 e 65×33 vertici, `cell_size = 4`, 1500 raggi casuali ciascuna, confrontati con la diagonale di T5: errore massimo 0.166 mm (Godot Physics) e 0.221 mm (Jolt), nessun raggio mancato | SUPERATO |

## Altri risultati

- Godot 4.7.2 crea un file `.gd.uid` accanto a ogni script. Questi file vanno committati insieme ai rispettivi script.
- In headless il rendering è fittizio: i test che leggono pixel richiedono una finestra.
- La cache `.godot/` viene creata alla prima apertura ed è già esclusa da `.gitignore`. Dopo l'eliminazione degli script temporanei il progetto è stato reimportato e la cache delle classi globali non contiene più le classi temporanee.

## Non verificato

- Quale backend il Project Manager di Godot scrive in un progetto *nuovo*: il `project.godot` di UPTG è stato scritto a mano e quindi usa `DEFAULT`. Non influisce su UPTG, perché i due backend si comportano allo stesso modo in tutti i test sopra.
- Determinismo tra piattaforme diverse (disponibile una sola macchina).
