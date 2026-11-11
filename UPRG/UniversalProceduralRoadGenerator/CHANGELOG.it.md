[English](CHANGELOG.md) | **Italiano**

# Changelog di UPRG

## [Non rilasciato]

### Aggiunto
- Strade sui terreni esportati da UPTG: percorso curvo dai punti di controllo, profilo delle altezze con limite di pendenza, spianamento del terreno con raccordo, superficie stradale e collisione.
- Strumento di bake da riga di comando, visualizzatore del mondo, strada di esempio e suite di test.
- Descrizione del mondo in un unico file `.tres`: modifiche al terreno (`ADD`, `LEVEL`), luoghi con edifici e skin con immagini salvate nel file del mondo.
- Modelli 3D nei mondi: libreria leggera costruita da una cartella di modelli, edifici da modelli, alberi, piante e rocce sparsi, oggetti a bordo strada, collisioni semplici, distanze di visibilità e un file dei crediti scritto con ogni mondo.
- Incroci: le strade che si attraversano o finiscono l'una sull'altra si incontrano alla stessa altezza, su una superficie comune con angoli arrotondati.
- Strade interne ai luoghi, collegate alla strada più vicina, con gli edifici lungo di esse e rivolti verso la strada.
- Tessere per mondi molto grandi: `tools/uprg_tiles.gd` scrive tessere di terreno con due livelli di dettaglio e collisione, e un mondo di esempio cinque volte più largo.
- `--road-colors` per le tessere: il rosso dei colori dei vertici segna il terreno vicino alle strade.
- Livelli di dettaglio: la libreria dei modelli conserva fino a sei versioni più leggere di ogni modello, e il motore le sceglie in base alla distanza. `UPRGDressing.chunk_size` decide come vengono raggruppati gli oggetti.
- Il mondo di esempio x5 ha due villaggi con le vie, alberi, rocce e arredi a bordo strada.
- Strade chiuse (`UPRGRoadConfig.closed`): un anello che torna al primo punto, con una chiusura morbida e gli incroci lontani da essa. Il mondo di esempio x5 ha il circuito Costa ad anello sulla costa ovest, collegato all'anello principale da una strada.

### Corretto
- Le pendenze si arrotondano solo vicino agli incroci, così il resto di ogni strada mantiene il suo profilo.

### Corretto
- Le parti dei modelli fatte di linee o punti non entrano più nella libreria dei modelli.

### Modificato
- I bordi della strada restano puliti su una griglia del terreno rada.
