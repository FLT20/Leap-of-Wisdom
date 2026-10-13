## =========================================================================
##  MENÚ PRINCIPAL  (pantalla de título)
## =========================================================================
##  Es la primera escena que ve el jugador. Tiene un botón para EMPEZAR
##  a jugar (carga la escena del juego) y otro para SALIR.
##
##  Para usarlo hay que decirle a Godot que arranque aquí:
##  Proyecto > Ajustes del proyecto > application/run/main_scene = menu.tscn
## =========================================================================
extends Control


# =========================================================================
#  REFERENCIAS
# =========================================================================
@onready var _btn_jugar: Button = $Centro/Panel/Caja/BotonJugar
@onready var _btn_salir: Button = $Centro/Panel/Caja/BotonSalir

## Ruta de la escena del juego (main.tscn).
const RUTA_JUEGO := "res://main.tscn"


func _ready() -> void:
	# Conectamos los botones a sus funciones.
	_btn_jugar.pressed.connect(_on_jugar)
	_btn_salir.pressed.connect(_on_salir)

	# El botón de jugar empieza con el foco, para poder usar el teclado.
	_btn_jugar.grab_focus()


# =========================================================================
#  ACCIONES DE LOS BOTONES
# =========================================================================
func _on_jugar() -> void:
	# Cargamos la escena del juego.
	get_tree().change_scene_to_file(RUTA_JUEGO)


func _on_salir() -> void:
	# Cerramos la aplicación.
	get_tree().quit()
