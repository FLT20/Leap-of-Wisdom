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
##    - La ANIMACIÓN de la cabeza (squash, balanceo, inclinación) vive en
##      player_animation.gd (nodo "Head").
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

## SALTO VARIABLE: si el jugador SUELTA el botón de salto mientras sube,
## la velocidad de subida se multiplica por este factor (<1), acortando el
## salto. Así, un toque corto = salto corto; mantener pulsado = salto alto.
const SALTO_CORTE := 0.42

## SALTO POTENCIADO (flecha ABAJO): si el jugador se aplasta (flecha abajo
## en el suelo) y luego salta, sale MUCHO más alto. Es el "resorte".
const SALTO_APLASTADO := -1080.0

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

## true mientras el personaje está subiendo por un salto (para el corte).
var _saltando: bool = false

## true mientras el jugador mantiene flecha ABAJO apoyado (cargando resorte).
var _aplastado: bool = false

## Contador de coleccionables de frases recogidos en la partida.
var _frases_recogidas: int = 0


# =========================================================================
#  REFERENCIAS A OTROS NODOS
# =========================================================================
## Gestor de la burbuja de diálogo (nodo hijo independiente).
@onready var _gestor_dialogo: DialogManager = $DialogueManager

## Burbuja de diálogo (panel) y su etiqueta de texto.
@onready var _bubble: Control = $SpeechBubble
@onready var _bubble_label: Label = $SpeechBubble/Label

## Nodo de animación de la cabeza (player_animation.gd).
@onready var _animacion: Node2D = $Head

## Detector (Area2D) que rodea a la cabeza para recoger coleccionables.
@onready var _detector: Area2D = $Detector

## Etiqueta del contador de frases recogidas (la pone main.gd al iniciar).
var _contador_label: Label = null


# =========================================================================
#  INICIALIZACIÓN
# =========================================================================
func _ready() -> void:
	_altura_inicio = global_position.y

	# Configuración física del CharacterBody2D.
	floor_snap_length = 8.0
	safe_margin = 0.08

	# Capas de colisión: capa 1 = jugador; máscara 2 = solo detecta las
	# maderas (que están en la capa 2). Así el jugador pisa las maderas pero
	# las maderas nunca lo empujan ni chocan entre sí.
	collision_layer = 1
	collision_mask = 2

	# El detector de coleccionables avisa cuando toca uno.
	if _detector != null and not _detector.area_entered.is_connected(_on_area_recogida):
		_detector.area_entered.connect(_on_area_recogida)

	# Enlazamos la burbuja con el gestor para la burbuja MANUAL (tecla M).
	# El diálogo automático está desactivado a petición del usuario.
	if _gestor_dialogo != null:
		_gestor_dialogo._init_dialogo(_bubble, _bubble_label)

	# Texto por defecto de la burbuja en el idioma activo, y refresco si el
	# jugador cambia de idioma durante la partida (menú de pausa).
	if _bubble_label != null:
		_bubble_label.text = LanguageManager.t("burbuja_inicio")
	if not LanguageManager.idioma_cambiado.is_connected(_on_idioma_cambiado):
		LanguageManager.idioma_cambiado.connect(_on_idioma_cambiado)


## Refresca el texto por defecto de la burbuja al cambiar de idioma.
func _on_idioma_cambiado(_nuevo_idioma: int) -> void:
	if _bubble_label != null:
		_bubble_label.text = LanguageManager.t("burbuja_inicio")


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

	# --- 3b) Aplastado con flecha ABAJO (cargar resorte) --------------
	# Apoyado y con flecha abajo mantenida -> la cabeza se achatarra (carga).
	_aplastado = is_on_floor() and Input.is_action_pressed("ui_down")

	# --- 4) Salto (usa coyote time + jump buffer) ---------------------
	if _jump_buffer > 0.0 and _coyote > 0.0:
		if _aplastado:
			# Resorte: salto MUCHO más alto (decisión A1).
			velocity.y = SALTO_APLASTADO
			SFX.pop_fuerte(self)
		else:
			velocity.y = JUMP_VELOCITY
			SFX.pop(self)
		_jump_buffer = 0.0
		_coyote = 0.0
		_saltando = true
		_aplastado = false
		# Feedback: estirón con rebote de la cabeza.
		if _animacion != null and _animacion.has_method("golpe_salto"):
			_animacion.golpe_salto()

	# --- 4b) Salto variable: soltar el botón acorta el salto ----------
	if _saltando and velocity.y < 0.0 and not Input.is_action_pressed("ui_accept"):
		velocity.y *= SALTO_CORTE
		_saltando = false

	# Si ya no estamos subiendo, damos por terminado el salto.
	if velocity.y >= 0.0:
		_saltando = false

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

	# --- 8) Animación de la cabeza (delegada en el nodo "Head") ------
	if _animacion != null and _animacion.has_method("actualizar_animacion"):
		_animacion.actualizar_animacion(delta, velocity.x, velocity.y, is_on_floor(), _aplastado)


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
	# Feedback de aterrizaje: aplastón de la cabeza + sonido.
	if _animacion != null and _animacion.has_method("golpe_aterrizaje"):
		_animacion.golpe_aterrizaje()
	SFX.thud(self)

	for i in range(get_slide_collision_count()):
		var colision := get_slide_collision(i)
		var cuerpo := colision.get_collider()
		if cuerpo != null and cuerpo.has_method("romper"):
			cuerpo.romper()


# =========================================================================
#  COLECCIONABLES DE FRASES
# =========================================================================
##  Lo llama el detector cuando la cabeza toca un coleccionable (Area2D).
##  Suma 1 al contador, muestra una frase sorpresa y recoge el objeto.
func _on_area_recogida(area: Area2D) -> void:
	if area == null or not area.has_method("recoger"):
		return
	_frases_recogidas += 1
	# Frase sorpresa (inspiración / filosofía / humor) en la burbuja.
	if _gestor_dialogo != null:
		var frases := Frases.obtener("coleccionable")
		if not frases.is_empty():
			_gestor_dialogo._mostrar_manual(frases, true)
	# Refresca el contador en pantalla.
	if _contador_label != null:
		_contador_label.text = "✦ %d" % _frases_recogidas
	area.recoger()


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
			return Frases.obtener("salto")
		return Frases.obtener("caida")

	# En el suelo: construimos una lista combinada.
	var lista: Array = []

	# Si se esta moviendo, frases de caminar; si esta parado, de reposo.
	if abs(velocity.x) > 1.0:
		lista.append_array(Frases.obtener("caminar"))
	else:
		lista.append_array(Frases.obtener("quieto"))

	# Si ademas esta bastante alto, anadimos frases de altura.
	if (_altura_inicio - global_position.y) > ALTURA_PARA_BROMA:
		lista.append_array(Frases.obtener("altura"))

	# Red de seguridad: nunca devolvemos una lista vacia.
	if lista.is_empty():
		lista.append_array(Frases.obtener("quieto"))

	return lista
