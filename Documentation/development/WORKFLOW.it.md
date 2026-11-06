[English](WORKFLOW.md) | **Italiano**

# Workflow di sviluppo

## Branch

- `main`: solo lavoro stabile e revisionato.
- Branch di funzionalità: `<modulo>/<breve-descrizione>`, per esempio `uptg/milestone-a-minimal-terrain`.
- Branch di sola documentazione: `docs/<breve-descrizione>`.

Si unisce in `main` tramite pull request, dopo aver verificato la modifica in Godot 4.7.2.

## Commit

Messaggi brevi all'imperativo, con il prefisso del modulo quando serve. I messaggi di commit restano in inglese:

```
UPTG: add UPTGConfig resource
docs: update testing procedure
```

## Versionamento

- Ogni modulo ha la propria versione semantica e il proprio `CHANGELOG.md`.
- I rilasci si taggano come `<modulo>-v<versione>`, per esempio `uptg-v0.1.0`.
- Il `CHANGELOG.md` nella radice registra le modifiche a livello di repository.

## Ciclo di una milestone

1. Esaminare i file esistenti e le convenzioni.
2. Proporre il piano e identificare i rischi; attendere l'approvazione quando sono coinvolti l'architettura o file esistenti.
3. Implementare a piccoli passi.
4. Verificare la sintassi ed eseguire la scena demo in Godot 4.7.2.
5. Aggiornare i documenti: README del modulo, `TESTING.md`, `CHANGELOG.md`.
6. Elencare i file creati o modificati, i test effettivamente eseguiti e i limiti noti.
7. Proporre la milestone successiva senza avviarla automaticamente.

## Documentazione bilingue

Ogni documento esiste in inglese (`NOME.md`) e in italiano (`NOME.it.md`). Quando si modifica uno dei due, si aggiorna anche l'altro nello stesso commit.

## Asset binari pesanti

I sorgenti Blender (`.blend`) e le texture grandi potranno in futuro passare a Git LFS. Fino ad allora, tenere gli asset binari piccoli e, quando possibile, fuori dal repository.
