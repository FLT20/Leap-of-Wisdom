## =========================================================================
##  DIALOG MANAGER  (gestor de la burbuja de diálogo)
## =========================================================================
##  - Muestra frases manuales cuando el jugador las pide (tecla M).
##  - Permite mostrar frases desde cualquier parte del juego.
##  - Mantiene un cooldown para evitar frases repetidas muy seguidas.
## =========================================================================

class_name DialogManager
extends Node


# =========================================================================
#  CONFIGURACIÓN
# =========================================================================
## Segundos de espera antes de la primera frase automática.
@export var dialogo_espera_inicio: float = 3.0

## Segundos que permanece visible cada burbuja.
@export var dialogo_duracion: float = 4.0

## Segundos de cortesía entre una frase y la siguiente.
@export var dialogo_cooldown: float = 2.0


# =========================================================================
#  ESTADO
# =========================================================================
## Todas las frases disponibles para el modo automático.
var _frases_automaticas: Array = []

## Cola rotativa de frases (se recicla en bucle).
var _pila_frase: Array = []

## Cuenta atrás hasta poder lanzar la primera frase automática.
var _tiempo_auto_disponible: float = 0.0

## Tiempo que le queda a la burbuja visible antes de ocultarse.
var _tiempo_burbuja_restante: float = 0.0

## Si es `true`, el jugador ya interactuó y paramos el modo automático.
var _ha_interactuado: bool = false

## Referencias visuales de la burbuja.
var _nodo_burbuja: Control = null
var _label_burbuja: Label = null


# =========================================================================
#  CICLO DE VIDA
# =========================================================================
func _init() -> void:
	_tiempo_auto_disponible = dialogo_espera_inicio


## Impulsa el diálogo automático fotograma a fotograma. Al ser un nodo
## independiente se auto-gestiona sin que el jugador tenga que llamarlo.
func _process(delta: float) -> void:
	_procesar(delta)


## Prepara el gestor para el comienzo de una partida.
func _inicio_partida() -> void:
	_ha_interactuado = false
	_tiempo_auto_disponible = dialogo_espera_inicio
	_tiempo_burbuja_restante = 0.0
	_construir_pila_frase()


## Marca que el jugador ya interactuó (detiene las frases automáticas).
func _marcar_interaccion() -> void:
	_ha_interactuado = true
	_ocultar_burbuja()


## Enlaza el gestor con la burbuja visual (panel) y su etiqueta.
func _init_dialogo(burbuja_nodo: Control, label_burbuja: Label) -> void:
	if not is_instance_valid(burbuja_nodo) or not is_instance_valid(label_burbuja):
		return
	_nodo_burbuja = burbuja_nodo
	_label_burbuja = label_burbuja


## Define la lista de frases que rotarán en modo automático.
func _set_frase_automaticas(frases: Array) -> void:
	_frases_automaticas = frases.duplicate()
	_construir_pila_frase()



# =========================================================================
#  LÓGICA DE DIÁLOGO
# =========================================================================
## Procesa el estado del diálogo cada frame.
func _procesar(delta: float) -> void:
	# Si hay una burbuja en pantalla, solo esperamos a que se agote.
	if _tiempo_burbuja_restante > 0.0:
		_tiempo_burbuja_restante -= delta
		if _tiempo_burbuja_restante <= 0.0:
			_ocultar_burbuja()
		return

	# Tras interactuar no lanzamos más frases automáticas.
	if _ha_interactuado:
		return

	# Respetamos la espera inicial.
	if _tiempo_auto_disponible > 0.0:
		_tiempo_auto_disponible -= delta
		return

	# Sin burbuja visible y sin espera pendiente: lanzamos la siguiente.
	_mostrar_proxima_frase_automatica()


## Muestra una frase manual concreta. `forzar` ignora las esperas.
func _mostrar_manual(frases: Array, forzar: bool = false) -> void:
	if frases.is_empty():
		return
	var frase: String = frases[randi() % frases.size()]
	if forzar:
		_desplegar_frase(frase)
		return
	if _tiempo_burbuja_restante > 0.0:
		return
	_desplegar_frase(frase)


## Muestra la siguiente frase automática de la cola rotativa.
func _mostrar_proxima_frase_automatica() -> void:
	if _pila_frase.is_empty():
		return
	var frase: String = _obtener_siguiente_frase()
	if frase == "":
		return
	_desplegar_frase(frase)


## Escribe el texto en la burbuja y la hace visible.
func _desplegar_frase(frase: String) -> void:
	if not is_instance_valid(_label_burbuja):
		return
	_label_burbuja.text = frase
	_label_burbuja.visible = true
	if is_instance_valid(_nodo_burbuja):
		_nodo_burbuja.visible = true
	_tiempo_burbuja_restante = dialogo_duracion


## Oculta la burbuja y limpia su texto.
func _ocultar_burbuja() -> void:
	_tiempo_burbuja_restante = 0.0
	# Oculta también el panel (el recuadro con fondo), no solo el texto:
	# si no, el fondo de la burbuja se quedaba en pantalla tras desaparecer
	# la frase.
	if is_instance_valid(_nodo_burbuja):
		_nodo_burbuja.visible = false
	if is_instance_valid(_label_burbuja):
		_label_burbuja.visible = false
		_label_burbuja.text = ""


## Rota la cola: saca la primera frase y la lleva al final.
func _obtener_siguiente_frase() -> String:
	if _pila_frase.is_empty():
		return ""
	var frase = _pila_frase[0]
	_pila_frase.pop_front()
	_pila_frase.append(frase)
	return frase


## Reconstruye la cola a partir de las frases automáticas.
func _construir_pila_frase() -> void:
	_pila_frase = _frases_automaticas.duplicate()
