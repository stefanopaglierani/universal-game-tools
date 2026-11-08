[English](README.md) | **Italiano**

# Addon UPTG (`addons/uptg/`)

UPTG (Universal Procedural Terrain Generator) genera a runtime, in Godot 4.7.2, un'isola 3D deterministica: height field, mesh con vertex colors e collisione. È scritto in GDScript tipizzato, non ha dipendenze e non fa riferimento a nessun gioco.

Versione: **0.1.0** (`ALGORITHM_VERSION` 1). Licenza: tutti i diritti riservati, vedi `LICENSE`.

UPTG è uno strumento di sviluppo privato: per mettere un mondo in un gioco va esportato con `tools/uptg_bake.gd` (vedi il README del modulo e ADR-0009). I passaggi seguenti servono a lavorare con il generatore in un progetto strumento, non a distribuirlo.

## Installazione

1. Copiare l'intera cartella `addons/uptg/` nella cartella `addons/` del proprio progetto Godot 4.7.2, mantenendo il percorso `res://addons/uptg/`.
2. Aprire il progetto una volta nell'editor (oppure eseguire `godot --headless --editor --quit`), così Godot registra le classi `UPTG*`.

UPTG non è un plugin dell'editor: non c'è niente da attivare in **Impostazioni progetto > Plugin**.

## Avvio rapido

1. Aggiungere un nodo `UPTGTerrain` a una scena 3D.
2. Nell'Inspector, impostare **Config** su `res://addons/uptg/presets/uptg_island_default.tres`, oppure creare una nuova risorsa `UPTGConfig`.
3. Eseguire la scena. Con **Generate On Ready** attivo, l'isola viene generata quando il nodo entra nell'albero.

Da codice:

```gdscript
var terrain := UPTGTerrain.new()
terrain.config = (load("res://addons/uptg/presets/uptg_island_default.tres") as UPTGConfig).duplicate(true)
terrain.config.generation_seed = 777
terrain.generation_finished.connect(func(data: UPTGTerrainData) -> void:
	print("isola pronta, checksum ", data.heights_checksum))
terrain.generation_failed.connect(func(message: String) -> void:
	push_warning(message))
add_child(terrain)  # genera in _ready()
```

Usare `duplicate(true)` prima di modificare un preset a runtime: il file `.tres` è una risorsa condivisa e le sue regioni montuose sono sotto-risorse.

Per rigenerare, modificare la configurazione e chiamare `terrain.generate()`, che restituisce `true` se riesce. La generazione è sincrona: va chiamata su un'azione esplicita (un pulsante, il caricamento di un livello), non a ogni frame né dai callback della fisica.

## Il nodo `UPTGTerrain`

| Membro | Descrizione |
|---|---|
| `config: UPTGConfig` | Parametri da generare. Obbligatorio. |
| `generate_on_ready: bool` | Genera in `_ready()`. Predefinito `true`. |
| `material_override: Material` | Materiale del terreno; se vuoto si usa il materiale predefinito con i vertex colors. |
| `allow_large_terrain: bool` | Permette le configurazioni con livello di costo `LARGE` (vedi sotto). Predefinito `false`. |
| `collision_layer`, `collision_mask` | Layer fisici del corpo del terreno. |
| `generate() -> bool` | Valida, genera e sostituisce il terreno. In caso di errore resta il terreno precedente. Una chiamata fatta durante una generazione in corso viene ignorata con un avviso. |
| `clear()` | Rimuove mesh e collisione generate. |
| `get_terrain_data() -> UPTGTerrainData` | Ultimo risultato riuscito, oppure `null`. |
| `get_height_at_world(pos: Vector3) -> float` | Quota del terreno sotto una posizione in spazio mondo, oppure `NAN` prima della prima generazione. |
| `get_last_stats() -> Dictionary` | Tempi per fase in microsecondi (`heightfield_us`, `mesh_us`, `collision_us`, `apply_us`, `total_us`), `vertices`, `triangles`, `estimated_bytes`, `cost_level`, `collision_mode`. |
| `generation_started`, `generation_finished(data)`, `generation_failed(message)` | Segnali. |

Il nodo crea i suoi figli alla prima generazione: `UPTGMesh` (`MeshInstance3D`) e `UPTGBody` (`StaticBody3D`) con `UPTGShape` (`CollisionShape3D`). Non hanno owner, quindi non vengono mai salvati nella scena. Non vanno aggiunti né rimossi a mano.

Il terreno è centrato sul nodo: copre `grid_cells_x * cell_size` per `grid_cells_z * cell_size` metri attorno all'origine del nodo. Il nodo si può spostare e ruotare attorno a Y, ma non inclinare.

## Parametri principali (`UPTGConfig`)

| Gruppo | Parametri |
|---|---|
| Seed | `generation_seed` (0 – 2 147 483 647). Stesso seed e stessa configurazione danno sempre lo stesso terreno. |
| Griglia | `grid_cells_x`, `grid_cells_z` (2 – 1024), `cell_size` in metri. |
| Mare | `sea_level`, `sea_floor_depth`. Il bordo della griglia è sempre sotto il mare. |
| Isola | `island_radius`, `coastline_irregularity`, `coastline_noise_frequency`, `coastline_falloff_width`. |
| Rilievo | `land_base_height`, `min_land_height`, `terrain_noise_frequency`, `terrain_noise_amplitude`, `noise_octaves`, `noise_lacunarity`, `noise_gain`. |
| Montagne | `mountain_regions`: fino a 16 `UPTGMountainRegion` (`center` e `radius` normalizzati, `peak_height` in metri, `falloff`). |
| Collisione | `collision_mode`: `HEIGHTMAP` (predefinito, il più economico), `TRIMESH` o `NONE`. |
| Aspetto | `uv_tile_size`, `sand_color`, `grass_color`, `rock_color`, `beach_height`, `rock_slope_degrees`, `rock_height`. |

Le frequenze sono in unità mondo: se si mantiene la stessa dimensione in metri (`grid_cells * cell_size`) e si cambia il numero di celle, cambia solo la risoluzione, non la forma dell'isola. L'elenco completo, con intervalli e valori predefiniti, è nella sezione 5 di `documentation/UPTG_ARCHITECTURE_0.2.it.md`.

`config.validate()` restituisce l'elenco degli errori (vuoto se la configurazione è valida); `generate()` rifiuta una configurazione non valida ed emette `generation_failed` con i messaggi.

## Protezione dai costi

Prima di generare, `config.estimate_cost()` stima celle, vertici e memoria, e assegna un livello:

- `OK`: fino a 512 × 512 celle (256 × 256 con `TRIMESH`) e 128 MB: generazione normale.
- `LARGE`: fino a 1024 × 1024 celle e 512 MB: rifiutata, a meno che il nodo abbia `allow_large_terrain = true`; in quel caso viene generata con un avviso.
- `REJECTED`: oltre questi limiti: sempre rifiutata.

`allow_large_terrain` sta sul nodo, non nella configurazione, così un preset condiviso non può aggirare la protezione. Come riferimento, su un portatile con Intel UHD 620, 256 × 256 celle richiedono circa 0.5 s e 512 × 512 celle circa 1.9 s con collisione `HEIGHTMAP` (misure in `documentation/TESTING.it.md`).

## Leggere il terreno da codice

`UPTGTerrainData` (da `get_terrain_data()` o da `generation_finished`) contiene il risultato nello spazio locale del nodo:

- `get_height_at(x, z)`, `get_normal_at(x, z)`, `get_mask_at(x, z)`, `is_land_at(x, z)`, `is_inside(x, z)`;
- `heights`, `land_mask`, `min_height`, `max_height`, `size`, `cell_size`, dimensioni della griglia;
- `generation_seed`, `config_checksum`, `heights_checksum`, `ALGORITHM_VERSION`.

Serve per posizionare oggetti, punti di spawn o acqua senza dipendere dalla mesh. Va considerato di sola lettura.

## Limiti della v0.1

- La generazione avviene sul thread principale e non è divisa in chunk: una mesh, una shape di collisione.
- Solo runtime: nell'editor non viene generato niente nella viewport.
- Niente laghi, fiumi, grotte o erosione; il colore viene dai vertex colors (nessuna texture o shader custom).
- Il determinismo è garantito sulla stessa piattaforma e versione di Godot; tra piattaforme diverse è un obiettivo, non una garanzia.

## Demo e test

Si trovano nel progetto del modulo, non nell'addon: `demo/uptg_demo.tscn` mostra il generatore con controlli del seed, wireframe e sfere che cadono; `documentation/TESTING.it.md` spiega come eseguire i test e il benchmark.
