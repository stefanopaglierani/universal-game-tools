[English](TESTING.md) | **Italiano**

# Test di UPRG

Dalla cartella del modulo:

```
godot --headless --editor --quit
godot --headless --path . -s res://tests/run_tests.gd
```

`tests/test_roads.gd` e `tests/test_world.gd` costruiscono un terreno esportato sintetico, quindi non richiedono codice UPTG. `test_world.gd` controlla modifiche al terreno, luoghi, facce degli edifici, skin e input rifiutati. Controlla il passo del percorso, `max_grade`, il terreno sotto la strada e lontano da essa, mesh e collisione rispetto alle altezze modificate, il verso dei triangoli della strada, un risultato autonomo e gli input rifiutati. Il codice d'uscita è `0` quando ogni controllo passa.

`tests/test_dressing.gd` costruisce una propria piccola libreria di modelli e controlla come i modelli vengono scelti e collocati, il file dei crediti e il rifiuto di una libreria mancante.

`tests/test_network.gd` controlla gli incroci (attraversamenti, incroci a T, superfici unite alle strade, altezze, pendenze, input rifiutati) e le strade interne ai luoghi (collegamenti, edifici lontani dalle strade).

`tests/test_tiles.gd` controlla le tessere (livelli di dettaglio, bordi comuni, collisione, cosa resta nel file del mondo, dimensioni rifiutate).

`tests/test_loops.gd` controlla gli anelli (punto di chiusura, pendenze, superficie senza buchi, strade che finiscono su un anello).

Per vedere un risultato: `godot --path . res://demo/uprg_viewer.tscn -- --file=<mondo.scn>`.
