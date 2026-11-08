[English](UPRG_ARCHITECTURE_0.1.md) | **Italiano**

# UPRG — Architettura 0.1

**Stato:** prima versione, secondo l'indicazione di Stefano del 2026-11-08 (ADR-0009, ADR-0010)
**Motore:** Godot 4.7.2

## 1. Flusso

```text
bake UPTG (.scn) ──► bake UPRG (strade, modifica del terreno) ──► file del mondo (.scn) ──► gioco
```

`UPRGWorldConfig` descrive tutto in un unico file `.tres`, applicato in quest'ordine: modifiche al terreno, terreno dei luoghi, strade, edifici. UPRG legge solo il file scritto da UPTG, formato 1 (metadati `terrain_data`, `Mesh`, `Body/Shape`). Non contiene codice UPTG e non modifica mai il file di ingresso.

## 2. Descrizione della strada

`UPRGRoadConfig` è una risorsa `.tres`: punti di controllo in metri dal centro del terreno, `width`, `shoulder`, `blend`, `sample_spacing`, `max_grade`, `smoothing`, `sea_clearance`, `sink`, `uv_length`, `road_color`.

## 3. Passaggi

1. **Percorso:** curva Catmull-Rom attraverso i punti, ricampionata ogni `sample_spacing` metri.
2. **Profilo delle altezze:** altezza del terreno lungo il percorso, mediata su `smoothing`, tenuta `sea_clearance` sopra il mare, limitata a `max_grade` nei due sensi.
3. **Modifica del terreno:** i vertici sotto carreggiata e banchina vanno all'altezza della strada meno `sink`; in `blend` metri il terreno torna alla sua forma. Mesh, normali e collisione height map sono ricostruite dalle altezze modificate.
4. **Superficie stradale:** una striscia con 4 punti per sezione (banchina esterna, due bordi della carreggiata, banchina esterna), in senso orario vista dall'alto, con una `ConcavePolygonShape3D` fatta degli stessi triangoli.

## 4. Modifiche al terreno, luoghi e skin

- **`UPRGTerrainEdit`:** un'area circolare con bordo morbido, `ADD` (alza o abbassa) o `LEVEL` (imposta un'altezza sopra il mare).
- **`UPRGPlace`:** livella il terreno alla sua altezza media, poi mette le case su una griglia di lotti mescolati con il seed del luogo. I lotti troppo vicini a una strada sono saltati, quindi gli edifici possono essere meno di quelli chiesti. Tutte le case di un luogo sono una sola mesh con una sola `ConcavePolygonShape3D`, in `Places/Place<n>`.
- **`UPRGSkin`:** immagini per strade, terreno ed edifici, salvate dentro il file, e tinte per terreno e strade.

Per ora i luoghi stanno in UPRG perché condividono la modifica del terreno e l'esportazione. Potranno passare a UPWG quando quel modulo partirà.

## 5. Risultato

La radice mantiene `terrain_data` con le `heights` modificate, un nuovo `heights_checksum`, `source_heights_checksum`, `roads_format_version` (1) e `roads` (percorso, altezze, larghezza e passo di ogni strada), e `places` (nome, centro, raggio, edifici). Le strade sono in `Roads/Road<n>`, ciascuna con `Body/Shape`. Il file non ha script né dipendenze esterne.

## 6. Limiti noti

- La fascia livellata accanto a una strada è più larga della strada di 1,5 celle del terreno, così il bordo resta pulito su una griglia rada.
- Gli edifici sono semplici volumi con tetto a due falde.
- Incroci e innesti non sono gestiti: una strada successiva modifica solo il terreno sotto di sé.
- È supportata solo la collisione del terreno `HEIGHTMAP`.
- La strada va dove indicano i punti: nessun percorso automatico.
