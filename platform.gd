## =========================================================================
##  PLATAFORMA  (tipos: normal, móvil y frágil)
## =========================================================================
##  Es una tabla de madera que el generador (main.gd) coloca en el mundo.
##  Tiene tres comportamientos según su "tipo":
##
##    - NORMAL: quieta, espera a que el jugador salte encima.
##    - MOVIL:  se desliza izquierda/derecha con balanceo cartoon.
##    - FRAGIL: al pisarla TIEMBLA unos segundos y luego se rompe.
##
##  IMPORTANTE (capas de colisión): para que las maderas NO choquen entre
##  sí, la plataforma vive en la capa 2 (collision_layer=2) y NO detecta
##  nada (collision_mask=0). El jugador (capa 1) sí la detecta con su
##  máscara. Así las maderas móviles se cruzan libremente sin empujarse.
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

# --- Estado de rotura (solo tipo FRAGIL) ---
## true mientras la frágil está temblando o rompiéndose.
var _rompiendo: bool = false
## true cuando ya se rompió del todo.
var _rota: bool = false
## Segundos que lleva temblando antes de caer.
var _t_temblor: float = 0.0

## Segundos que tiembla la frágil antes de desprenderse.
const TEMBLOR_DURACION := 1.2


func _ready() -> void:
	# Capas: capa 2 = mundo (maderas). Máscara 0 = no detecta a nadie,
	# así NUNCA choca con otras maderas ni con el jugador desde su lado.
	collision_layer = 2
	collision_mask = 0

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
	match tipo:
		Tipo.MOVIL:
			_mover(delta)
		Tipo.FRAGIL:
			if _rompiendo:
				_temblar(delta)


# =========================================================================
#  MOVIMIENTO DE LA MADERA MÓVIL  ( cartoon )
# =========================================================================
##  Se desliza con seno pero con un BALANCÍN cartoon: la madera se inclina
##  según su velocidad (se ladea al cambiar de dirección), lo que le da
##  peso y vida en vez del movimiento "tieso" de antes.
func _mover(delta: float) -> void:
	_fase += delta * _velocidad_mov
	var desfase: float = sin(_fase)
	position.x = clamp(_x_base + desfase * _amplitud, 140.0, 1010.0)
	# La derivada del seno es el coseno: indica la velocidad del vaivén.
	# Cuando va más rápido (centro) se inclina más; en los extremos se
	# endereza. Leve y suave -> sensación de balancín, no de robot.
	rotation = cos(_fase) * 0.09 * clamp(_amplitud / 100.0, 0.4, 1.4)


# =========================================================================
#  ROTURA DE LA MADERA FRÁGIL  ( tiembla y luego cae )
# =========================================================================
##  La llama el jugador al aterrizar sobre una frágil. En vez de romperse
##  al instante, empieza a TEMBLAR durante unos segundos (aviso) y luego
##  se desprende. Una vez iniciado, cae sí o sí (aunque el jugador salte).
func romper() -> void:
	if tipo != Tipo.FRAGIL or _rompiendo or _rota:
		return
	_rompiendo = true
	_t_temblor = 0.0
	SFX.crack(self)


##  Vibración mientras "cae". Cuando pasa el tiempo, se desprende.
func _temblar(delta: float) -> void:
	_t_temblor += delta
	# Temblor horizontal cada vez más intenso.
	var intensidad: float = 3.0 + 4.0 * (_t_temblor / TEMBLOR_DURACION)
	position.x = _x_base + randf_range(-intensidad, intensidad)

	if _t_temblor >= TEMBLOR_DURACION:
		_desprenderse()


##  Desactiva la colisión y hace la animación de caída/desvanecido.
func _desprenderse() -> void:
	_rompiendo = false
	_rota = true
	position.x = _x_base  # centramos antes de caer

	# Desactivamos la colisión para que el jugador la atraviese al caer.
	for hijo in get_children():
		if hijo is CollisionShape2D:
			hijo.set_deferred("disabled", true)

	# Animación: se desvanece y se hunde antes de desaparecer.
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.32)
	tw.tween_property(self, "position:y", position.y + 60.0, 0.32)
	tw.tween_property(self, "rotation", randf_range(-0.5, 0.5), 0.32)
	tw.chain().tween_callback(queue_free)


# =========================================================================
#  VISUAL
# =========================================================================
## Tiñe la madera según el tipo (feedback visual de para qué sirve).
func _aplicar_tinte(color: Color) -> void:
	for hijo in get_children():
		if hijo is Sprite2D or hijo is Polygon2D:
			hijo.modulate = color
