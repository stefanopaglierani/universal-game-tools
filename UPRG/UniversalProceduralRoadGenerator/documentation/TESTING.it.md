[English](TESTING.md) | **Italiano**

# Test di UPRG

Dalla cartella del modulo:

```
godot --headless --editor --quit
godot --headless --path . -s res://tests/run_tests.gd
```

`tests/test_roads.gd` costruisce un terreno esportato sintetico, quindi non richiede codice UPTG. Controlla il passo del percorso, `max_grade`, il terreno sotto la strada e lontano da essa, mesh e collisione rispetto alle altezze modificate, il verso dei triangoli della strada, un risultato autonomo e gli input rifiutati. Il codice d'uscita è `0` quando ogni controllo passa.

Per vedere un risultato: `godot --path . res://demo/uprg_viewer.tscn -- --file=<mondo.scn>`.
