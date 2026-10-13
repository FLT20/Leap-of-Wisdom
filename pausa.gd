## =========================================================================
##  MENÚ DE PAUSA  (durante la partida)
## =========================================================================
##  Se controla con la tecla ESC: pausa / reanuda el juego. Ofrece:
##    - CONTINUAR: vuelve al juego.
##    - REINICIAR: empieza la partida de nuevo.
##    - MENÚ: vuelve a la pantalla de título.
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
@onready var _btn_continuar: Button = $Centro/Panel/Caja/BotonContinuar
@onready var _btn_reiniciar: Button = $Centro/Panel/Caja/BotonReiniciar
@onready var _btn_menu: Button = $Centro/Panel/Caja/BotonMenu

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


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode != KEY_ESCAPE:
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


## ¿Está visible el panel de Game Over? (para no robarle la tecla ESC).
func _en_game_over() -> bool:
	var escena := get_tree().current_scene
	if escena == null:
		return false
	var panel := escena.get_node_or_null("UI/GameOver")
	return panel != null and panel.visible
