## =========================================================================
##  MENÚ DE PAUSA  (durante la partida, multi-idioma)
## =========================================================================
##  Se controla con la tecla ESC: pausa / reanuda el juego. Ofrece:
##    - CONTINUAR: vuelve al juego.
##    - REINICIAR: empieza la partida de nuevo.
##    - MENÚ: vuelve a la pantalla de título.
##    - ESPAÑOL / ENGLISH: cambia el idioma de TODO el juego en vivo.
##
##  Usa get_tree().paused para congelar el mundo. Este nodo tiene
##  process_mode = ALWAYS para seguir respondiendo (y poder despausar)
##  incluso con el juego en pausa.
## =========================================================================
extends Control

const RUTA_MENU := "res://menu.tscn"


# =========================================================================
#  REFERENCIAS
# =========================================================================
@onready var _titulo: Label = $Centro/Panel/Caja/Titulo
@onready var _btn_continuar: Button = $Centro/Panel/Caja/BotonContinuar
@onready var _btn_reiniciar: Button = $Centro/Panel/Caja/BotonReiniciar
@onready var _btn_menu: Button = $Centro/Panel/Caja/BotonMenu
@onready var _btn_idioma: Button = $Centro/Panel/Caja/BotonIdioma

@onready var _cuadro: Control = $CuadroIdioma
@onready var _cuadro_titulo: Label = $CuadroIdioma/Centro/Panel/Caja/Titulo
@onready var _cuadro_es: Button = $CuadroIdioma/Centro/Panel/Caja/BotonES
@onready var _cuadro_en: Button = $CuadroIdioma/Centro/Panel/Caja/BotonEN

## ¿Está el juego en pausa ahora mismo?
var _pausado: bool = false


func _ready() -> void:
	# Siempre procesar, incluso con el mundo en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Empezamos ocultos y sin pausa.
	visible = false
	get_tree().paused = false

	_btn_continuar.pressed.connect(_continuar)
	_btn_reiniciar.pressed.connect(_reiniciar)
	_btn_menu.pressed.connect(_al_menu)

	# Botón Idioma -> abre el cuadro de selección.
	_btn_idioma.pressed.connect(_abrir_cuadro_idioma)
	_cuadro_es.pressed.connect(_on_idioma_es)
	_cuadro_en.pressed.connect(_on_idioma_en)
	_cuadro.get_node("Velo").gui_input.connect(_on_velo_input)

	# Refrescamos textos según el idioma activo y escuchamos cambios.
	_actualizar_textos()
	if not LanguageManager.idioma_cambiado.is_connected(_actualizar_textos):
		LanguageManager.idioma_cambiado.connect(_actualizar_textos)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode != KEY_ESCAPE:
		return
	# Si el cuadro de idioma está abierto, ESC solo lo cierra.
	if _pausado and _cuadro.visible:
		_cuadro.visible = false
		return
	# Si el juego está en Game Over, no pausamos (allí cualquier tecla
	# reinicia la partida, lo gestiona main.gd).
	if _en_game_over():
		return
	if _pausado:
		_continuar()
	else:
		_pausar()


# =========================================================================
#  IDIOMA
# =========================================================================
## Coloca cada texto en su nodo y habilita/deshabilita las opciones de
## idioma según cuál esté activo.
func _actualizar_textos(_nuevo_idioma: int = 0) -> void:
	_titulo.text = LanguageManager.t("pausa_titulo")
	_btn_continuar.text = LanguageManager.t("pausa_continuar")
	_btn_reiniciar.text = LanguageManager.t("pausa_reiniciar")
	_btn_menu.text = LanguageManager.t("pausa_menu")
	_btn_idioma.text = LanguageManager.t("btn_idioma")

	_cuadro_titulo.text = LanguageManager.t("titulo_idioma")

	var activo := LanguageManager.idioma_actual
	_cuadro_es.disabled = (activo == LanguageManager.Idioma.ESPANOL)
	_cuadro_en.disabled = (activo == LanguageManager.Idioma.INGLES)


# =========================================================================
#  ACCIONES
# =========================================================================
func _pausar() -> void:
	_pausado = true
	get_tree().paused = true
	visible = true
	_btn_continuar.grab_focus()


func _continuar() -> void:
	_pausado = false
	get_tree().paused = false
	visible = false


func _reiniciar() -> void:
	# Muy importante: despausar ANTES de recargar, o la nueva escena
	# arrancaría congelada.
	get_tree().paused = false
	get_tree().reload_current_scene()


func _al_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(RUTA_MENU)


func _on_idioma_es() -> void:
	LanguageManager.cambiar_idioma(LanguageManager.Idioma.ESPANOL)
	_cuadro.visible = false
	_btn_continuar.grab_focus()


func _on_idioma_en() -> void:
	LanguageManager.cambiar_idioma(LanguageManager.Idioma.INGLES)
	_cuadro.visible = false
	_btn_continuar.grab_focus()


## Abre el cuadro de selección de idioma durante la pausa.
func _abrir_cuadro_idioma() -> void:
	_cuadro.visible = true
	_cuadro_es.grab_focus()


## Cierra el cuadro si se hace clic fuera del panel (sobre el velo).
func _on_velo_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_cuadro.visible = false


## ¿Está visible el panel de Game Over? (para no robarle la tecla ESC).
func _en_game_over() -> bool:
	var escena := get_tree().current_scene
	if escena == null:
		return false
	var panel := escena.get_node_or_null("UI/GameOver")
	return panel != null and panel.visible
