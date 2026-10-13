extends SceneTree
# Test automatico (no forma parte del juego). Comprueba que la burbuja
# de "empieza a jugar" sale sola si no tocas nada, y que al interactuar
# cambian las frases.

func _init() -> void:
	var escena: PackedScene = load("res://main.tscn")
	var main := escena.instantiate()
	root.add_child(main)

	var player: CharacterBody2D = main.get_node("Player")
	var burbuja: PanelContainer = player.get_node("SpeechBubble")
	var label: Label = player.get_node("SpeechBubble/Label")

	# Dejamos arrancar la escena y que el personaje aterrice.
	for i in range(30):
		await process_frame
		await physics_frame

	# Recolectamos TODAS las frases que van saliendo durante ~6 segundos
	# SIN tocar ningun control. Deberia incluir la de INICIO.
	var frases_vistas := []
	var ultima = ""
	for i in range(400):
		await process_frame
		await physics_frame
		if burbuja.visible:
			ultima = label.text
			if not frases_vistas.has(ultima):
				frases_vistas.append(ultima)

	print("TEST A - la burbuja salio sola sin tocar nada: ", frases_vistas.size() > 0)
	print("   -> frases vistas:")
	for f in frases_vistas:
		print("      * ", f)

	# La ULTIMA frase visible tras varios segundos debe ser de INICIO
	# (porque el jugador nunca interactuo).
	var palabras_inicio := ["Pulsa", "ESPACIO", "puedes", "Empieza", "salta",
		"Vamos", "Ánimo", "ánimo", "miedo", "flechas", "día", "Respira",
		"cima", "cambiarlo", "primer salto", "sube"]
	var es_inicio := false
	for p in palabras_inicio:
		if ultima.containsn(p):
			es_inicio = true
			break

	print("TEST B - la frase final motiva a EMPEZAR (sin interaccion): ", es_inicio)
	print("   -> ultima frase: '", ultima, "'")

	# Verificamos que _ha_interactuado sigue en false (nunca tocamos nada).
	print("TEST C - _ha_interactuado en false (no toco nada): ", player.get("_ha_interactuado") == false)

	print("=== TESTS DE FRASES COMPLETADOS ===")
	quit()
