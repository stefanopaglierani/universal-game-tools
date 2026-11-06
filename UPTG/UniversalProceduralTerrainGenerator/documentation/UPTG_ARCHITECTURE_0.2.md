# UPTG — Universal Procedural Terrain Generator
## Specifica di architettura — Versione 0.2

**Stato:** architettura approvata (0.2-r2). Milestone 0 eseguita il 2026-11-06: i risultati sperimentali sono riportati con l'etichetta [VERIFICATO M0]. Nessun codice del generatore è stato scritto.
**Revisione:** 0.2-r3 (vedi Appendice B)
**Progetto:** Universal Game Tools
**Engine di riferimento:** Godot 4.7.2
**Linguaggio:** GDScript (static typing)
**Owner:** Stefano
**Sostituisce:** `UPTG_ARCHITECTURE.md` (Draft 0.1), che resta invariato come riferimento storico.
**Data:** 2026-11-06

---

## 0. Come leggere questo documento

Il documento usa tre etichette, riepilogate nella sezione 16:

- **[APPROVATO]** — decisione architetturale approvata da Stefano il 2026-11-06. Si cambia solo con una nuova approvazione.
- **[DA VERIFICARE]** — ipotesi tecnica da confermare sperimentalmente in Godot 4.7.2, quasi sempre in Milestone 0. Le ipotesi previste per la Milestone 0 sono state verificate (vedi [VERIFICATO M0]); restano [DA VERIFICARE] solo le voci elencate in 16.2. Se un test smentisce l'ipotesi, il documento viene aggiornato e la modifica sottoposta a Stefano.
- **[RINVIATO]** — decisione consapevolmente spostata a una milestone successiva, con l'indicazione di quale.
- **[VERIFICATO M0]** — ipotesi confermata da un test realmente eseguito in Godot 4.7.2 durante la Milestone 0. Comandi, output e valori misurati sono in `documentation/M0_VERIFICATION.md`.

La documentazione ufficiale è quella contenuta nel repository `universal-game-tools`. Le copie nella cartella esterna `C:\Progetti Software\Universal Gmaes Tool` sono solo riferimenti locali (D8, [APPROVATO]).

---

## 1. Scopo e perimetro

UPTG è un modulo riutilizzabile per generare terreni procedurali 3D in Godot. Il primo obiettivo operativo e il primo preset sono un'isola deterministica e configurabile per un mondo di gioco compatto.

### 1.1 Principi strategici [APPROVATO]

- Il core è **game-agnostic**: non contiene logica di racing, survival, RPG, quest, veicoli o di qualsiasi gioco specifico.
- L'isola è il **primo preset**, non l'unico scopo del core. La pipeline di generazione è progettata in fasi separate (maschera di forma, rilievo, rilievi localizzati, combinazione) così che in futuro possa supportare terreni continentali, pianure, colline, catene montuose, ambienti survival e fantasy senza riscrivere il core.
- Queste estensioni **non vengono implementate in v0.1**; sono solo considerate nella progettazione (sezione 14).
- I futuri moduli (strade, vegetazione, ambienti, world generation) usano esclusivamente `UPTGTerrainData` e non dipendono dai dettagli interni del generatore.

### 1.2 Funzionalità v0.1

- Generazione di un height field deterministico da un `generation_seed`.
- Maschera dell'isola con costa irregolare e falloff morbido verso il mare.
- Colline tramite noise frattale, una o più regioni montuose configurabili.
- Mesh indicizzata con normali, UV e vertex colors.
- Collisione statica: `HeightMapShape3D` (predefinita), trimesh (alternativa) o nessuna.
- Nodo riutilizzabile `UPTGTerrain` con rigenerazione senza duplicare nodi.
- Configurazione tramite Resource salvabile come preset `.tres`.
- Scena demo autonoma e test automatici.
- Documentazione: README, TESTING, CHANGELOG.

### 1.3 Fuori perimetro per v0.1

- Strade, sentieri, ponti, percorsi.
- Edifici, vegetazione, oggetti di scena, insediamenti.
- Biomi, shader custom, blending avanzato dei materiali.
- Terreno deformabile o distruttibile.
- Terreno infinito, streaming, chunking, LOD.
- Generazione in thread separati.
- Script `@tool`, anteprima nell'editor, editor dock, `EditorPlugin`.
- Baking del terreno su file.
- Erosione, fiumi, laghi.
- Modalità di forma diverse dall'isola (continentale, ecc.).
- Gameplay, navigazione AI, logica veicoli.
- Directory vuote per moduli futuri (UPRG, UPWG).

---

## 2. Principi di progettazione

1. **Riutilizzabile:** il core non dipende da nessun gioco.
2. **Deterministico:** stessa configurazione + stesso seed + stessa build sulla stessa piattaforma = stesso terreno.
3. **Modulare:** configurazione, generazione, mesh, collisione e nodo di scena sono separati.
4. **Puro dove possibile:** il generatore dell'height field non accede alla scena.
5. **Ispezionabile:** dati e risultati sono leggibili e misurabili.
6. **Incrementale:** milestone piccole, ciascuna verificata prima della successiva.
7. **Misurato:** nessuna affermazione sulle prestazioni senza misure.
8. **Verificato:** nessuna API dichiarata compatibile con 4.7.2 senza un test.
9. **Portabile:** tutto ciò che serve a runtime sta in `addons/uptg/`.
10. **Sicuro:** nessuna modifica a file esistenti senza approvazione.

---

## 3. Struttura del repository [APPROVATO]

Il repository esiste già in `C:\Progetti Software\Universal Gmaes Tool\universal-game-tools`, collegato a `github.com/stefanopaglierani/universal-game-tools`, branch `main`. La struttura seguente indica in che modo UPTG si inserisce in ciò che esiste; i file marcati "esistente" non vengono modificati da questo documento.

```text
universal-game-tools/                         radice del repository Git (esistente)
├── README.md                                 esistente
├── CHANGELOG.md                              esistente (livello repository)
├── LICENSE                                   esistente, "All rights reserved" (D2)
├── Documentation/                            esistente: architecture/ (con ADR), development/
├── UPRG/, UPWG/                              esistenti, solo README segnaposto; nessun contenuto aggiunto
└── UPTG/
    └── UniversalProceduralTerrainGenerator/  progetto Godot autonomo (project.godot)
        ├── project.godot
        ├── addons/
        │   └── uptg/                         addon portabile: l'unica cartella da copiare
        │       ├── core/
        │       │   ├── uptg_config.gd
        │       │   ├── uptg_mountain_region.gd
        │       │   ├── uptg_terrain_data.gd
        │       │   ├── uptg_seed.gd
        │       │   └── uptg_heightfield_generator.gd
        │       ├── builders/
        │       │   ├── uptg_mesh_builder.gd
        │       │   └── uptg_collision_builder.gd
        │       ├── nodes/
        │       │   └── uptg_terrain.gd
        │       ├── materials/
        │       │   └── uptg_terrain_default.tres
        │       ├── presets/
        │       │   └── uptg_island_default.tres
        │       ├── LICENSE                   copia di "All rights reserved"
        │       └── README.md
        ├── demo/
        │   ├── uptg_demo.tscn
        │   └── uptg_demo_controller.gd
        ├── tests/
        │   ├── run_tests.gd
        │   ├── test_validation.gd
        │   ├── test_seed.gd
        │   ├── test_determinism.gd
        │   ├── test_mesh.gd
        │   └── collision/
        │       ├── collision_test.tscn
        │       └── collision_test.gd
        ├── documentation/
        │   ├── UPTG_ARCHITECTURE.md          Draft 0.1, invariato
        │   ├── UPTG_ARCHITECTURE_0.2.md      questo documento
        │   └── TESTING.md
        └── CHANGELOG.md
```

Regole:

- Il codice runtime in `addons/uptg/` usa solo percorsi `res://addons/uptg/...` e non fa riferimento a `demo/`, `tests/` o file esterni all'addon. La verifica si fa con una ricerca testuale (criterio di accettazione A13).
- Nessun `plugin.cfg` né `EditorPlugin` in v0.1: le classi con `class_name` sono disponibili senza attivare un plugin.
- Tutti i `class_name` hanno prefisso `UPTG` per evitare conflitti nei progetti che importano l'addon.
- Nessuna nuova directory per moduli futuri. Le cartelle `UPRG/` e `UPWG/` esistono già con un README segnaposto; non vengono toccate.
- Il repository segue `Documentation/development/CONVENTIONS.md` (static typing, `##` doc comments, `push_error()`/`push_warning()`, nomi con prefisso del modulo) e `WORKFLOW.md` (branch `uptg/<descrizione>` e `docs/<descrizione>`, commit con prefisso `UPTG:`, tag `uptg-v<versione>`).
- **D1 [APPROVATO]:** vale la struttura R12, con `core/`, `builders/`, `nodes/`, `materials/` e `presets/` dentro `addons/uptg/`. `Documentation/architecture/README.md` e il README del modulo descrivono ancora `runtime/` + `resources/` e una cartella `presets/` di modulo: **non vengono modificati ora** e restano temporaneamente disallineati. Il loro allineamento è **[RINVIATO]** a un aggiornamento documentale da approvare separatamente. Per UPTG, in caso di differenza, prevale questo documento.
- La cartella di modulo `UPTG/UniversalProceduralTerrainGenerator/presets/` (oggi vuota, con `.gitkeep`) non viene usata in v0.1; il suo destino si decide insieme all'allineamento dei documenti.
- **D2 [APPROVATO]:** la licenza resta "All rights reserved". `addons/uptg/LICENSE` sarà una copia dello stesso testo. Nessuna licenza permissiva e nessuna distribuzione pubblica sono autorizzate.

---

## 4. Componenti e responsabilità

```text
UPTGConfig ──► UPTGHeightfieldGenerator ──► UPTGTerrainData ──┬─► UPTGMeshBuilder ──────► ArrayMesh
 (Resource)        (puro, nessuna scena)       (contratto)     ├─► UPTGCollisionBuilder ─► Shape3D
                                                               └─► moduli futuri (strade, vegetazione...)

UPTGTerrain (Node3D) orchestra il flusso e possiede i nodi figli.
```

| Componente | Tipo | Responsabilità | Non fa |
|---|---|---|---|
| `UPTGConfig` | `Resource` | Tutti i parametri, validazione, salvataggio come preset | Nessun calcolo di terreno |
| `UPTGMountainRegion` | `Resource` | Parametri di una singola regione montuosa | — |
| `UPTGSeed` | classe statica | Derivazione deterministica dei sub-seed | Nessuno stato globale |
| `UPTGHeightfieldGenerator` | classe con sole funzioni statiche, senza stato | Config → `UPTGTerrainData` | Nessun accesso alla scena, a nodi o a risorse grafiche |
| `UPTGTerrainData` | `RefCounted` | Contratto dati del terreno e query | Nessuna generazione, nessuna grafica |
| `UPTGMeshBuilder` | classe statica | `UPTGTerrainData` → `ArrayMesh` | Nessuna collisione |
| `UPTGCollisionBuilder` | classe statica | `UPTGTerrainData` → `Shape3D` | Nessuna gestione di nodi |
| `UPTGTerrain` | `Node3D` | Orchestrazione, nodi figli, rigenerazione, segnali, errori | Nessuna logica di gioco |

Nota sui nomi: `UPTGGenerator` del Draft 0.1 diventa `UPTGHeightfieldGenerator` (la parte "orchestrazione" passa a `UPTGTerrain`); `UPTGTerrainBuilder` diventa `UPTGMeshBuilder`.

---

## 5. Configurazione: `UPTGConfig` [APPROVATO]

`class_name UPTGConfig extends Resource`. Proprietà esportate con `@export_group`, `@export_range` e tooltip (commenti `##`). I valori predefiniti sono provvisori e verranno tarati in Milestone D.

### 5.1 Parametri

| Gruppo | Proprietà | Tipo | Intervallo valido | Predefinito provvisorio | Note |
|---|---|---|---|---|---|
| Seed | `generation_seed` | `int` | 0 – 2 147 483 647 | 12345 | Limite a 31 bit, compatibile con `FastNoiseLite.seed` |
| Griglia | `grid_cells_x` | `int` | 2 – 1024 | 256 | Numero di celle; vertici = celle + 1 |
| Griglia | `grid_cells_z` | `int` | 2 – 1024 | 256 | Come sopra |
| Griglia | `cell_size` | `float` | 0.25 – 64.0 m | 4.0 | Celle sempre quadrate |
| Mare | `sea_level` | `float` | qualsiasi | 0.0 m | Quota del livello del mare |
| Mare | `sea_floor_depth` | `float` | 0.5 – 500 m | 20.0 m | Profondità del fondale sotto `sea_level` dove la maschera vale 0 |
| Isola | `island_radius` | `Vector2` | 0.1 – 0.85 per asse | (0.6, 0.6) | Raggi normalizzati dell'ellisse di base; vedi vincolo in 5.3 |
| Isola | `coastline_irregularity` | `float` | 0.0 – 0.5 | 0.25 | Ampiezza della perturbazione della costa |
| Isola | `coastline_noise_frequency` | `float` | 0.0001 – 0.1 | 0.004 | Frequenza in unità mondo (vedi 6.1) |
| Isola | `coastline_falloff_width` | `float` | 0.01 – 0.8 | 0.25 | Larghezza normalizzata della transizione terra-mare |
| Rilievo | `land_base_height` | `float` | 0 – 500 m | 6.0 m | Quota media dell'entroterra sopra `sea_level` |
| Rilievo | `min_land_height` | `float` | 0 – 50 m | 1.0 m | Quota minima dell'entroterra (evita laghi in v0.1) |
| Rilievo | `terrain_noise_frequency` | `float` | 0.0001 – 0.1 | 0.006 | Frequenza in unità mondo |
| Rilievo | `terrain_noise_amplitude` | `float` | 0 – 500 m | 12.0 m | Ampiezza delle colline |
| Rilievo | `noise_octaves` | `int` | 1 – 8 | 4 | `FastNoiseLite.fractal_octaves` |
| Rilievo | `noise_lacunarity` | `float` | 1.0 – 4.0 | 2.0 | `FastNoiseLite.fractal_lacunarity` |
| Rilievo | `noise_gain` | `float` | 0.0 – 1.0 | 0.5 | `FastNoiseLite.fractal_gain` |
| Montagne | `mountain_regions` | `Array[UPTGMountainRegion]` | 0 – 16 elementi | 1 regione | Vedi 5.2 |
| Collisione | `collision_mode` | `enum` | `HEIGHTMAP`, `TRIMESH`, `NONE` | `HEIGHTMAP` | Vedi sezione 9 |
| Aspetto | `uv_tile_size` | `float` | 0.1 – 1000 m | 8.0 m | Metri coperti da una ripetizione UV |
| Aspetto | `sand_color`, `grass_color`, `rock_color` | `Color` | — | toni neutri | Vertex colors |
| Aspetto | `beach_height` | `float` | 0 – 50 m | 1.5 m | Fascia di sabbia sopra `sea_level` |
| Aspetto | `rock_slope_degrees` | `float` | 0 – 90 | 35 | Pendenza oltre la quale il colore tende alla roccia |
| Aspetto | `rock_height` | `float` | 0 – 2000 m | 45 m | Quota oltre la quale il colore tende alla roccia |

### 5.2 `UPTGMountainRegion` [APPROVATO]

`class_name UPTGMountainRegion extends Resource`

| Proprietà | Tipo | Intervallo | Significato |
|---|---|---|---|
| `center` | `Vector2` | 0.0 – 1.0 per asse | Posizione normalizzata sul terreno (0,0 = angolo -X/-Z, 1,1 = angolo +X/+Z) |
| `radius` | `float` | 0.01 – 1.0 | Raggio normalizzato rispetto alla dimensione minore del terreno |
| `peak_height` | `float` | 0 – 2000 m | Altezza aggiunta al centro |
| `falloff` | `float` | 0.25 – 8.0 | Esponente della curva di decadimento (1 = morbido, valori alti = picco più stretto) |

Le coordinate normalizzate fanno sì che la montagna resti nella stessa posizione relativa quando cambiano `cell_size` o il numero di celle.

### 5.3 Validazione

`UPTGConfig.validate() -> PackedStringArray` restituisce la lista degli errori (vuota se valida). Regole:

- tutti i valori dentro gli intervalli della tabella 5.1;
- **vincolo della costa:** `max(island_radius.x, island_radius.y) / (1 - coastline_irregularity) <= 0.9`. Con la perturbazione della sezione 8.2 la costa può allontanarsi dal centro fino a `raggio / (1 - irregolarità)`; oltre 0.9 verrebbe tagliata dalla fascia di bordo e diventerebbe un tratto rettilineo. Con i valori predefiniti: 0.6 / 0.75 = 0.8;
- dimensione della griglia e costo stimato secondo la sezione 5.4;
- `mountain_regions` senza elementi `null`, ciascuna regione valida;
- tutti i valori `float` finiti (nessun NaN o infinito).

Se la validazione fallisce, la generazione non parte, il terreno precedente resta in scena e `UPTGTerrain` emette `generation_failed` con il messaggio.

### 5.4 Protezione da configurazioni troppo costose [APPROVATO]

Obiettivo: impedire che un preset, un errore di battitura o un valore modificato a runtime blocchi il gioco o l'editor per molti secondi o esaurisca la memoria.

**Stima preventiva.** `UPTGConfig.estimate_cost() -> Dictionary` calcola, senza generare nulla:

| Chiave | Calcolo |
|---|---|
| `cells` | `grid_cells_x * grid_cells_z` |
| `vertices` | `(grid_cells_x + 1) * (grid_cells_z + 1)` |
| `triangles` | `2 * cells` |
| `noise_samples` | `vertices * (noise_octaves + 2)` (rilievo frattale + costa a 2 ottave) |
| `estimated_bytes` | `vertices * 112 + cells * 24`, più `cells * 72` se `collision_mode == TRIMESH` |
| `level` | `OK`, `LARGE` o `REJECTED` (tabella sotto) |

I coefficienti di memoria sono stime a priori: 112 byte per vertice coprono height field e maschera (8), array della mesh lato CPU (posizione, normale, UV, colore: 48), una copia equivalente lato GPU (48) e la heightmap di collisione (4, arrotondato); 24 byte per cella sono gli indici; 72 byte per cella i triangoli della trimesh, senza la struttura di accelerazione del motore fisico. Vanno **calibrati con misure reali in Milestone D** **[DA VERIFICARE]**.

**Livelli e comportamento:**

| Livello | Condizione | Comportamento |
|---|---|---|
| `OK` | `cells <= 262 144` (512 × 512) e `estimated_bytes <= 128 MB` | Generazione normale |
| `LARGE` | oltre la soglia `OK`, ma `cells <= 1 048 576` e `estimated_bytes <= 512 MB` | Generazione **rifiutata** con `generation_failed`, a meno che il nodo `UPTGTerrain` abbia `allow_large_terrain = true`; in quel caso procede con `push_warning()` |
| `REJECTED` | `grid_cells_x` o `grid_cells_z` oltre 1024, oppure oltre i limiti `LARGE` | Generazione sempre rifiutata, anche con `allow_large_terrain` |

Regole aggiuntive:

- `allow_large_terrain` sta sul **nodo**, non nella Resource: un preset `.tres` condiviso o scaricato non può aggirare la protezione da solo.
- Con `collision_mode == TRIMESH` la soglia `OK` scende a 65 536 celle (256 × 256), perché la trimesh è la parte più costosa da costruire e da interrogare.
- Le soglie sono costanti nominate in `UPTGConfig` (`MAX_CELLS_OK`, `MAX_CELLS_HARD`, `MAX_BYTES_OK`, `MAX_BYTES_HARD`, `MAX_CELLS_OK_TRIMESH`), non valori sparsi nel codice. Potranno essere riviste dopo le misure di Milestone D, con approvazione.
- La stima e il livello vengono riportati da `UPTGTerrain.get_last_stats()` e mostrati nella demo **prima** di generare.
- **Rigenerazione:** `UPTGTerrain.generate()` non è rientrante: una chiamata durante una generazione in corso (per esempio da un gestore di `generation_finished`) viene ignorata con `push_warning()`. La demo applica la rigenerazione solo su azione esplicita (pulsante), non a ogni modifica di un campo.
- **Tempo:** non si impone un timeout, perché la generazione è sincrona e non interrompibile in v0.1. Il tempo è controllato indirettamente da `cells` e `noise_samples`; le soglie in secondi saranno documentate dopo le misure di Milestone D.

---

## 6. Sistema di coordinate e griglia [APPROVATO]

- Godot è Y-up. Il terreno giace sul piano XZ, Y è l'altezza.
- Il terreno è **centrato sull'origine** del nodo `UPTGTerrain`.
- Vertici per asse: `vx = grid_cells_x + 1`, `vz = grid_cells_z + 1`.
- Dimensioni: `size_x = grid_cells_x * cell_size`, `size_z = grid_cells_z * cell_size`.
- Posizione locale del vertice `(ix, iz)`:
  - `x = (ix - grid_cells_x / 2.0) * cell_size`
  - `z = (iz - grid_cells_z / 2.0) * cell_size`
- Indice nell'array: `i = iz * vx + ix` (righe lungo X). Questo ordine corrisponde all'ordine di `HeightMapShape3D.map_data` **[VERIFICATO M0]** (Godot Physics e Jolt; l'ipotesi trasposta dà errori di 23 m).
- Tutte le funzioni di noise e di maschera ricevono coordinate **in metri** (spazio locale), non indici di griglia: cambiare la risoluzione cambia il dettaglio, non la forma dell'isola.

### 6.1 Unità delle frequenze

`FastNoiseLite` moltiplica le coordinate di input per `frequency`. Poiché l'input è in metri, una frequenza di 0.004 corrisponde a strutture con periodo dell'ordine di 1 / 0.004 = 250 m. La documentazione utente userà questa regola pratica.

---

## 7. Sistema di seed e determinismo [APPROVATO]

### 7.1 Sub-seed

Ogni fase casuale usa un proprio sub-seed derivato dal seed principale con un "salt" costante:

| Salt | Costante | Uso in v0.1 |
|---|---|---|
| 1 | `SALT_COASTLINE` | `FastNoiseLite` della costa |
| 2 | `SALT_TERRAIN` | `FastNoiseLite` del rilievo |
| 3 | `SALT_MOUNTAINS` | Riservato (posizionamento casuale di montagne, non in v0.1) |
| 4 – 99 | — | Riservati a UPTG |

Regole: i salt non vengono mai riordinati né riutilizzati; un nuovo uso riceve un nuovo numero.

### 7.2 Funzione di derivazione

Hash intero a 32 bit (variante "lowbias32"), con moltiplicazione modulo 2^32 implementata senza overflow degli `int` a 64 bit di GDScript:

```gdscript
# addons/uptg/core/uptg_seed.gd  (pseudocodice di riferimento, non ancora scritto)
const MASK32 := 0xFFFFFFFF

static func _mul32(a: int, b: int) -> int:
    # (a * b) mod 2^32 senza superare 2^63
    var lo := (a & 0xFFFF) * b
    var hi := ((a >> 16) * b) & 0xFFFF
    return (lo + (hi << 16)) & MASK32

static func derive(master_seed: int, salt: int) -> int:
    var x := (master_seed ^ _mul32(salt, 0x9E3779B9)) & MASK32
    x = _mul32(x ^ (x >> 16), 0x7FEB352D)
    x = _mul32(x ^ (x >> 15), 0x846CA68B)
    x = x ^ (x >> 16)
    return x & 0x7FFFFFFF   # 31 bit, valido come seed di FastNoiseLite
```

- Non si usa `String.hash()` né `hash()`: il loro risultato non è garantito stabile tra versioni del motore.
- Il test `test_seed.gd` fissa valori di riferimento noti ("test vectors") per `derive()`; se cambiano, il test fallisce.

### 7.3 Regole sulla casualità

- Vietati `randi()`, `randf()`, `randomize()`, `seed()` globale e qualsiasi stato casuale globale nel codice dell'addon.
- Ogni eventuale passo casuale usa un `RandomNumberGenerator` locale con `seed` impostato da `UPTGSeed.derive()`.
- Nessuna dipendenza da tempo, frame, ordine di caricamento o dimensioni della finestra.

### 7.4 Garanzia di determinismo

- **Garantito:** stessa configurazione + stesso `generation_seed` + stessa build di Godot + stessa piattaforma = height field identico bit per bit.
- **Obiettivo, non garanzia:** identità tra piattaforme e CPU diverse. Verrà testata quando possibile e documentata.
- `UPTGTerrainData` registra `ALGORITHM_VERSION` (intero, parte da 1). Ogni modifica alla formula che cambia l'output a parità di seed incrementa la versione e viene annotata nel CHANGELOG.
- Il checksum dell'height field usa una funzione propria (FNV-1a a 32 bit sui byte di `heights`), non `hash()`, per lo stesso motivo del punto 7.2.

---

## 8. Algoritmo del terreno [APPROVATO]

### 8.1 Pipeline

```text
per ogni vertice (ix, iz):
  1. posizione locale (x, z) in metri                    [sezione 6]
  2. mask      = shape_mask(x, z)        0 = mare, 1 = entroterra
  3. hills     = terrain_noise(x, z) * terrain_noise_amplitude
  4. mount     = mountains(x, z)
  5. land      = max(land_base_height + hills + mount, min_land_height)
  6. height    = lerp(sea_level - sea_floor_depth, sea_level + land, mask)
  7. heights[i] = height,  land_mask[i] = mask
```

Le fasi 2, 3 e 4 sono funzioni separate. In futuro altre forme (continentale, pianura) sostituiranno solo la fase 2, senza modificare le altre (sezione 14).

### 8.2 Maschera dell'isola (`shape_mask`)

Coordinate normalizzate `u = x / (size_x / 2)`, `v = z / (size_z / 2)`, entrambe in [-1, 1].

```text
d       = sqrt( (u / island_radius.x)^2 + (v / island_radius.y)^2 )   distanza ellittica, 1 = costa di base
c       = clamp(coastline_noise(x, z), -1, 1)                          noise 2D sulla posizione, non sull'angolo
d_pert  = d * (1 + coastline_irregularity * c)
mask    = 1 - smoothstep(1 - coastline_falloff_width, 1, d_pert)
edge    = 1 - smoothstep(0.9, 1.0, max(|u|, |v|))                      garantisce mare sul bordo
mask    = mask * edge
```

- Il noise della costa è campionato sulla posizione (x, z) e non sull'angolo polare, per evitare la cucitura dove l'angolo passa da -π a π.
- Il fattore `edge` garantisce che l'ultimo 10% della griglia sia sempre mare, qualunque sia la configurazione: il bordo della mesh resta sotto il livello del mare e non è visibile.
- Il noise della costa usa `FastNoiseLite` con `seed = derive(generation_seed, SALT_COASTLINE)`, tipo Simplex Smooth, frattale FBM con 2 ottave fisse in v0.1.

### 8.3 Rilievo (`terrain_noise`)

Un solo `FastNoiseLite` [APPROVATO]: `seed = derive(generation_seed, SALT_TERRAIN)`, tipo Simplex Smooth, frattale FBM con `noise_octaves`, `noise_lacunarity`, `noise_gain`, `frequency = terrain_noise_frequency`. Il valore restituito da `get_noise_2d(x, z)` viene limitato a [-1, 1].

### 8.4 Montagne (`mountains`)

Per ogni regione `r`:

```text
centro_m  = ((r.center.x - 0.5) * size_x, (r.center.y - 0.5) * size_z)
raggio_m  = r.radius * min(size_x, size_z)
t         = 1 - clamp(distanza((x, z), centro_m) / raggio_m, 0, 1)
contrib_r = r.peak_height * pow(smoothstep(0, 1, t), r.falloff)
```

`mountains(x, z) = max(contrib_r)` su tutte le regioni. Si usa il massimo, non la somma, per evitare picchi anomali dove le regioni si sovrappongono. Poiché il risultato passa per il `lerp` con la maschera (fase 6), una montagna posta in mare non emerge.

### 8.5 Linea di costa

Con la formula della fase 6, la quota è esattamente `sea_level` dove:

```text
mask = sea_floor_depth / (sea_floor_depth + land)
```

Con i valori predefiniti (fondale 20 m, entroterra circa 6 m) la costa cade dove la maschera vale circa 0.77. La documentazione utente spiegherà come `sea_floor_depth` e `coastline_falloff_width` controllano la pendenza della spiaggia.

### 8.6 Limiti noti dell'algoritmo in v0.1

- Nessun lago interno (impedito da `min_land_height`; esclusione confermata, D4 [APPROVATO]), nessun fiume, nessuna erosione.
- Le montagne sono coni morbidi, non catene.
- Le pendenze massime dipendono da `cell_size` e dall'ampiezza del noise; vanno misurate in Milestone D.

---

## 9. Contratto dati: `UPTGTerrainData` [APPROVATO]

`class_name UPTGTerrainData extends RefCounted`. È il **contratto ufficiale** tra UPTG e qualsiasi sistema esterno. Dopo la generazione è da considerare in sola lettura.

### 9.1 Campi

| Campo | Tipo | Significato |
|---|---|---|
| `ALGORITHM_VERSION` | `const int` | Versione dell'algoritmo che ha prodotto i dati |
| `generation_seed` | `int` | Seed usato |
| `config_checksum` | `int` | FNV-1a a 32 bit di `var_to_bytes()` applicato a un `Array` ordinato dei soli parametri che influenzano le altezze (seed, griglia, mare, isola, rilievo, montagne). Stabile nella stessa versione di Godot, non garantito tra versioni |
| `heights_checksum` | `int` | FNV-1a a 32 bit di `heights` |
| `grid_cells_x`, `grid_cells_z` | `int` | Celle per asse |
| `vertex_count_x`, `vertex_count_z` | `int` | Vertici per asse (celle + 1) |
| `cell_size` | `float` | Lato della cella in metri |
| `size` | `Vector2` | Dimensioni totali (X, Z) in metri |
| `sea_level` | `float` | Livello del mare |
| `sea_floor_depth` | `float` | Profondità del fondale sotto `sea_level` (usata anche fuori griglia) |
| `min_height`, `max_height` | `float` | Estremi dell'height field |
| `heights` | `PackedFloat32Array` | Altezze in spazio locale, indice `iz * vx + ix` |
| `land_mask` | `PackedFloat32Array` | Valore della maschera (0–1) per vertice |

### 9.2 Metodi di query

Tutte le coordinate sono nello **spazio locale** del nodo `UPTGTerrain`. Il nodo fornisce le versioni in spazio mondo.

| Metodo | Risultato |
|---|---|
| `get_vertex_height(ix, iz) -> float` | Altezza del vertice |
| `get_vertex_position(ix, iz) -> Vector3` | Posizione locale del vertice |
| `is_inside(x, z) -> bool` | Se il punto cade dentro la griglia |
| `get_height_at(x, z) -> float` | Altezza interpolata sui **triangoli**, con la stessa diagonale della mesh e della collisione (sezione 10.2), così coincide con ciò che il giocatore vede e tocca |
| `get_normal_at(x, z) -> Vector3` | Normale interpolata |
| `get_mask_at(x, z) -> float` | Maschera interpolata |
| `is_land_at(x, z) -> bool` | `get_height_at(x, z) > sea_level` |

Fuori dalla griglia, `get_height_at` restituisce `sea_level - sea_floor_depth` e `is_inside` restituisce `false`.

### 9.3 Uso da parte di moduli futuri

Un modulo strade o vegetazione riceve un `UPTGTerrainData` (direttamente o tramite `UPTGTerrain.get_terrain_data()`) e usa solo i campi e i metodi di questa sezione. Ogni cambiamento incompatibile del contratto richiede un incremento di versione maggiore e una nota nel CHANGELOG.

La modifica del terreno da parte di moduli futuri (per esempio spianare una strada) non è prevista in v0.1; sarà oggetto di una decisione futura.

---

## 10. Mesh [APPROVATO]

`UPTGMeshBuilder.build(data: UPTGTerrainData, config: UPTGConfig) -> ArrayMesh`

### 10.1 Dati geometrici

- Un vertice per punto della griglia (`vx * vz` vertici), geometria **indicizzata**.
- Array `PackedVector3Array`, `PackedVector2Array`, `PackedColorArray`, `PackedInt32Array` pre-dimensionati con `resize()`.
- Una sola superficie, creata con `ArrayMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)`.
- Oltre 65 535 vertici gli indici restano integri **[VERIFICATO M0]**: mesh di 90 000 vertici e 536 406 indici, indice massimo 89 999 riletto correttamente, sia headless sia con il renderer Forward+ (Vulkan).

### 10.2 Triangoli, winding e diagonale

- Ogni cella produce 2 triangoli, quindi `2 * grid_cells_x * grid_cells_z` triangoli.
- Ordine di avvolgimento: la faccia frontale è quella con vertici in senso **orario visti dall'osservatore** **[VERIFICATO M0]**. Verificato nel rendering (culling predefinito `CULL_BACK`: il triangolo orario visto dalla camera è visibile, quello antiorario no) e nella fisica (`ConcavePolygonShape3D` con `backface_collision = false`: il raggio colpisce solo dal lato da cui i vertici appaiono orari), su entrambi i backend. Per un terreno visto dall'alto, ogni triangolo va quindi emesso in senso orario visto da +Y.
- Tutte le celle usano la **stessa diagonale**: quella che unisce il vertice `(ix + 1, iz)` al vertice `(ix, iz + 1)` **[VERIFICATO M0]**. È la diagonale usata da `HeightMapShape3D` in tutte le celle, con Godot Physics e con Jolt. Ogni cella si divide quindi nei triangoli `(00, 10, 01)` e `(10, 11, 01)`. Con la diagonale opposta l'errore misurato su un terreno di prova arriva a 31.6 cm. La stessa regola vale per `get_height_at`: se `fx + fz <= 1` si interpola sul triangolo `(00, 10, 01)`, altrimenti su `(10, 11, 01)`.

### 10.3 Normali

Calcolate dall'height field con differenze centrali (differenze unilaterali sui bordi):

```text
n = normalize( Vector3( h(ix-1, iz) - h(ix+1, iz),  2 * cell_size,  h(ix, iz-1) - h(ix, iz+1) ) )
```

Non si usa `SurfaceTool.generate_normals()`. Le tangenti non vengono generate in v0.1 (nessuna normal map).

### 10.4 UV

Proiezione planare in metri: `uv = Vector2(x, z) / uv_tile_size`. Limite noto: allungamento della texture sulle pendenze ripide. La proiezione triplanare è rimandata.

### 10.5 Vertex colors

Colore per vertice calcolato da quota e pendenza, con transizioni morbide (`smoothstep`):

- sabbia: quota entro `beach_height` sopra `sea_level`;
- roccia: pendenza oltre `rock_slope_degrees` o quota oltre `rock_height`;
- erba: altrove.

### 10.6 Materiale [APPROVATO]

Un `StandardMaterial3D` (`addons/uptg/materials/uptg_terrain_default.tres`) con `vertex_color_use_as_albedo = true`. Nessuno shader custom in v0.1. Il nodo permette di sostituirlo con un materiale del gioco.

---

## 11. Collisione [APPROVATO]

`UPTGCollisionBuilder.build(data: UPTGTerrainData, mode) -> Shape3D` (oppure `null` per `NONE`).

### 11.1 `HEIGHTMAP` (predefinito)

- `HeightMapShape3D` con `map_width = vertex_count_x`, `map_depth = vertex_count_z`.
- `map_data` = `heights` divise per `cell_size`, perché la shape usa campioni distanziati di 1 unità.
- Il `CollisionShape3D` riceve una scala **uniforme** `Vector3(cell_size, cell_size, cell_size)`; dividere le altezze e scalare uniformemente evita la scala non uniforme, non affidabile sulle collision shape.
- La shape è centrata sulla propria origine, come la mesh (sezione 6).
- **[VERIFICATO M0]** (D5): la shape è centrata sull'origine; `map_data` segue l'ordine `iz * vx + ix`; la diagonale è quella della sezione 10.2; la scala uniforme del `CollisionShape3D` con altezze divise per `cell_size` funziona (provata con `cell_size` 1 e 4, errore massimo 0.09 mm con Godot Physics e 0.13 mm con Jolt). Le stesse regole valgono per griglie non quadrate (7×4, 4×9, 65×33 vertici; errore massimo 0.22 mm). Nessuna collisione fuori dalla griglia.
- **Backend fisico (D3, [APPROVATO]):** i test iniziali usano il backend predefinito; lo stesso test viene ripetuto sull'altro backend e il risultato è documentato.
- **[VERIFICATO M0]** Con il `project.godot` di UPTG l'impostazione `physics/3d/physics_engine` vale `DEFAULT` e il backend effettivo è **Godot Physics**: i valori dei raggi coincidono bit per bit con quelli ottenuti forzando `GodotPhysics3D` e differiscono da quelli con Jolt. `PhysicsServer3D.get_class()` restituisce `PhysicsServer3D` con entrambi i backend e non serve a identificarli. Jolt è stato provato tramite un `override.cfg` temporaneo: ordine, centratura, diagonale, winding e scala si comportano in modo identico.

### 11.2 `TRIMESH` (alternativa)

`ConcavePolygonShape3D` costruita dagli stessi triangoli della mesh con `set_faces()`. Più costosa in memoria e tempo di costruzione; utile se `HEIGHTMAP` mostrasse limiti in un caso specifico. Con `backface_collision = false` (valore predefinito) i triangoli devono essere orari visti da +Y, come nella mesh, altrimenti i raggi dall'alto non li colpiscono **[VERIFICATO M0]**.

### 11.3 `NONE`

Nessuna collisione; `UPTGTerrain` rimuove o disattiva lo `StaticBody3D`.

### 11.4 Regole

- La collisione è sempre su uno `StaticBody3D`, mai su un corpo dinamico.
- `collision_layer` e `collision_mask` sono esportati sul nodo `UPTGTerrain`.
- Il test di allineamento (A8) lancia raggi verticali su una griglia di punti e confronta il punto d'impatto con `get_height_at`; la differenza deve restare entro la tolleranza. **D6:** 1 cm **[VERIFICATO M0]**. Su una griglia 64 × 64 con `cell_size` 4 e 2000 raggi, l'errore massimo con la diagonale corretta è 0.19 mm (Godot Physics) e 0.15 mm (Jolt) per `HEIGHTMAP`, 0.20 mm o meno per `TRIMESH`: la tolleranza di 1 cm ha un ampio margine e viene confermata.

---

## 12. Nodo `UPTGTerrain` [APPROVATO]

`class_name UPTGTerrain extends Node3D`. È il punto di ingresso per qualsiasi gioco.

### 12.1 Interfaccia

| Tipo | Nome | Descrizione |
|---|---|---|
| `@export` | `config: UPTGConfig` | Preset da usare |
| `@export` | `generate_on_ready: bool = true` | Genera in `_ready()` |
| `@export` | `material_override: Material` | Opzionale; se vuoto usa il materiale predefinito |
| `@export` | `allow_large_terrain: bool = false` | Autorizza configurazioni di livello `LARGE` (sezione 5.4) |
| `@export_flags_3d_physics` | `collision_layer`, `collision_mask` | Layer della collisione |
| metodo | `generate() -> bool` | Valida, genera, sostituisce mesh e collisione |
| metodo | `clear()` | Rimuove mesh e collisione |
| metodo | `get_terrain_data() -> UPTGTerrainData` | Ultimo risultato valido o `null` |
| metodo | `get_height_at_world(pos: Vector3) -> float` | Query in spazio mondo |
| metodo | `get_last_stats() -> Dictionary` | Tempi (µs) per fase, vertici, triangoli, stima di costo e livello (5.4) |
| segnale | `generation_started` | — |
| segnale | `generation_finished(data: UPTGTerrainData)` | — |
| segnale | `generation_failed(message: String)` | — |

### 12.2 Nodi figli

```text
UPTGTerrain (Node3D)
├── UPTGMesh       (MeshInstance3D)
└── UPTGBody       (StaticBody3D)
    └── UPTGShape  (CollisionShape3D)
```

- Creati alla prima generazione, con nomi fissi.
- Non ricevono un `owner`: non vengono salvati nella scena `.tscn`, così i file di scena restano piccoli e senza dati generati.
- Alla rigenerazione si **sostituiscono le risorse** (`mesh`, `shape`), non i nodi. Nessun nodo duplicato, mai.

### 12.3 Atomicità ed errori

- Prima si genera tutto (dati, mesh, shape); solo se ogni passo riesce si sostituiscono le risorse nei nodi. In caso di errore il terreno precedente resta intatto.
- Gli errori vengono emessi con `push_error()` e con il segnale `generation_failed`.
- La generazione è sincrona; non va chiamata dentro `_physics_process` o callback fisiche.
- Limite noto: corpi fisici appoggiati sul terreno durante una rigenerazione possono attraversarlo o essere spinti; documentato, non gestito in v0.1.

### 12.4 Runtime soltanto [APPROVATO]

Nessuno script usa `@tool`. Non esistono anteprima nell'editor, editor dock o baking in v0.1.

---

## 13. Prestazioni

Nessun valore di prestazione è dichiarato finché non viene misurato. In Milestone D si misurano, per 128 × 128, 256 × 256 e 512 × 512 celle:

- tempo di generazione dell'height field, della mesh e della collisione (separatamente);
- numero di vertici e triangoli;
- memoria stimata di mesh e shape;
- tempo di costruzione della collisione in `HEIGHTMAP` e `TRIMESH`;
- frame time nella demo.

La misura `TRIMESH` a 512 × 512 celle supera la soglia `OK` della trimesh (sezione 5.4) e richiede `allow_large_terrain = true` nella scena di misura.

Rischio noto: il ciclo per vertice in GDScript è la parte più costosa. Il generatore è puro proprio per poterlo spostare in futuro su `WorkerThreadPool` senza riscriverlo (fuori perimetro v0.1).

Limite noto: una sola mesh significa che il frustum culling vale per tutto il terreno o per niente.

---

## 14. Estendibilità futura (solo progettazione, non implementata)

| Futuro | Come si inserisce senza riscrivere il core |
|---|---|
| Terreno continentale, pianure | Nuova funzione di forma al posto di `shape_mask` (fase 2), selezionata da un enum in `UPTGConfig` |
| Colline e varianti di rilievo | Nuovi parametri o profili di noise nella fase 3 |
| Catene montuose | Nuovo tipo di regione (per esempio a polilinea) accanto a `UPTGMountainRegion` |
| Ambienti survival o fantasy | Preset `.tres` e materiali diversi; il core non cambia |
| Strade, vegetazione, world generation | Moduli separati che leggono `UPTGTerrainData` |
| Erosione, laghi, fiumi | Fasi di post-elaborazione sull'height field |
| Mondi grandi | Chunking e LOD costruiti sopra `UPTGTerrainData`, generazione in thread |
| Anteprima editor e baking | `UPTGTerrainData` potrà diventare `Resource` salvabile; script `@tool` |

---

## 15. Test e criteri di accettazione [APPROVATO]

### 15.1 Infrastruttura

- Test headless con script GDScript eseguiti da riga di comando (`godot --headless --path <progetto> -s res://tests/run_tests.gd`) **[VERIFICATO M0]**: lo script estende `SceneTree`, la fisica funziona in headless (raggi e corpi statici), `quit(n)` restituisce il codice d'uscita `n` e un errore di parsing restituisce 1. Il rendering in headless è fittizio: i test che leggono pixel richiedono una finestra.
- Godot 4.7.2 genera un file `.gd.uid` accanto a ogni script: va committato insieme allo script **[VERIFICATO M0]**.
- Nessun framework esterno (per esempio GUT) in v0.1, per non introdurre dipendenze.
- Il test di collisione richiede una scena con fisica attiva (`tests/collision/collision_test.tscn`).
- `documentation/TESTING.md` descrive come eseguire ogni test e come verificare a mano la demo.

### 15.2 Criteri di accettazione v0.1

| # | Criterio | Verifica |
|---|---|---|
| A1 | Il progetto si apre in Godot 4.7.2 senza nuovi errori o warning dell'addon | Manuale |
| A2 | La demo si avvia autonomamente | Manuale |
| A3 | Viene generata un'isola 3D con costa visibilmente irregolare | Manuale + screenshot |
| A4 | Sono presenti colline e almeno una regione montuosa | Manuale |
| A5 | La validazione rifiuta configurazioni non valide con messaggi chiari | `test_validation.gd` |
| A5b | La protezione della sezione 5.4 classifica correttamente `OK`, `LARGE` e `REJECTED`; `LARGE` è rifiutato senza `allow_large_terrain`; `REJECTED` è rifiutato sempre; un rifiuto non altera il terreno esistente | `test_validation.gd` (solo stima, senza generare terreni grandi) |
| A6 | Mesh valida: indici nei limiti, nessun NaN, normali unitarie, numero di triangoli atteso | `test_mesh.gd` |
| A7 | Stesso seed e stessa configurazione producono lo stesso checksum; seed diverso lo cambia; i test vector di `UPTGSeed` sono rispettati | `test_determinism.gd`, `test_seed.gd` |
| A8 | Collisione allineata alla mesh entro la tolleranza, in modalità `HEIGHTMAP` e `TRIMESH`, sul backend predefinito; risultato sull'altro backend documentato | `collision_test` |
| A9 | Corpi `RigidBody3D` lasciati cadere su una griglia di punti si fermano sulla superficie; una capsula `CharacterBody3D` percorre le pendenze moderate | `collision_test` + demo |
| A10 | 20 rigenerazioni consecutive non aumentano il numero di nodi né la memoria in modo continuo | Test + monitor della demo |
| A11 | Il bordo della griglia è sempre sotto `sea_level` | `test_determinism.gd` |
| A12 | La configurazione si salva e si ricarica come preset `.tres` con risultato identico | Test |
| A13 | Il codice in `addons/uptg/` non fa riferimento a percorsi esterni all'addon né a giochi specifici | Ricerca testuale |
| A14 | Nessun uso di RNG globale nell'addon (`randi`, `randf`, `randomize`, `seed(`) | Ricerca testuale |
| A15 | Tutti i nuovi file sono documentati; nessun file esistente non correlato è stato modificato | Revisione |
| A16 | Le misure della sezione 13 sono registrate in `TESTING.md` | Revisione |

---

## 16. Stato delle decisioni

### 16.1 Decisioni approvate [APPROVATO]

| # | Decisione | Sezione |
|---|---|---|
| — | Le 15 decisioni architetturali approvate il 2026-11-06 (contratto dati, nodo, collisione, griglia, seed, determinismo, formula, montagne, noise, mesh, materiali, solo runtime, addon portabile, generatore puro, test) | 1–15 |
| D1 | Struttura R12: `core/`, `builders/`, `nodes/`, `materials/`, `presets/` dentro `addons/uptg/`; documenti generali del repository non modificati ora | 3 |
| D2 | Licenza "All rights reserved"; nessuna licenza permissiva né distribuzione pubblica | 3 |
| D3 | Test iniziali sul backend fisico predefinito di Godot 4.7.2; verifica documentata sull'altro backend | 11.1 |
| D4 | Nessun lago interno in v0.1 | 8.6 |
| D6 | Tolleranza iniziale di allineamento: 1 cm (da confermare, vedi 16.2) | 11.4 |
| D8 | La documentazione nel repository è ufficiale; le copie esterne sono riferimenti locali | 0 |
| D9 | Le decisioni fondamentali hanno ADR sintetici: ADR-0001 … ADR-0006 in `Documentation/architecture/decisions/` (creati in Milestone 0) | 16.3 |
| — | Protezione da configurazioni troppo costose | 5.4 |

### 16.2 Verifiche sperimentali

**Eseguite in Milestone 0 [VERIFICATO M0]** (dettagli in `documentation/M0_VERIFICATION.md`):

| Tema | Risultato |
|---|---|
| Apertura del progetto in 4.7.2 | Editor headless e con interfaccia (Vulkan Forward+, Intel UHD 620): nessun errore, codice d'uscita 0 |
| Backend fisico predefinito | `DEFAULT`, che per questo progetto corrisponde a Godot Physics |
| API dell'architettura | Tutte disponibili e funzionanti (elenco in M0_VERIFICATION) |
| Seed di `FastNoiseLite` | 2 147 483 647 viene conservato; 3 000 000 000 diventa -1 294 967 296: il limite a 31 bit della sezione 5.1 è necessario |
| Funzione `derive()` della sezione 7.2 | Risultati identici ai valori calcolati in modo indipendente (4 test vector) |
| D5: ordine di `map_data` e centratura | `iz * vx + ix`, centrata sull'origine, entrambi i backend |
| D5: diagonale | `(ix + 1, iz)`–`(ix, iz + 1)` in tutte le celle, entrambi i backend, anche su griglie non quadrate |
| D5: winding | Frontale = orario visto dall'osservatore, rendering e fisica |
| Scala uniforme del `CollisionShape3D` | Funziona, entrambi i backend |
| D6: tolleranza | 1 cm confermato (errore massimo misurato 0.2 mm) |
| Altro backend (Jolt) | Stesso comportamento; differenze numeriche di circa 0.1 mm |
| Indici a 32 bit | Integri oltre 65 535 vertici |
| Test headless | Funzionano, con codice d'uscita affidabile |

**Ancora da verificare:**

| Tema | Quando | Azione |
|---|---|---|
| Backend assegnato da Godot a un progetto creato dal Project Manager (il `project.godot` di UPTG è stato scritto a mano) | Se servirà | Non influisce su UPTG: entrambi i backend si comportano allo stesso modo |
| Coefficienti di memoria e soglie della protezione | Milestone D | Aggiornare le costanti con approvazione |
| Determinismo cross-platform | Quando sarà disponibile una seconda piattaforma | Documentare; resta un obiettivo, non una garanzia |

### 16.3 Decisioni rinviate [RINVIATO]

| Tema | Rinviato a | Note |
|---|---|---|
| D7: valori definitivi del preset isola | Milestone D, dopo la demo | I valori della tabella 5.1 sono provvisori |
| Allineamento di `Documentation/architecture/README.md`, README di modulo e cartella `presets/` di modulo alla struttura R12 | Aggiornamento documentale separato, da approvare | Fino ad allora prevale questo documento per UPTG |
| Soglie di tempo in secondi per la protezione | Milestone D | Dopo le misure reali |
| Spostamento della generazione su thread | Dopo v0.1 | Reso possibile dal generatore puro |
| Anteprima editor, `@tool`, baking su file | v0.2.0 o successiva | Fuori perimetro v0.1 |
| Modifica del terreno da parte di moduli futuri (per esempio strade) | Progettazione di UPRG | `UPTGTerrainData` resta in sola lettura in v0.1 |
| Licenza permissiva o distribuzione | Solo con decisione esplicita di Stefano | D2 |

---

## 17. Sequenza di implementazione

Ogni milestone inizia solo dopo l'approvazione esplicita di Stefano e termina con un report: file creati o modificati, test eseguiti realmente, limiti, proposta per la milestone successiva.

### Milestone 0 — Setup e verifica delle API

- Su un branch `uptg/milestone-0-setup` del repository esistente, creare `project.godot` in `UPTG/UniversalProceduralTerrainGenerator/` e le cartelle secondo la decisione D1; nessuna modifica ai documenti esistenti senza approvazione.
- Verificare che il progetto si apra in 4.7.2 e registrare il backend fisico.
- Uno script temporaneo che verifica ogni API usata dal progetto (`FastNoiseLite`, `ArrayMesh`, `HeightMapShape3D`, `ConcavePolygonShape3D`, `Array[Resource]` esportati, raycast, esecuzione headless). Eliminato al termine.
- Test sperimentale su una griglia 4 × 4 con altezze note per determinare D5 e confermare D6, prima sul backend predefinito e poi sull'altro (D3).
- Scrivere gli ADR sintetici previsti da D9 (sezione 16.3), solo dopo l'approvazione dell'avvio della Milestone 0.
- Aggiornare le parti **[DA VERIFICARE]** di questo documento con i risultati.
- **Stato:** completata il 2026-11-06 (risultati in `documentation/M0_VERIFICATION.md`).

### Milestone A — Dati e height field (senza scena)

- `UPTGConfig`, `UPTGMountainRegion`, validazione, stima di costo e protezione (5.4).
- `UPTGSeed` con test vector.
- `UPTGTerrainData` con metodi di query.
- `UPTGHeightfieldGenerator`: maschera, noise, montagne, formula.
- Test: A5, A5b, A7, A11, A12.

### Milestone B — Mesh, nodo e demo

- `UPTGMeshBuilder`: geometria, normali, UV, vertex colors, materiale predefinito.
- `UPTGTerrain`: segnali, nodi figli, rigenerazione atomica.
- Demo: generazione all'avvio, pulsante di rigenerazione, campo seed, pannello informazioni (tempi, vertici, triangoli), wireframe, piano d'acqua al `sea_level` (solo nella demo).
- Test: A2, A3, A4, A6, A10.

### Milestone C — Collisione

- `UPTGCollisionBuilder`: `HEIGHTMAP`, `TRIMESH`, `NONE`.
- Scena di test con raycast, corpi che cadono e capsula.
- Test: A8, A9.

### Milestone D — Qualità, misure e documentazione

- Taratura del preset isola dopo la demo (D7).
- Calibrazione dei coefficienti di memoria e delle soglie della sezione 5.4 con le misure reali.
- Misure della sezione 13 in `TESTING.md`.
- README dell'addon, TESTING, CHANGELOG; verifica A1, A13 – A16.
- Versione `0.1.0`.

---

## 18. Documentazione e versioni

- `UPTG_ARCHITECTURE.md` — Draft 0.1, conservato invariato.
- `UPTG_ARCHITECTURE_0.2.md` — questo documento, aggiornato dopo Milestone 0.
- `addons/uptg/README.md` — come usare l'addon in un altro progetto.
- `documentation/TESTING.md` — procedure di verifica e misure.
- `CHANGELOG.md` — modifiche per versione, incluse le variazioni di `ALGORITHM_VERSION`.

Versioni previste (provvisorie): `0.1.0` primo generatore di isole funzionante; `0.2.0` controlli migliorati, eventuale anteprima editor e baking; `1.0.0` modulo stabile dopo test e documentazione.

---

## 19. Protocollo di lavoro con Claude

Prima di ogni milestone: ispezionare i file, confermare il piano, attendere l'approvazione.
Durante: milestone piccole, verifica della sintassi, esecuzione della demo e dei test quando possibile, nessuna modifica a file non correlati.
Dopo: elenco dei file creati e modificati, test realmente eseguiti, limiti, proposta della milestone successiva senza avviarla.

Questo documento definisce l'architettura. Non autorizza implementazioni, modifiche distruttive o sistemi fuori perimetro.

---

## Appendice A — Modifiche rispetto al Draft 0.1

| Area | Draft 0.1 | Versione 0.2 |
|---|---|---|
| Output | "restituire o esporre il risultato" | Contratto `UPTGTerrainData` con campi e query definiti |
| Integrazione | Solo scena demo | Nodo riutilizzabile `UPTGTerrain` |
| Nomi classi | `UPTGGenerator`, `UPTGTerrainBuilder` | `UPTGHeightfieldGenerator` (puro), `UPTGMeshBuilder`; più `UPTGSeed`, `UPTGMountainRegion` |
| Griglia | `terrain_size_x/z` + `resolution_x/z` | `grid_cells_x/z` + `cell_size`, celle quadrate, terreno centrato |
| Collisione | Trimesh | `HeightMapShape3D` predefinita, trimesh alternativa, `NONE` |
| Seed | `seed` senza meccanismo | `generation_seed` a 31 bit, sub-seed con funzione documentata, RNG locali |
| Determinismo | Requisito generico | Garanzia precisa, `ALGORITHM_VERSION`, checksum |
| Formula | Componenti elencate | Formula esplicita, `sea_level`, `sea_floor_depth`, bordo garantito in mare |
| Montagne | Elenco di proprietà | `UPTGMountainRegion` Resource, coordinate normalizzate, combinazione con `max` |
| Noise | Fino a tre livelli | Due `FastNoiseLite` (rilievo frattale, costa) |
| Materiali | Erba/roccia/sabbia generici | `StandardMaterial3D` con vertex colors |
| Editor | Non specificato | Solo runtime, niente `@tool` né baking |
| Struttura | `materials/` fuori dall'addon, presets in demo | Addon autosufficiente, progetto Godot per modulo, `tests/` |
| Test | Criteri manuali, riferimento a un veicolo e a Nitro Underground | Test automatici, corpi fisici generici, criteri verificabili |
| Sequenza | Collisione in Milestone C con griglia libera | Milestone 0 di verifica API; vincoli della collisione fissati prima del codice |
| Testo | Caratteri invisibili in due nomi di classe | Rimossi |

---

## Appendice B — Storico del documento

| Revisione | Data | Modifiche |
|---|---|---|
| 0.2-r1 | 2026-11-06 | Prima stesura in italiano con le 15 decisioni approvate |
| 0.2-r2 | 2026-11-06 | Incorporate D1–D9; aggiunta la protezione da configurazioni costose (5.4, A5b); sezione 16 divisa in approvato, da verificare, rinviato; corretti il vincolo raggio/irregolarità della costa e i valori predefiniti di `island_radius`, il campo mancante `sea_floor_depth` in `UPTGTerrainData`, la definizione di `config_checksum` e il tipo di `UPTGHeightfieldGenerator` |
| 0.2-r3 | 2026-11-06 | Risultati della Milestone 0: aggiunta l'etichetta [VERIFICATO M0]; registrati ordine di `map_data`, centratura, diagonale `(ix + 1, iz)`–`(ix, iz + 1)`, winding orario, scala uniforme, tolleranza di 1 cm confermata, backend predefinito (Godot Physics), comportamento identico di Jolt, indici a 32 bit, test headless e file `.gd.uid`. Nessuna decisione architetturale modificata |
