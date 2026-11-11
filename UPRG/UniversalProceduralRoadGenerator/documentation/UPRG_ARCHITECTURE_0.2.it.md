[English](UPRG_ARCHITECTURE_0.2.md) | **Italiano**

# UPRG — Architettura 0.2

**Stato:** descrive UPRG 0.1.0 (2026-11-11). Sostituisce l'[architettura 0.1](UPRG_ARCHITECTURE_0.1.it.md), conservata come storia.
**Motore:** Godot 4.7.2

## 1. Flusso

```text
bake UPTG (.scn) ──► bake UPRG (world.tres) ──► file del mondo (.scn) ──► tessere facoltative ──► gioco
```

UPRG legge solo il file scritto da UPTG (formato 1, ADR-0010), non contiene codice UPTG e non modifica mai il file di partenza. `UPRGWorldConfig` descrive un mondo intero in un unico file `.tres`. Il bake applica, in quest'ordine:

1. modifiche al terreno (`UPRGTerrainEdit`);
2. livellamento dei luoghi (`UPRGPlace`);
3. piani delle strade (`UPRGRoadConfig`), con gli anelli fatti partire lontano da tutto il resto;
4. vie dei luoghi che le richiedono;
5. la rete degli incroci (ADR-0011), che fissa le altezze dove le strade si incontrano;
6. un'unica modifica del terreno per tutte le strade, poi mesh, normali e collisione ricostruite;
7. superfici di strade e incroci, edifici e modelli 3D (`UPRGDressing`);
8. il file del mondo, più un file dei crediti quando ci sono modelli.

## 2. Strade

- **Percorso:** una curva Catmull-Rom tra i punti di controllo, ricampionata ogni `sample_spacing` metri. Con `closed` la curva torna al primo punto e l'ultima posizione ripete la prima (ADR-0013).
- **Profilo delle altezze:** altezza del terreno lungo il percorso, mediata su `smoothing`, tenuta `sea_clearance` sopra il mare, limitata a `max_grade`. Sugli anelli media e limite girano attorno al punto di chiusura.
- **Modifica del terreno:** sotto carreggiata, banchina e 1,5 celle il terreno va all'altezza della strada meno `sink`, e in `blend` metri torna alla sua forma. Dove più strade toccano lo stesso vertice vince quella che lo cambia di meno. Dove una strada piega verso l'alto vicino a un incrocio, il terreno scende di più, così non può bucare l'asfalto.
- **Superficie:** 4 punti per sezione, in senso orario visti dall'alto, con una `ConcavePolygonShape3D` fatta degli stessi triangoli.

## 3. Incroci

Gli attraversamenti, e le strade che finiscono entro mezza carreggiata da un'altra, diventano incroci (ADR-0011). Le strade si incontrano alla stessa altezza; quella elencata per prima mantiene la sua. Un incrocio sostituisce i campioni di strada vicini con un'unica superficie ad angoli arrotondati, che condivide i punti del bordo con le estremità delle strade. Vicino a un incrocio la pendenza cresce gradualmente, e solo lì il profilo viene arrotondato. Incontri più stretti di 25 gradi e incroci troppo vicini sulla stessa strada vengono rifiutati con un messaggio. Con `UPRGWorldConfig.connected_roads`, una strada non raggiungibile attraverso gli incroci ferma il bake indicandola.

## 4. Luoghi e vie

`UPRGPlace` livella il suo terreno. Senza vie, gli edifici stanno su una griglia mescolata di lotti lontani dalle strade. Con `streets`, una via principale si collega alla strada più vicina e da lì partono le vie laterali; gli edifici stanno lungo ogni via, rivolti verso di essa. Tutto segue il seed del luogo.

## 5. Modelli

`tools/uprg_library.gd` costruisce una libreria leggera da una cartella di modelli `.glb`/`.gltf` e da un catalogo: una mesh per oggetto, a grandezza reale, texture piccole e fino a sei livelli di dettaglio generati con `ImporterMesh`. `UPRGDressing` sparge alberi, piante, cespugli e rocce, mette lampioni e oggetti lungo le strade e costruisce i luoghi con i modelli. Gli oggetti ripetuti sono gruppi `MultiMesh` di `chunk_size` metri con distanze di visibilità. Ogni bake scrive i crediti dei modelli usati.

## 6. Tessere

`tools/uprg_tiles.gd` taglia un mondo esportato in tessere quadrate (ADR-0012): ogni tessera ha una mesh dettagliata, una leggera oltre 480 m, bordi verticali contro i buchi e la sua collisione ad altezze. Le tessere tutte sotto il mare non vengono scritte. Strade, luoghi, oggetti e dati restano in `world.scn`. Con `--road-colors` il rosso dei colori dei vertici dice quanto il terreno è vicino a una strada, per uno shader del gioco che disegna il terreno con le sue texture.

## 7. Risultato

La radice conserva `terrain_data`: le `heights` modificate (tolte con le tessere), i checksum, `roads` (percorso, altezze, larghezza, passo, `street`, `closed`), `junctions` (centro, altezza, raggio, strade, bracci), `places` e `tiles` quando ci sono le tessere. I file non hanno script né dipendenze esterne.

## 8. Limiti noti

- Tutti gli incroci sono a raso: niente ponti.
- Gli edifici guardano la loro via con l'asse +Z; i modelli con il fronte altrove guardano di lato.
- La griglia del terreno è limitata da UPTG a 1024 celle per lato.
- Un gioco ha bisogno di codice suo per caricare le tessere e dare le texture al terreno (previsto un lettore separato, vedi il piano del 2026-11-11).
