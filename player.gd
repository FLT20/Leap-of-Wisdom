## =========================================================================
##  JUGADOR 2D  (Godot 4) - caminar y saltar
## =========================================================================
##  Responsabilidades de este nodo (Player / CharacterBody2D):
##    - Física y movimiento (gravedad, salto, deslizamiento).
##    - Límite lateral (teletransporte por los bordes de la cámara).
##    - Detectar el estado del personaje y disparar las frases de
##      reacción a través del DialogueManager.
##
##  Delegación en otros nodos (arquitectura modular):
##    - La ANIMACIÓN de piernas/brazos vive en player_animation.gd
##      (nodo "Body").
##    - El DIÁLOGO de burbuja vive en dialog.gd (nodo "DialogueManager").
##    - Los TEXTOS viven en frases.gd (recurso Frases).
## =========================================================================

extends CharacterBody2D


# =========================================================================
#  CONSTANTES FÍSICAS
# =========================================================================
## Velocidad al caminar, en píxeles por segundo.
const SPEED := 300.0

## Impulso del salto. NEGATIVO porque arriba es `Y` negativo.
## Con este impulso y la gravedad de abajo el salto alcanza unos 188 px,
## suficiente para superar con holgura el hueco maximo entre maderas (150).
const JUMP_VELOCITY := -700.0

## Desaceleración horizontal al soltar las teclas (independiente del FPS).
const DESACCEL := 2400.0

## Velocidad máxima de caída para evitar saltos de física.
const MAX_FALL_SPEED := 620.0

## Gravedad aplicada al caer/saltar, en píxeles por segundo al cuadrado.
## Ajustada junto al impulso del salto para una altura de salto de ~188 px.
const GRAVEDAD := 1300.0

## Umbral de altura para considerar que el jugador está muy alto.
const ALTURA_PARA_BROMA := 120.0

## Segundos quieto en el suelo antes de mostrar la frase de "quieto".
const TIEMPO_QUIETO := 3.0

## COYOTE TIME: margen (en segundos) para poder saltar JUSTO después de
## haberse despegado del borde. Sin esto, el salto es "todo o nada" y se
## siente injusto. Con esto, el juego perdona unos instantes.
const COYOTE_TIME := 0.12

## JUMP BUFFER: margen (en segundos) para recordar que se pulsó salto un
## instante ANTES de tocar el suelo, y ejecutarlo al aterrizar. Evita
## tener que pulsar en el frame exacto del contacto.
const JUMP_BUFFER_TIME := 0.12


# =========================================================================
#  ESTADO DEL JUGADOR
# =========================================================================
## Altura de partida real para comparar la posición vertical.
## La usa _frases_para_contexto() para la burbuja MANUAL (tecla M).
var _altura_inicio: float = 0.0

## Temporizadores de "feel" del salto (coyote time y jump buffer).
var _coyote: float = 0.0
var _jump_buffer: float = 0.0


# =========================================================================
#  REFERENCIAS A OTROS NODOS
# =========================================================================
## Gestor de la burbuja de diálogo (nodo hijo independiente).
@onready var _gestor_dialogo: DialogManager = $DialogueManager

## Burbuja de diálogo (panel) y su etiqueta de texto.
@onready var _bubble: Control = $SpeechBubble
@onready var _bubble_label: Label = $SpeechBubble/Label

## Nodo de animación del cuerpo (player_animation.gd).
@onready var _animacion: Node2D = $Body


# =========================================================================
#  INICIALIZACIÓN
# =========================================================================
func _ready() -> void:
	_altura_inicio = global_position.y

	# Configuración física del CharacterBody2D.
	floor_snap_length = 8.0
	safe_margin = 0.08

	# Enlazamos la burbuja con el gestor para la burbuja MANUAL (tecla M).
	# El diálogo automático está desactivado a petición del usuario.
	if _gestor_dialogo != null:
		_gestor_dialogo._init_dialogo(_bubble, _bubble_label)


# =========================================================================
#  FÍSICA Y MOVIMIENTO
# =========================================================================
func _physics_process(delta: float) -> void:
	# --- 1) Gravedad y velocidad máxima de caída ----------------------
	if not is_on_floor():
		velocity.y += GRAVEDAD * delta
		velocity.y = min(velocity.y, MAX_FALL_SPEED)

	# --- 2) Coyote Time -----------------------------------------------
	# Si estamos en el suelo, recargamos el "perdón" al máximo. Si no,
	# lo vamos gastando. Mientras quede perdón, podremos saltar aunque
	# ya no toquemos el suelo (útil al caer por un borde).
	if is_on_floor():
		_coyote = COYOTE_TIME
	else:
		_coyote -= delta

	# --- 3) Jump Buffer -----------------------------------------------
	# Si pulsamos salto, abrimos una ventana breve. Si dentro de esa
	# ventana volvemos a tocar suelo (o conservamos coyote), saltamos.
	# Así no hace falta pulsar en el frame exacto del aterrizaje.
	if Input.is_action_just_pressed("ui_accept"):
		_jump_buffer = JUMP_BUFFER_TIME
	else:
		_jump_buffer -= delta

	# --- 4) Salto (usa coyote time + jump buffer) ---------------------
	if _jump_buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_jump_buffer = 0.0
		_coyote = 0.0

	# --- 5) Movimiento horizontal -------------------------------------
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0.0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, DESACCEL * delta)

	# --- 6) Aplicar movimiento ----------------------------------------
	# Guardamos si ya estábamos en el suelo ANTES de mover, para detectar
	# el instante exacto del aterrizaje (y así romper plataformas frágiles).
	var ya_en_suelo := is_on_floor()
	move_and_slide()

	# --- 6b) Recién aterrizado: avisar a la plataforma de debajo -------
	if not ya_en_suelo and is_on_floor():
		_avisar_aterrizaje()

	# --- 7) Límite lateral (envuelve por los bordes de la cámara) -----
	_limitar_bordes()

	# --- 8) Animación del cuerpo (delegada en el nodo "Body") --------
	if _animacion != null and _animacion.has_method("actualizar_animacion"):
		_animacion.actualizar_animacion(delta, velocity.x, is_on_floor())


## Mantiene al jugador dentro de la pantalla teletransportándolo al otro
## lado cuando se sale por un borde (estilo "pantalla envolvente").
func _limitar_bordes() -> void:
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return
	var half_w: float = get_viewport_rect().size.x * 0.5
	var left_limit := cam.position.x - half_w - 20.0
	var right_limit := cam.position.x + half_w + 20.0
	if global_position.x < left_limit:
		global_position.x = right_limit
	elif global_position.x > right_limit:
		global_position.x = left_limit


## Al aterrizar, avisa a la plataforma de debajo por si es FRÁGIL.
## Usamos la colisión del último frame para saber sobre qué pisamos y,
## si ese cuerpo entiende el mensaje "romper()", lo rompemos.
func _avisar_aterrizaje() -> void:
	for i in range(get_slide_collision_count()):
		var colision := get_slide_collision(i)
		var cuerpo := colision.get_collider()
		if cuerpo != null and cuerpo.has_method("romper"):
			cuerpo.romper()


# =========================================================================
#  ENTRADA MANUAL
# =========================================================================
func _unhandled_input(event: InputEvent) -> void:
	# Tecla M: muestra una frase manual del contexto actual.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M and _gestor_dialogo != null:
			_gestor_dialogo._mostrar_manual(
				_frases_para_contexto(), true
			)


# =========================================================================
#  FRASES POR CONTEXTO (burbuja MANUAL con la tecla M)
# =========================================================================
## Devuelve la lista de frases adecuada al comportamiento actual.
## Combina varias categorias para que, al pulsar M, la frase NO sea siempre
## la misma: segun camines, estes parado o vayas alto, se juntan distintas
## listas y luego se elige UNA al azar entre todas ellas.
func _frases_para_contexto() -> Array:
	# En el aire: distingue entre subir (salto) y bajar (caida).
	if not is_on_floor():
		if velocity.y < -10.0:
			return Frases.FRASES_SALTO
		return Frases.FRASES_CAIDA

	# En el suelo: construimos una lista combinada.
	var lista: Array = []

	# Si se esta moviendo, frases de caminar; si esta parado, de reposo.
	if abs(velocity.x) > 1.0:
		lista.append_array(Frases.FRASES_CAMINAR)
	else:
		lista.append_array(Frases.FRASES_QUIETO)

	# Si ademas esta bastante alto, anadimos frases de altura.
	if (_altura_inicio - global_position.y) > ALTURA_PARA_BROMA:
		lista.append_array(Frases.FRASES_ALTURA)

	# Red de seguridad: nunca devolvemos una lista vacia.
	if lista.is_empty():
		lista.append_array(Frases.FRASES_QUIETO)

	return lista
