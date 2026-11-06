[English](ADR-0004-uptg-seed-and-determinism.md) | **Italiano**

# ADR-0004: Gestione del seed e garanzia di determinismo di UPTG

**Stato:** Accettata
**Data:** 2026-11-06
**Modulo:** UPTG

## Contesto

La generazione deve essere riproducibile da un seed. Usare un solo seed per tutti i livelli di noise li rende correlati, `seed` oscura una funzione globale di GDScript e `FastNoiseLite` memorizza il seed a 32 bit.

## Opzioni considerate

1. Un solo seed per tutto: semplice / livelli correlati, conflitto di nome.
2. `generation_seed` più sub-seed per fase da un hash intero documentato, solo RNG locali: livelli indipendenti, stabile tra versioni del motore / poco codice da mantenere.

## Decisione

Opzione 2. `generation_seed` è limitato a 0–2147483647; i sub-seed derivano da `derive(seed, salt)` (architettura §7.2) con salt fissi; le funzioni RNG globali sono vietate nell'addon; `String.hash()`/`hash()` non vengono usate. Garanzia: output identico con stessa configurazione, seed, build di Godot e piattaforma; l'identità tra piattaforme è un obiettivo, non una garanzia. `ALGORITHM_VERSION` è registrato nei dati del terreno. Deciso da Stefano, 2026-11-06.

## Conseguenze

La Milestone 0 ha confermato il limite a 31 bit (un seed di 3000000000 diventa -1294967296 in `FastNoiseLite`) e che l'implementazione GDScript di `derive()` coincide con quattro test vector calcolati in modo indipendente.

Fonte: `UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.md`
