## =========================================================================
##  ANIMACIÓN DE LA CABEZA FLOTANTE  (nodo "Head")
## =========================================================================
##  El personaje es SOLO la cabeza (una imagen). Este script le da vida con
##  animación 100% procedural, pensada para una cara/cabeza que flota y
##  salta. Funciona con CUALQUIER textura (foto actual o sprite futuro).
##
##  Efectos cartoon:
##    - SQUASH & STRETCH con REBOTE (gelatina): al aterrizar aplasta,
##      rebota estirada y se asienta. Al saltar, estira y rebota.
##    - APLASTADO PROVOCADO: con flecha ABAJO la cabeza se achatarra mucho
##      (carga) para luego salir disparada (lo dispara el jugador).
##    - INCLINACIÓN (roll): se ladea según la velocidad horizontal.
##    - BALANCEO/flotación: pequeño bob mientras está en el aire.
##
##  No depende de la física: el jugador le pasa el estado cada frame.
## =========================================================================
extends Node2D


# =========================================================================
#  AJUSTES
# =========================================================================
## Escala base de la cabeza. DEBE coincidir con la del nodo "Head" en
## player.tscn (para que el squash no cambie el tamaño "en reposo").
const ESCALA_BASE := 0.078

## Inclinación máxima (radianes) al moverse a toda velocidad.
const ROLL_MAX := 0.38

## Fuerza del rebote/golpe (0..1 del tamaño).
const GOLPE_FUERZA := 0.30

## Duración del rebote (s). Más alto = rebote más lento y visible.
const GOLPE_DUR := 0.42

## Cuánto se achatarra la cabeza con la flecha ABAJO (0..1).
const APLASTADO_FUERZA := 0.46

## Suavidad al entrar/salir del aplastado.
const APLASTADO_LERP := 15.0

## Amplitud (px) y frecuencia del balanceo/flotación en el aire.
const BOB_AMP := 3.0
const BOB_FREC := 6.0

## Suavidad de la inclinación.
const ROLL_LERP := 12.0


# =========================================================================
#  ESTADO INTERNO
# =========================================================================
var _tiempo: float = 0.0        # reloj para el balanceo
var _roll: float = 0.0          # inclinación actual (interpolada)

# --- Rebote (resorte de gelatina) ---
var _golpe_activo: bool = false
var _golpe_t: float = 0.0       # tiempo transcurrido del golpe
var _golpe_dir: float = 1.0     # +1 = primer movimiento estira, -1 = aplasta

# --- Aplastado por input (flecha abajo) ---
var _aplastado: float = 0.0     # 0 = normal, 1 = muy chaparro (suavizado)


# =========================================================================
#  API: la llama el jugador cada frame
# =========================================================================
## `velocidad_x`/`velocidad_y`: velocidad actual. `en_suelo`: apoyado o no.
## `input_aplastado`: true si el jugador mantiene flecha ABAJO en el suelo.
func actualizar_animacion(delta: float, velocidad_x: float, velocidad_y: float, en_suelo: bool, input_aplastado: bool = false) -> void:
	_tiempo += delta

	# --- Aplastado por input (suavizado) -------------------------------
	var objetivo_aplastado: float = 1.0 if (input_aplastado and en_suelo) else 0.0
	_aplastado = lerp(_aplastado, objetivo_aplastado, APLASTADO_LERP * delta)

	# --- Inclinación según velocidad horizontal ------------------------
	var objetivo_roll: float = clamp(-velocidad_x / 300.0, -1.0, 1.0) * ROLL_MAX
	_roll = lerp(_roll, objetivo_roll, ROLL_LERP * delta)
	rotation = _roll

	# --- Squash & stretch base según el estado -------------------------
	var sx := 1.0
	var sy := 1.0
	if not en_suelo:
		if velocidad_y < 0.0:
			sy = 1.08   # subiendo: estirado
			sx = 0.95
		else:
			sy = 1.10   # cayendo: algo más estirado
			sx = 0.94

	# --- Rebote (pulso amortiguado que oscila una vez) ----------------
	if _golpe_activo:
		_golpe_t += delta
		var p: float = _golpe_t / GOLPE_DUR
		if p >= 1.0:
			_golpe_activo = false
		else:
			# sin(p*2PI) estira y comprime; (1-p) lo amortigua -> gelatina.
			var g: float = sin(p * PI * 2.0) * (1.0 - p) * GOLPE_FUERZA * _golpe_dir
			sy *= 1.0 + g
			sx *= 1.0 - g

	# --- Aplastado por input: chaparra la cabeza ----------------------
	if _aplastado > 0.001:
		sy *= 1.0 - APLASTADO_FUERZA * _aplastado
		sx *= 1.0 + APLASTADO_FUERZA * 0.7 * _aplastado

	# --- Balanceo/flotación (solo en el aire) --------------------------
	var bob := 0.0
	if not en_suelo:
		bob = sin(_tiempo * BOB_FREC) * BOB_AMP
	position.y = bob

	# --- Aplicar escala final ------------------------------------------
	scale = Vector2(ESCALA_BASE * sx, ESCALA_BASE * sy)


# =========================================================================
#  GOLPES (los dispara el jugador)
# =========================================================================
## Efecto de SALTAR: estirón con rebote.
func golpe_salto() -> void:
	_golpe_activo = true
	_golpe_t = 0.0
	_golpe_dir = 1.0


## Efecto de ATERRIZAR: aplastón con rebote.
func golpe_aterrizaje() -> void:
	_golpe_activo = true
	_golpe_t = 0.0
	_golpe_dir = -1.0
