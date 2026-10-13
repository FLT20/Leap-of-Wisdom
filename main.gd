extends Node2D
## ==================================================================
##  GENERADOR DEL MUNDO VERTICAL  (juego de subir saltando, tipo Pou)
## ==================================================================
##  Crea las plataformas de madera SOLAS, "de 2 en 2" y bien separadas,
##  hacia arriba. Ademas mueve la camara siguiendo al personaje (pero
##  solo hacia ARRIBA, nunca baja) y borra las plataformas que se
##  quedan por debajo para no acumular objetos.
## ==================================================================


# ==================================================================
#  AJUSTES DEL MUNDO
# ==================================================================

## Escena de plataforma que duplicaremos muchas veces.
@export var platform_scene: PackedScene = preload("res://platform.tscn")

## Cuantas plataformas por tanda. Ahora 2, bien separadas.
@export var platforms_per_row: int = 2

## Distancia vertical MINIMA entre tandas. DEBE ser MAYOR que el alto
## del personaje (~92 px) para que quepa holgado entre dos maderas y
## no se atasque NUNCA.
@export var row_gap_min: float = 115.0

## Distancia vertical MAXIMA entre tandas. Debe ser MENOR que la altura
## de salto (~188 px) para que SIEMPRE pueda alcanzar la tanda de arriba.
## Cada tanda usa un valor al azar entre MIN y MAX: asi el mundo es
## variado (nunca una linea regular) pero sin provocar atascos.
@export var row_gap_max: float = 150.0

## Cuantas tandas creamos nada mas empezar (para llenar la pantalla).
@export var rows_at_start: int = 8

## Margen (en px) por encima/debajo de la vista para crear o reciclar.
@export var view_margin: float = 420.0

## Altura de referencia (superficie del pasto inicial, y=530). La usa el
## generador del mundo para colocar las primeras maderas. El marcador de
## altura NO usa este valor: mide desde la posición real del jugador
## (_altura_origen).
@export var altura_inicial: float = 530.0

## Cuantos pixeles equivalen a 1 metro en el marcador (para mostrar un
## numero mas bonito que los pixeles crudos).
@export var pixels_por_metro: float = 40.0

## --- DIFICULTAD PROGRESIVA -----------------------------------------
## Cuanta altura (en px) hace falta para llegar a la dificultad MAXIMA.
## A mas altura, maderas mas estrechas y mas plataformas especiales.
@export var dificultad_max_altura: float = 6000.0

## Ancho (escala X) de la madera cuando la dificultad es MINIMA (arriba
## del todo al empezar): amplia y facil.
@export var ancho_facil: float = 1.25

## Ancho (escala X) de la madera cuando la dificultad es MAXIMA (muy
## arriba): estrecha y dificil.
@export var ancho_dificil: float = 0.62

## A partir de que fraccion de dificultad (0..1) empiezan a aparecer las
## plataformas MOVILES y, mas tarde, las FRAGILES.
@export var inicio_moviles: float = 0.15
@export var inicio_fragiles: float = 0.40


# ==================================================================
#  FRASES DE GAME OVER
# ==================================================================
## Provienen de frases.gd (única fuente de verdad para todos los textos).
## Salen al azar cuando el jugador cae, para animarle a reintentar.


# ==================================================================
#  REFERENCIAS
# ==================================================================
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D

## Etiqueta del marcador de altura. Va en su propio CanvasLayer "UI"
## (encima de todo) para que se vea siempre. La actualizamos cada frame.
@onready var score_label: Label = $UI/ScoreLabel

## Etiqueta con la altura ACTUAL en vivo (sube y baja), en pequeño, debajo
## del récord. Muestra dónde está el jugador ahora mismo, no su mejor marca.
@onready var altura_actual_label: Label = $UI/AlturaActualLabel

## Capa del menú de Game Over (oculta al empezar). Se muestra al caer.
@onready var game_over: Control = $UI/GameOver

## Etiqueta con la frase aleatoria de ánimo dentro del Game Over.
@onready var frase_label: Label = $UI/GameOver/Centro/Panel/Caja/FraseLabel

## Señal que se emite cuando se activa el game over.
signal game_over_activated

## Altura Y de la última tanda creada (la de más arriba). Empieza en 0.
var _highest_y: float = 0.0

## Lista con las plataformas que están vivas ahora mismo.
var _platforms: Array[Node2D] = []

## Altura MÁXIMA (en px) que ha alcanzado el personaje en la partida.
@export var max_altura: float = 0.0

## Posición Y real del jugador al empezar la partida. Es el "cero" del
## marcador: medimos la altura como (_altura_origen - posición actual),
## en lugar de usar la superficie del pasto. Así el contador arranca en
## 0 m exacto y refleja la altura real recorrida por el jugador.
var _altura_origen: float = 0.0

## Evita que el Game Over se dispare varias veces seguidas.
var _game_over_activo: bool = false


func _actualizar_marcador_altura() -> void:
	# Medimos desde la posición real de inicio (_altura_origen), no desde
	# la superficie del pasto: así el marcador arranca en 0 m exacto.
	var altura_actual: float = _altura_origen - player.position.y

	# 1) RÉCORD (grande): solo sube, nunca baja. Es tu mejor marca.
	if altura_actual > max_altura:
		max_altura = altura_actual
	var metros_record: int = int(round(max_altura / pixels_por_metro))
	var texto_record := "Altura: %d m" % metros_record
	if score_label.text != texto_record:
		score_label.text = texto_record

	# 2) ALTURA ACTUAL (pequeña): sube y baja en vivo. Limitada a 0 para no
	#    mostrar números negativos si el jugador cae por debajo del inicio.
	var metros_actual: int = int(round(max(altura_actual, 0.0) / pixels_por_metro))
	var texto_actual := "Actual: %d m" % metros_actual
	if altura_actual_label.text != texto_actual:
		altura_actual_label.text = texto_actual



# ==================================================================
#  _ready()
# ==================================================================
##  Se ejecuta UNA vez al entrar en escena.
func _ready() -> void:
	_inicializar_juego()

func _inicializar_juego() -> void:
	# El "cero" del marcador es la posición Y REAL del jugador al empezar
	# (no la del pasto). Así el contador arranca en 0 m exacto.
	_altura_origen = player.position.y

	# Empezamos a crear madera por ENCIMA del pasto inicial (superficie
	# en y=altura_inicial). Calculamos un punto inicial que permita
	# al personaje saltar cómodamente.
	var punto_inicial_y: float = altura_inicial - 105.0  # 425 cuando altura_inicial=530
	_highest_y = punto_inicial_y

	# Llenamos la pantalla con varias tandas hacia arriba.
	for i in range(rows_at_start):
		_spawn_row()

	# Centramos la cámara en el jugador
	_actualizar_camara()

	# El menú de Game Over empieza oculto
	game_over.visible = false
	_game_over_activo = false


# ==================================================================
#  _activar_game_over()
# ==================================================================
##  Congela el mundo, pone una frase de animo AL AZAR en el menu y lo
##  muestra. A partir de aqui solo queda esperar que el jugador pulse
##  una tecla para reintentar (ver _unhandled_input, mas abajo).
func _activar_game_over() -> void:
	if _game_over_activo:
		return
		
	_game_over_activo = true
	emit_signal("game_over_activated")

	# Congelamos al jugador
	if is_instance_valid(player):
		player.set_physics_process(false)
		player.velocity = Vector2.ZERO

	# Mostramos una frase aleatoria
	if is_instance_valid(frase_label):
		frase_label.text = Frases.FRASES_GAME_OVER[randi() % Frases.FRASES_GAME_OVER.size()]
		game_over.visible = true


# ==================================================================
#  _unhandled_input(event)
# ==================================================================
##  Cuando el Game Over esta en pantalla, cualquier tecla (o clic) sirve
##  para reiniciar la partida de inmediato.
func _unhandled_input(event: InputEvent) -> void:
	if not _game_over_activo:
		return
	var es_tecla: bool = event is InputEventKey and event.pressed and not event.echo
	var es_clic: bool = event is InputEventMouseButton and event.pressed
	if es_tecla or es_clic:
		get_tree().reload_current_scene()


# ==================================================================
#  _process(delta)
# ==================================================================
##  Se ejecuta en cada frame. Aqui mantenemos el mundo vivo.
func _process(_delta: float) -> void:
	# Salir si el juego está en game over
	if _game_over_activo:
		return
		
	# Verificar que los nodos esenciales existen
	if not _validar_nodos_esenciales():
		return

	# Actualizar sistemas del juego
	_actualizar_mundo()
	_actualizar_camara()
	_actualizar_marcador_altura()
	_verificar_game_over()


func _validar_nodos_esenciales() -> bool:
	return is_instance_valid(player) and is_instance_valid(camera) and is_instance_valid(score_label)


func _actualizar_mundo() -> void:
	# Crear plataformas nuevas hacia arriba
	_crear_plataformas_si_necesario()
	
	# Reciclar plataformas que quedaron muy abajo
	_reciclar_plataformas_antiguas()


func _crear_plataformas_si_necesario() -> void:
	var cam_top: float = camera.position.y - _obtener_half_screen_h()
	while _highest_y > cam_top - view_margin:
		_spawn_row()


func _reciclar_plataformas_antiguas() -> void:
	var cam_bottom: float = camera.position.y + _obtener_half_screen_h() + view_margin
	var plataformas_validas: Array[Node2D] = []
	
	for plataforma in _platforms:
		if not is_instance_valid(plataforma):
			continue
			
		if plataforma.position.y > cam_bottom:
			plataforma.queue_free()
		else:
			plataformas_validas.append(plataforma)
			
	_platforms = plataformas_validas


func _actualizar_camara() -> void:
	# La cámara sigue al jugador SOLO hacia arriba (nunca baja) y NUNCA se
	# mueve en horizontal: el mundo queda fijo a izquierda y derecha.
	var objetivo_y: float = player.position.y - 80.0
	if objetivo_y < camera.position.y:
		camera.position.y = objetivo_y


func _obtener_half_screen_h() -> float:
	return get_viewport_rect().size.y * 0.5


func _verificar_game_over() -> void:
	# Game Over: si el jugador cae por debajo de la vista
	var limite_abajo: float = camera.position.y + _obtener_half_screen_h() + 60.0
	if player.position.y > limite_abajo:
		_activar_game_over()


# ==================================================================
#  _spawn_row()
# ==================================================================
##  Crea una tanda de 2 maderas BIEN SEPARADAS en la altura actual
##  (una en la mitad izquierda y otra en la derecha) y sube para
##  preparar la tanda siguiente. La dificultad crece con la altura:
##  maderas mas estrechas y mas plataformas MOVILES/FRAGILES.
func _spawn_row() -> void:
	# La dificultad crece con la altura: 0 abajo (facil), 1 muy arriba.
	var dif: float = _calcular_dificultad()

	for i in range(platforms_per_row):
		var x: float
		if i == 0:
			# Mitad izquierda de la pantalla (evitamos el centro)
			x = randf_range(150.0, 470.0)
		else:
			# Mitad derecha de la pantalla (evitamos el centro)
			x = randf_range(680.0, 1000.0)

		# Limitar a los bordes de la pantalla con margen
		x = clamp(x, 120.0, 1030.0)

		# Todas las plataformas de la tanda están a la misma altura
		var y: float = _highest_y

		# Instanciar la plataforma
		var plataforma: Plataforma = platform_scene.instantiate()
		plataforma.position = Vector2(x, y)

		# Ancho progresivo: ancha y facil abajo, estrecha y dura arriba.
		# El randf da un poco de variedad sin pasarse de la dificultad.
		var ancho: float = lerp(ancho_facil, ancho_dificil, dif) * randf_range(0.9, 1.1)
		plataforma.scale.x = ancho

		add_child(plataforma)
		_platforms.append(plataforma)

		# Elegimos el tipo segun la dificultad y lo configuramos en la plataforma.
		var tipo := _elegir_tipo(dif)
		var amplitud: float = randf_range(60.0, 130.0) * (0.5 + dif)
		plataforma.configurar(tipo, amplitud)

	# Preparar la altura para la siguiente tanda
	var gap: float = randf_range(row_gap_min, row_gap_max)
	_highest_y -= gap


# ==================================================================
#  DIFICULTAD PROGRESIVA
# ==================================================================
## Devuelve la dificultad actual (0 = abajo/facil, 1 = muy arriba/dificil)
## segun la altura de la tanda que estamos generando.
func _calcular_dificultad() -> float:
	if dificultad_max_altura <= 0.0:
		return 0.0
	var altura: float = _altura_origen - _highest_y
	return clamp(altura / dificultad_max_altura, 0.0, 1.0)


## Elige al azar el tipo de plataforma segun la dificultad. Al principio
## (dif baja) casi todas NORMALES; al subir aparecen MOVILES y FRAGILES.
func _elegir_tipo(dif: float) -> int:
	var azar: float = randf()
	# Fragiles: solo a partir de inicio_fragiles, probando mas con la altura.
	if dif >= inicio_fragiles and azar < (dif - inicio_fragiles) * 0.6:
		return Plataforma.Tipo.FRAGIL
	# Moviles: a partir de inicio_moviles.
	if dif >= inicio_moviles and azar < dif * 0.55:
		return Plataforma.Tipo.MOVIL
	return Plataforma.Tipo.NORMAL
