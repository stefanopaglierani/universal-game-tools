[English](ADR-0012-uprg-terrain-tiles.md) | **Italiano**

# ADR-0012: I mondi molto grandi si tagliano in tessere di terreno dopo il bake

**Stato:** Accettata
**Data:** 2026-11-10
**Modulo:** UPRG

## Contesto

Un mondo cinque volte più largo della prima isola ha 2,1 milioni di triangoli di terreno: troppi in un solo pezzo per un telefono di fascia media. Stefano ha scelto un unico grande mondo collegato il 2026-11-09, e il suo caricamento andava provato prima sul suo telefono.

## Opzioni considerate

1. Generare il terreno direttamente a tessere dentro UPTG: nessuna mesh intera / cambia UPTG e il suo contratto dei dati.
2. Tagliare in tessere un file del mondo finito, in UPRG: UPTG invariato, ogni funzione di UPRG resta com'è / la mesh intera esiste per un momento sul PC.

## Decisione

Opzione 2, con tessere quadrate (64 celle da 5 m nel mondo di esempio), una mesh leggera oltre 480 m, bordi verticali contro i buchi e una collisione ad altezze per tessera. Tutto il resto resta in `world.scn`. Stefano ha provato il risultato sul suo telefono il 2026-11-10 e l'ha approvato.

## Conseguenze

Qualsiasi mondo esportato si può tagliare a tessere. La grandezza resta limitata dalle 1024 celle per lato di UPTG. Un gioco ha bisogno di codice che carichi le tessere; non fa parte di UPRG.

Fonte: `UPRG/UniversalProceduralRoadGenerator/documentation/UPRG_ARCHITECTURE_0.2.it.md`
