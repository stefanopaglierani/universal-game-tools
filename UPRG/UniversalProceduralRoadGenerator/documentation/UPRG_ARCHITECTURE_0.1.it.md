[English](UPRG_ARCHITECTURE_0.1.md) | **Italiano**

# UPRG — Architettura 0.1

**Stato:** prima versione, secondo l'indicazione di Stefano del 2026-11-08 (ADR-0009, ADR-0010)
**Motore:** Godot 4.7.2

## 1. Flusso

```text
bake UPTG (.scn) ──► bake UPRG (strade, modifica del terreno) ──► file del mondo (.scn) ──► gioco
```

UPRG legge solo il file scritto da UPTG, formato 1 (metadati `terrain_data`, `Mesh`, `Body/Shape`). Non contiene codice UPTG e non modifica mai il file di ingresso.

## 2. Descrizione della strada

`UPRGRoadConfig` è una risorsa `.tres`: punti di controllo in metri dal centro del terreno, `width`, `shoulder`, `blend`, `sample_spacing`, `max_grade`, `smoothing`, `sea_clearance`, `sink`, `uv_length`, `road_color`.

## 3. Passaggi

1. **Percorso:** curva Catmull-Rom attraverso i punti, ricampionata ogni `sample_spacing` metri.
2. **Profilo delle altezze:** altezza del terreno lungo il percorso, mediata su `smoothing`, tenuta `sea_clearance` sopra il mare, limitata a `max_grade` nei due sensi.
3. **Modifica del terreno:** i vertici sotto carreggiata e banchina vanno all'altezza della strada meno `sink`; in `blend` metri il terreno torna alla sua forma. Mesh, normali e collisione height map sono ricostruite dalle altezze modificate.
4. **Superficie stradale:** una striscia con 4 punti per sezione (banchina esterna, due bordi della carreggiata, banchina esterna), in senso orario vista dall'alto, con una `ConcavePolygonShape3D` fatta degli stessi triangoli.

## 4. Risultato

La radice mantiene `terrain_data` con le `heights` modificate, un nuovo `heights_checksum`, `source_heights_checksum`, `roads_format_version` (1) e `roads` (percorso, altezze, larghezza e passo di ogni strada). Le strade sono in `Roads/Road<n>`, ciascuna con `Body/Shape`. Il file non ha script né dipendenze esterne.

## 5. Limiti noti

- I bordi della strada seguono la griglia del terreno, quindi appaiono seghettati dove la griglia è rada rispetto alla strada.
- Incroci e innesti non sono gestiti: una strada successiva modifica solo il terreno sotto di sé.
- I colori della strada sono uniformi; texture e skin sono una milestone successiva.
- È supportata solo la collisione del terreno `HEIGHTMAP`.
- La strada va dove indicano i punti: nessun percorso automatico.
