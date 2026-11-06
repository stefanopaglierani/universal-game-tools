[English](ADR-0002-uptg-heightmap-collision.md) | **Italiano**

# ADR-0002: Collisione UPTG: `HeightMapShape3D` come predefinita

**Stato:** Accettata
**Data:** 2026-11-06
**Modulo:** UPTG

## Contesto

Il terreno richiede una collisione statica. Il Draft 0.1 proponeva una trimesh concava, la forma più costosa per una griglia regolare.

## Opzioni considerate

1. Solo `ConcavePolygonShape3D` (trimesh): esatta per qualsiasi triangolazione / più memoria e tempo di costruzione.
2. `HeightMapShape3D`: pensata per le griglie, meno costosa / triangolazione fissa e campioni distanziati di 1 unità.

## Decisione

`collision_mode` in `UPTGConfig`: `HEIGHTMAP` (predefinito), `TRIMESH`, `NONE`. I dati della heightmap sono le altezze divise per `cell_size` e il `CollisionShape3D` riceve una scala uniforme pari a `cell_size`. Deciso da Stefano, 2026-11-06.

## Conseguenze

Risultati della Milestone 0 (Godot 4.7.2, Godot Physics e Jolt): la shape è centrata sull'origine, `map_data` segue l'ordine `iz * width + ix`, ogni cella è divisa lungo la diagonale dal vertice `(ix+1, iz)` al vertice `(ix, iz+1)` e la scala uniforme funziona. Errore massimo rispetto all'interpolazione sui triangoli: 0.19 mm, quindi la tolleranza di 1 cm è confermata. La mesh e `get_height_at()` devono usare la stessa diagonale; con `backface_collision` disattivato le facce della trimesh devono essere orarie viste dall'alto. Vedi `M0_VERIFICATION.it.md`.

Fonte: `UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.md`
