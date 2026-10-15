## =========================================================================
##  MENÚ PRINCIPAL  (pantalla de título, multi-idioma)
## =========================================================================
##  Es la primera escena que ve el jugador. Tiene:
##    - Título, subtítulo y botones JUGAR / SALIR (traducidos en vivo).
##    - Un botón IDIOMA que abre un cuadro emergente para elegir entre
##      Español / English. El idioma activo aparece deshabilitado.
##
##  Los textos viven en LanguageManager (Autoload). Este script solo los
##  coloca y escucha los cambios.
## =========================================================================
extends Control


# =========================================================================
#  REFERENCIAS
# =========================================================================
@onready var _titulo: Label = $Centro/Panel/Caja/Titulo
@onready var _subtitulo: Label = $Centro/Panel/Caja/Subtitulo
@onready var _btn_jugar: Button = $Centro/Panel/Caja/BotonJugar
@onready var _btn_salir: Button = $Centro/Panel/Caja/BotonSalir
@onready var _btn_idioma: Button = $Centro/Panel/Caja/BotonIdioma

@onready var _cuadro: Control = $CuadroIdioma
@onready var _cuadro_titulo: Label = $CuadroIdioma/Centro/Panel/Caja/Titulo
@onready var _cuadro_es: Button = $CuadroIdioma/Centro/Panel/Caja/BotonES
@onready var _cuadro_en: Button = $CuadroIdioma/Centro/Panel/Caja/BotonEN

## Ruta de la escena del juego (main.tscn).
const RUTA_JUEGO := "res://main.tscn"


func _ready() -> void:
	# Botones principales.
	_btn_jugar.pressed.connect(_on_jugar)
	_btn_salir.pressed.connect(_on_salir)

	# Abrir/cerrar el cuadro de idioma.
	_btn_idioma.pressed.connect(_abrir_cuadro_idioma)
	_cuadro_es.pressed.connect(_on_idioma_es)
	_cuadro_en.pressed.connect(_on_idioma_en)

	# Clic en el velo oscuro cierra el cuadro sin cambiar nada.
	_cuadro.get_node("Velo").gui_input.connect(_on_velo_input)

	# El botón de jugar empieza con el foco, para poder usar el teclado.
	_btn_jugar.grab_focus()

	# Refrescamos TODO el texto según el idioma activo y nos suscribimos a
	# futuros cambios (por si se vuelve al menú tras cambiar el idioma).
	_actualizar_textos()
	if not LanguageManager.idioma_cambiado.is_connected(_actualizar_textos):
		LanguageManager.idioma_cambiado.connect(_actualizar_textos)


# =========================================================================
#  CUADRO DE IDIOMA
# =========================================================================
func _abrir_cuadro_idioma() -> void:
	_cuadro.visible = true
	_cuadro_es.grab_focus()


## Cierra el cuadro si se hace clic fuera del panel (sobre el velo).
func _on_velo_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_cuadro.visible = false


# =========================================================================
#  IDIOMA
# =========================================================================
## Coloca cada texto en su nodo y habilita/deshabilita las opciones de
## idioma según cuál esté activo.
func _actualizar_textos(_nuevo_idioma: int = 0) -> void:
	_titulo.text = LanguageManager.t("titulo_juego")
	_subtitulo.text = LanguageManager.t("subtitulo")
	_btn_jugar.text = LanguageManager.t("btn_jugar")
	_btn_salir.text = LanguageManager.t("btn_salir")
	_btn_idioma.text = LanguageManager.t("btn_idioma")

	# Cuadro emergente.
	_cuadro_titulo.text = LanguageManager.t("titulo_idioma")

	# El idioma ACTIVO se deshabilita (no tiene sentido volver a pulsarlo).
	var activo := LanguageManager.idioma_actual
	_cuadro_es.disabled = (activo == LanguageManager.Idioma.ESPANOL)
	_cuadro_en.disabled = (activo == LanguageManager.Idioma.INGLES)


# =========================================================================
#  ACCIONES DE LOS BOTONES
# =========================================================================
func _on_jugar() -> void:
	# Cargamos la escena del juego.
	get_tree().change_scene_to_file(RUTA_JUEGO)


func _on_salir() -> void:
	# Cerramos la aplicación.
	get_tree().quit()


func _on_idioma_es() -> void:
	LanguageManager.cambiar_idioma(LanguageManager.Idioma.ESPANOL)
	_cuadro.visible = false
	_btn_jugar.grab_focus()


func _on_idioma_en() -> void:
	LanguageManager.cambiar_idioma(LanguageManager.Idioma.INGLES)
	_cuadro.visible = false
	_btn_jugar.grab_focus()
