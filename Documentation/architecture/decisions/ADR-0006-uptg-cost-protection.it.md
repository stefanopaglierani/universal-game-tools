[English](ADR-0006-uptg-cost-protection.md) | **Italiano**

# ADR-0006: Protezione di UPTG da configurazioni troppo costose

**Stato:** Accettata
**Data:** 2026-11-06
**Modulo:** UPTG

## Contesto

La generazione è GDScript sincrono sul thread principale. Una griglia grande in un preset, un errore di battitura o una modifica a runtime potrebbero bloccare il gioco o l'editor o esaurire la memoria.

## Opzioni considerate

1. Solo documentare i limiti: nessun codice / nessuna protezione.
2. Rifiuto rigido oltre una dimensione: semplice / blocca anche terreni grandi legittimi.
3. Stima dei costi prima della generazione con tre livelli, terreni grandi permessi solo da un flag esplicito sul nodo: sicuro per impostazione predefinita e flessibile / le stime vanno calibrate.

## Decisione

Opzione 3 (architettura §5.4). `UPTGConfig.estimate_cost()` restituisce celle, vertici, triangoli, campioni di noise, byte stimati e un livello: `OK`, `LARGE` (rifiutato salvo `UPTGTerrain.allow_large_terrain` attivo) o `REJECTED` (sempre rifiutato). Il flag sta sul nodo, quindi un preset condiviso non può aggirarlo. `TRIMESH` ha una soglia più bassa. `generate()` non è rientrante. Deciso da Stefano, 2026-11-06.

## Conseguenze

Le soglie sono costanti nominate; i coefficienti di memoria e le soglie di tempo sono stime da calibrare con misure reali in Milestone D, con approvazione.

Fonte: `UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.md`
