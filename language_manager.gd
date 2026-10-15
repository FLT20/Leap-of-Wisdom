extends Node
## ======================================================================
##  GESTOR DE IDIOMA  (Autoload / Singleton)
## ======================================================================
##  Única fuente de verdad para el IDIOMA activo y para los textos cortos
##  de la interfaz (botones, títulos, marcadores, mensajes...).
##
##  Uso desde cualquier script:
##    LanguageManager.t("btn_jugar")                 -> texto traducido
##    LanguageManager.t("score_max") % 12            -> texto con formato
##    LanguageManager.idioma_actual                  -> Idioma.ESPANOL/INGLES
##    LanguageManager.idioma_cambiado.connect(mi_fn) -> aviso al cambiar
##
##  Las FRASES largas y motivadoras viven en frases.gd y consultan aquí
##  el idioma activo (ver Frases.obtener()).
## ======================================================================

enum Idioma { ESPANOL, INGLES }

## Se emite cada vez que el jugador cambia de idioma.
signal idioma_cambiado(nuevo_idioma: int)

## Idioma activo ahora mismo. Empieza en español.
var idioma_actual: int = Idioma.ESPANOL


## Tabla de textos de la interfaz:  clave -> { "es": ..., "en": ... }
const TEXTOS := {
	"titulo_juego": {
		"es": "Salto de Sabiduría",
		"en": "Leap of Wisdom",
	},
	"subtitulo": {
		"es": "Salta de madera en madera y sube lo más alto que puedas",
		"en": "Jump from log to log and climb as high as you can",
	},
	"btn_jugar": {"es": "JUGAR", "en": "PLAY"},
	"btn_salir": {"es": "SALIR", "en": "QUIT"},
	"btn_idioma": {"es": "Idioma", "en": "Language"},
	"titulo_idioma": {
		"es": "Selecciona un idioma",
		"en": "Select a language",
	},
	"btn_cerrar": {"es": "Cerrar", "en": "Close"},

	# Marcador de altura (usa %d para el número de metros).
	"score_max": {
		"es": "Altura máxima: %d m",
		"en": "Max Height: %d m",
	},
	"score_actual": {
		"es": "Actual: %d m",
		"en": "Current: %d m",
	},

	# Pantalla de Game Over.
	"gameover_titulo": {
		"es": "¡GAME OVER!",
		"en": "GAME OVER!",
	},
	"gameover_pista": {
		"es": "Pulsa cualquier tecla para reintentar",
		"en": "Press any key to retry",
	},

	# Menú de pausa.
	"pausa_titulo": {"es": "PAUSA", "en": "PAUSE"},
	"pausa_continuar": {"es": "CONTINUAR", "en": "RESUME"},
	"pausa_reiniciar": {"es": "REINICIAR", "en": "RESTART"},
	"pausa_menu": {"es": "MENÚ", "en": "MENU"},

	# Burbuja de diálogo (texto por defecto).
	"burbuja_inicio": {
		"es": "¡Hola! Pulsa M para hablar.",
		"en": "Hi! Press M to talk.",
	},
}


## Cambia el idioma si es distinto del actual y avisa a toda la interfaz.
func cambiar_idioma(nuevo_idioma: int) -> void:
	if nuevo_idioma == idioma_actual:
		return
	idioma_actual = nuevo_idioma
	idioma_cambiado.emit(idioma_actual)


## Devuelve el texto traducido de una clave. Si no existe, avisa y
## devuelve la propia clave (fallback visible para detectar errores).
func t(clave: String) -> String:
	var entrada: Dictionary = TEXTOS.get(clave, {})
	if entrada.is_empty():
		push_warning("LanguageManager: clave sin traducir -> '%s'" % clave)
		return clave
	var texto: String = entrada["en"] if idioma_actual == Idioma.INGLES else entrada["es"]
	return texto


## Código corto del idioma ("es" / "en"). Lo usan las frases motivadoras.
func codigo_idioma() -> String:
	return "en" if idioma_actual == Idioma.INGLES else "es"
