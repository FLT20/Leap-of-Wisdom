## =========================================================================
##  ANIMACIÓN DEL CUERPO  (nodo "Body")
## =========================================================================
##  Nodo independiente encargado SOLO de la animación procedural del
##  personaje: orientar el cuerpo y balancear piernas/brazos.
##  El jugador le pasa el estado (velocidad y si está en suelo) para que
##  este nodo no dependa de la física del CharacterBody2D.
## =========================================================================

extends Node2D


## Rapidez con la que piernas/brazos alcanzan su pose objetivo.
const ANIM_LERP := 14.0

## Frecuencia de balanceo de piernas al caminar.
const WALK_FREQ := 12.0


# Referencias a las extremidades (hijas de este nodo).
@onready var _pierna_izq: Node2D = $LegLeft
@onready var _pierna_der: Node2D = $LegRight
@onready var _brazo_izq: Node2D = $ArmLeft
@onready var _brazo_der: Node2D = $ArmRight

# Reloj interno de la animación de caminar.
var _anim_time: float = 0.0


# =========================================================================
#  ANIMACIÓN
# =========================================================================
## Actualiza la pose del personaje. Llamado por el jugador cada frame.
## `velocidad_x`: velocidad horizontal actual.
## `en_suelo`: true si el personaje está apoyado en el suelo.
func actualizar_animacion(delta: float, velocidad_x: float, en_suelo: bool) -> void:
	# --- Orientación del cuerpo según la dirección --------------------
	if velocidad_x > 1.0:
		scale.x = 1.0
	elif velocidad_x < -1.0:
		scale.x = -1.0

	var target_leg := 0.0
	var target_arm := 0.0

	if not en_suelo:
		# En el aire: piernas recogidas y brazos arriba.
		target_leg = 0.45
		target_arm = 2.2
	elif abs(velocidad_x) > 1.0:
		# Caminando: balanceo senoidal de piernas y brazos.
		_anim_time += delta
		var swing := sin(_anim_time * WALK_FREQ)
		target_leg = swing * 0.6
		target_arm = -swing * 0.7
	else:
		# Quieto: reiniciamos el reloj del balanceo.
		_anim_time = 0.0

	# Interpolación suave hacia la pose objetivo.
	var t := ANIM_LERP * delta
	_pierna_der.rotation = lerp_angle(_pierna_der.rotation, target_leg, t)
	_pierna_izq.rotation = lerp_angle(_pierna_izq.rotation, -target_leg, t)
	_brazo_der.rotation = lerp_angle(_brazo_der.rotation, -target_arm, t)
	_brazo_izq.rotation = lerp_angle(_brazo_izq.rotation, target_arm, t)
