class_name UPWGI18n
extends RefCounted
## The languages of the editor. The texts in the code are English; this file gives each one in
## Italian. Godot translates buttons, labels and tooltips by itself once the language is set;
## texts built while the editor runs go through tr().

const SETTINGS_PATH := "user://upwg_settings.cfg"
const LANGUAGES := ["en", "it"]

const ITALIAN := {
	# Top bar and tabs
	"New": "Nuovo",
	"Start a new world": "Inizia un mondo nuovo",
	"Open": "Apri",
	"Open a world you saved": "Apri un mondo che hai salvato",
	"Save": "Salva",
	"Save your world (Ctrl+S)": "Salva il tuo mondo (Ctrl+S)",
	"Export": "Esporta",
	"Make the files for a game or another program": "Crea i file per un gioco o un altro programma",
	"Undo": "Annulla",
	"Take back the last change (Ctrl+Z)": "Togli l'ultima modifica (Ctrl+Z)",
	"Redo": "Ripeti",
	"Put it back (Ctrl+Y)": "Rimettila (Ctrl+Y)",
	"Create": "Crea",
	"Make the world: its size, land and mountains": "Fai il mondo: grandezza, terra e montagne",
	"Edit": "Modifica",
	"Shape the ground and add water with the mouse": "Modella il terreno e aggiungi l'acqua con il mouse",
	"Change the language": "Cambia lingua",
	"Help": "Aiuto",
	"How to use the editor": "Come si usa l'editor",
	# View buttons
	"Come closer": "Avvicinati",
	"Go farther": "Allontanati",
	"See the whole world": "Guarda tutto il mondo",
	"Look from the sky": "Guarda dal cielo",
	# Tools
	"New world": "Mondo nuovo",
	"Land": "Terra",
	"Mountains": "Montagne",
	"Start over": "Ricomincia",
	"Look": "Guarda",
	"Raise": "Alza",
	"Dig": "Scava",
	"Smooth": "Leviga",
	"Flatten": "Spiana",
	"Bumpy": "Rocce",
	"Lake": "Lago",
	"River": "Fiume",
	"Pick a world to start from, and how big it is.": "Scegli il mondo da cui partire e quanto è grande.",
	"Change the shape of the land and its hills.": "Cambia la forma della terra e delle colline.",
	"Add big mountains and move them around.": "Aggiungi grandi montagne e spostale.",
	"Remove your work and start again.": "Togli il tuo lavoro e ricomincia.",
	"Drag with the left button to turn around the world. Wheel to come closer.": "Trascina con il tasto sinistro per girare intorno al mondo. Rotellina per avvicinarti.",
	"Hold the left button and move: the ground goes up. Hold Ctrl to dig.": "Tieni premuto il tasto sinistro e muoviti: il terreno sale. Tieni premuto Ctrl per scavare.",
	"Hold the left button and move: the ground goes down. Hold Ctrl to raise.": "Tieni premuto il tasto sinistro e muoviti: il terreno scende. Tieni premuto Ctrl per alzare.",
	"Paint to make the ground soft and round.": "Dipingi per rendere il terreno morbido e arrotondato.",
	"Paint to make the ground flat, at the height where you start.": "Dipingi per rendere il terreno piatto, all'altezza da cui parti.",
	"Paint to make the ground bumpy, like rocks.": "Dipingi per rendere il terreno ruvido, come rocce.",
	"Click to make a lake. It works on mountains too! Ctrl + click removes the closest water.": "Clicca per fare un lago. Funziona anche sulle montagne! Ctrl + clic toglie l'acqua più vicina.",
	"Click the points of the river, from the start to the sea. Right-click or Enter to finish, Esc to cancel.": "Clicca i punti del fiume, dalla sorgente al mare. Tasto destro o Invio per finire, Esc per annullare.",
	# World section
	"World": "Mondo",
	"Choose a world to start": "Scegli un mondo per iniziare",
	"Island": "Isola",
	"Continent": "Continente",
	"Coast": "Costa",
	"Highlands": "Altopiano",
	"Flat land": "Pianura",
	"Start a new world like this": "Inizia un mondo nuovo come questo",
	"Surprise me!": "Sorprendimi!",
	"A new world of the same kind, different every time": "Un mondo nuovo dello stesso tipo, ogni volta diverso",
	"How big?": "Quanto grande?",
	"Small": "Piccolo",
	"Medium": "Medio",
	"Big": "Grande",
	"Huge": "Enorme",
	"Giant": "Gigante",
	"More options": "Altre opzioni",
	"World number": "Numero del mondo",
	"The number that makes this world. The same number gives the same world.": "Il numero che crea questo mondo. Lo stesso numero dà lo stesso mondo.",
	"Size (m)": "Grandezza (m)",
	"Detail (m per square)": "Dettaglio (m per quadretto)",
	# Land section
	"The land": "La terra",
	"Hills: how high": "Colline: quanto alte",
	"Hills: how wide": "Colline: quanto larghe",
	"Land above the sea": "Terra sopra il mare",
	"Island: how big": "Isola: quanto grande",
	"Coast: where": "Costa: dove",
	"Coast: how wiggly": "Costa: quanto frastagliata",
	"Sea: how deep (m)": "Mare: quanto profondo (m)",
	# Mountains section
	"How many": "Quante",
	"One less": "Una in meno",
	"One more": "Una in più",
	"How high (m)": "Quanto alte (m)",
	"How wide": "Quanto larghe",
	"Move the mountains": "Sposta le montagne",
	"Put the mountains in other places": "Metti le montagne in altri posti",
	"Tip: in Edit, the Raise tool makes your own mountains where you want.": "Consiglio: in Modifica, lo strumento Alza crea le tue montagne dove vuoi.",
	# Start over section
	"Remove my brush work and water": "Togli il mio lavoro col pennello e l'acqua",
	"The land goes back to how it was made": "La terra torna com'era all'inizio",
	"A flat world": "Un mondo piatto",
	"Start again from flat land": "Ricomincia da una pianura",
	# Look section
	"Look around": "Guardati intorno",
	"Left button: turn around the world.\nRight button + W A S D: fly like a bird. Q and E: down and up. Shift: faster.\nWheel: come closer to what is under the mouse.\nF: fly to the point under the mouse.": "Tasto sinistro: gira intorno al mondo.\nTasto destro + W A S D: vola come un uccello. Q ed E: giù e su. Shift: più veloce.\nRotellina: avvicinati a quello che c'è sotto il mouse.\nF: vola fino al punto sotto il mouse.",
	# Brush section
	"Brush": "Pennello",
	"Size": "Grandezza",
	"Strength": "Forza",
	"Soft edge": "Bordo morbido",
	"Shape": "Forma",
	"Round brush": "Pennello rotondo",
	"Square brush": "Pennello quadrato",
	"Both": "Entrambi",
	"Only lower": "Solo abbassa",
	"Only raise": "Solo alza",
	"Always the same height": "Sempre la stessa altezza",
	"Off: the height where you start. On: the height written here.": "Spento: l'altezza da cui parti. Acceso: l'altezza scritta qui.",
	"Height": "Altezza",
	# Water section
	"Water": "Acqua",
	"Lake size (m)": "Grandezza del lago (m)",
	"Water depth (m)": "Profondità dell'acqua (m)",
	"The river goes where you click. It always flows down.": "Il fiume passa dove clicchi. Scende sempre verso il basso.",
	# Dialogs
	"Yes": "Sì",
	"No": "No",
	"What do you want to make?": "Cosa vuoi creare?",
	"Godot: one scene file": "Godot: un solo file di scena",
	"Godot: pieces for big worlds": "Godot: pezzi per mondi grandi",
	"Heightmap images (Unity, Unreal, Blender)": "Immagini delle altezze (Unity, Unreal, Blender)",
	"3D model glTF (any program)": "Modello 3D glTF (qualsiasi programma)",
	"Choose the folder and export": "Scegli la cartella ed esporta",
	"1. Create: pick a world, its size, the land and the mountains.\n2. Edit: choose a tool and paint on the world with the left button.\n\nRight button + W A S D: fly.  Wheel: come closer.\nCtrl: Raise digs, Dig raises.  Shift: smooth.\nB + mouse or wheel: brush size.  Shift + B: strength.\nF: fly to the mouse.  1 to 8: tools.\nCtrl+Z: undo.  Ctrl+Y: redo.  Ctrl+S: save.": "1. Crea: scegli un mondo, la grandezza, la terra e le montagne.\n2. Modifica: scegli uno strumento e dipingi sul mondo con il tasto sinistro.\n\nTasto destro + W A S D: vola.  Rotellina: avvicinati.\nCtrl: Alza scava, Scava alza.  Shift: leviga.\nB + mouse o rotellina: grandezza del pennello.  Shift + B: forza.\nF: vola fino al mouse.  Da 1 a 8: strumenti.\nCtrl+Z: annulla.  Ctrl+Y: ripeti.  Ctrl+S: salva.",
	# Messages
	"Right button + W A S D: fly   ·   Wheel: closer   ·   B + mouse: brush size   ·   Ctrl+Z: undo": "Tasto destro + W A S D: vola   ·   Rotellina: avvicinati   ·   B + mouse: grandezza del pennello   ·   Ctrl+Z: annulla",
	"Do you want to continue the world you were making last time?": "Vuoi continuare il mondo che stavi facendo l'ultima volta?",
	"A new world! Now change it with the tools on the left.": "Un mondo nuovo! Ora cambialo con gli strumenti a sinistra.",
	"This file is not a UPWG world: %s": "Questo file non è un mondo UPWG: %s",
	"Opened %s.": "Aperto %s.",
	"Saved %s.": "Salvato %s.",
	"Could not save %s (error %d).": "Non è stato possibile salvare %s (errore %d).",
	"Building the world and writing the files... big worlds take a few minutes.": "Sto costruendo il mondo e scrivendo i file... i mondi grandi richiedono qualche minuto.",
	"Done! %d files written to %s in %.0f seconds.": "Fatto! %d file scritti in %s in %.0f secondi.",
	"The export did not work: %s": "L'esportazione non è riuscita: %s",
	"This terrain cannot be built: %s": "Questo terreno non si può costruire: %s",
	"This terrain cannot be built.": "Questo terreno non si può costruire.",
	"The water cannot go here: it is too close to the edge of the world.": "L'acqua non può andare qui: è troppo vicina al bordo del mondo.",
	"Lake added! Ctrl+Z takes it away.": "Lago aggiunto! Ctrl+Z lo toglie.",
	"River added! Ctrl+Z takes it away.": "Fiume aggiunto! Ctrl+Z lo toglie.",
	"There is no water to remove.": "Non c'è acqua da togliere.",
	"Water removed. Ctrl+Z brings it back.": "Acqua tolta. Ctrl+Z la rimette.",
	"There is nothing to undo.": "Non c'è niente da annullare.",
	"Undone.": "Annullato.",
	"There is nothing to redo.": "Non c'è niente da ripetere.",
	"Redone.": "Ripetuto.",
	"All your brush work and water are gone. The land is as it was made.": "Il lavoro col pennello e l'acqua sono stati tolti. La terra è com'era all'inizio.",
	"Remove all your brush work, lakes and rivers?": "Vuoi togliere tutto il lavoro col pennello, i laghi e i fiumi?",
	"The world is %.1f km from side to side, with squares of %.1f m.": "Il mondo è largo %.1f km, con quadretti da %.1f m.",
	"Start a new world? What you made and did not save will be lost.": "Iniziare un mondo nuovo? Quello che hai fatto e non hai salvato andrà perso.",
	"Open another world? What you made and did not save will be lost.": "Aprire un altro mondo? Quello che hai fatto e non hai salvato andrà perso.",
	"Your world is not saved. Close anyway? A copy is kept and offered next time.": "Il tuo mondo non è salvato. Vuoi chiudere lo stesso? Una copia viene tenuta e ti verrà proposta la prossima volta.",
	"River: %d points. Right-click or Enter when it reaches the end.": "Fiume: %d punti. Tasto destro o Invio quando arriva alla fine.",
	"A river needs at least 2 points.": "Un fiume ha bisogno di almeno 2 punti.",
}

static var _installed := false


## Adds the Italian translation and sets the saved language (the system's one the first time).
static func install() -> void:
	if not _installed:
		var italian := Translation.new()
		italian.locale = "it"
		for english: String in ITALIAN:
			italian.add_message(english, ITALIAN[english])
		TranslationServer.add_translation(italian)
		_installed = true
	TranslationServer.set_locale(saved_language())


static func saved_language() -> String:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		var language: String = settings.get_value("editor", "language", "")
		if language in LANGUAGES:
			return language
	return "it" if OS.get_locale_language() == "it" else "en"


static func set_language(language: String) -> void:
	TranslationServer.set_locale(language)
	var settings := ConfigFile.new()
	settings.load(SETTINGS_PATH)
	settings.set_value("editor", "language", language)
	settings.save(SETTINGS_PATH)
