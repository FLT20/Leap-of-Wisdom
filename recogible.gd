## =========================================================================
##  RECOGIBLE DE FRASES  (coleccionable "tesoro")
## =========================================================================
##  Un cuadro brillante que aparece de sorpresa en el mundo. Cuando la
##  cabeza del jugador lo toca, entrega una frase (inspiración / filosofía /
##  humor), suma al contador y desaparece con un destello.
##
##  Vive en la capa 3 (collision_layer=3). El detector del jugador (Area2D)
##  lo detecta; el recogible en sí no detecta a nadie (collision_mask=0).
## =========================================================================
class_name Recogible
extends Area2D

## Tweens de flotación y latido (para poder detenerlos al recoger).
var _tween_flotar: Tween
var _tween_latir: Tween


func _ready() -> void:
	# Capa 3 = recogibles. Máscara 0: no detecta nada por su cuenta.
	collision_layer = 3
	collision_mask = 0
	monitoring = true

	# Vida propia: flota arriba/abajo y "respira" (crece/encoge), para que
	# se note como un tesoro que espera ser recogido.
	var base_y: float = position.y
	var base_escala: Vector2 = scale
	_tween_flotar = create_tween().set_loops()
	_tween_flotar.tween_property(self, "position:y", base_y - 10.0, 0.9).set_trans(Tween.TRANS_SINE)
	_tween_flotar.tween_property(self, "position:y", base_y, 0.9).set_trans(Tween.TRANS_SINE)
	_tween_latir = create_tween().set_loops()
	_tween_latir.tween_property(self, "scale", base_escala * 1.12, 0.6).set_trans(Tween.TRANS_SINE)
	_tween_latir.tween_property(self, "scale", base_escala, 0.6).set_trans(Tween.TRANS_SINE)


##  Lo llama el jugador al tocarlo. Destella y desaparece.
func recoger() -> void:
	# Evita recogerlo dos veces si el detector vuelve a entrar.
	if not monitoring:
		return
	monitoring = false

	# Detenemos la flotación/latido para que no luchen con el destello.
	if _tween_flotar and _tween_flotar.is_valid():
		_tween_flotar.kill()
	if _tween_latir and _tween_latir.is_valid():
		_tween_latir.kill()

	SFX.recoger(get_parent())

	# Destello: crece, se desvanece y desaparece.
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", scale * 1.9, 0.18)
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(queue_free)

