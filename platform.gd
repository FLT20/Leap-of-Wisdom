## =========================================================================
##  PLATAFORMA  (tipos: normal, móvil y frágil)
## =========================================================================
##  Es una tabla de madera que el generador (main.gd) coloca en el mundo.
##  Tiene tres comportamientos según su "tipo":
##
##    - NORMAL: quieta, espera a que el jugador salte encima.
##    - MOVIL:  se desliza izquierda/derecha. Lleva al jugador encima
##              (por eso el cuerpo es AnimatableBody2D con sync_to_physics).
##    - FRAGIL: aguanta UN aterrizaje y luego se rompe y desaparece.
##
##  main.gd decide el tipo según la dificultad y llama a configurar().
## =========================================================================
class_name Plataforma
extends AnimatableBody2D

enum Tipo { NORMAL, MOVIL, FRAGIL }

## Tipo actual de la plataforma.
var tipo: int = Tipo.NORMAL

# --- Parámetros del movimiento (solo tipo MOVIL) ---
var _amplitud: float = 0.0        # cuántos px se desplaza a cada lado
var _velocidad_mov: float = 1.2   # rapidez del vaivén
var _x_base: float = 0.0          # centro del vaivén
var _fase: float = 0.0            # acumulador de tiempo para el seno

## Evita romper la misma plataforma dos veces.
var _rota: bool = false


func _ready() -> void:
	# Recordamos el centro del vaivén para las plataformas móviles.
	_x_base = position.x
	# Una fase inicial aleatoria para que no todas oscilen a la vez.
	_fase = randf() * TAU


## Configura la plataforma recién creada.
##  - p_tipo: uno de los valores del enum Tipo.
##  - p_amplitud: desplazamiento del vaivén (solo para MOVIL).
func configurar(p_tipo: int, p_amplitud: float = 0.0) -> void:
	tipo = p_tipo
	_amplitud = p_amplitud

	match tipo:
		Tipo.FRAGIL:
			_aplicar_tinte(Color(0.95, 0.75, 0.7))
		Tipo.MOVIL:
			_aplicar_tinte(Color(0.7, 0.9, 0.95))


func _physics_process(delta: float) -> void:
	# Solo las plataformas móviles se mueven.
	if tipo != Tipo.MOVIL or _rota:
		return
	_fase += delta * _velocidad_mov
	# Oscilación suave con seno, centrada en _x_base.
	position.x = clamp(_x_base + sin(_fase) * _amplitud, 140.0, 1010.0)


## Rompe la plataforma (la llama el jugador al aterrizar sobre una frágil).
func romper() -> void:
	if tipo != Tipo.FRAGIL or _rota:
		return
	_rota = true

	# Desactivamos la colisión para que el jugador la atraviese al caer.
	for hijo in get_children():
		if hijo is CollisionShape2D:
			hijo.set_deferred("disabled", true)

	# Pequeña animación: se desvanece y se hunde antes de desaparecer.
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.28)
	tween.tween_property(self, "position:y", position.y + 60.0, 0.28)
	tween.chain().tween_callback(queue_free)


## Tiñe la madera según el tipo (feedback visual de para qué sirve).
func _aplicar_tinte(color: Color) -> void:
	for hijo in get_children():
		if hijo is Sprite2D or hijo is Polygon2D:
			hijo.modulate = color
