shader_type canvas_item;
// ===================================================================
//  Recorta una textura CUADRADA a un CIRCULO.
//  Lo aplicamos a la foto de la cabeza para que se vea redonda
//  (mas natural) en vez de un cuadrado flotando sobre el cuerpo.
// ===================================================================

void fragment() {
	// UV son las coordenadas de la imagen: van de (0,0) arriba-izq
	// a (1,1) abajo-der. Al restar 0.5 el centro de la imagen es (0,0).
	vec2 centered = UV - vec2(0.5);

	// Distancia desde el centro. En el borde del circulo vale 0.5.
	float dist = length(centered);

	// alpha = 1 dentro del circulo y 0 fuera. smoothstep suaviza el
	// borde para que no se vea el filo escalonado.
	float circle = 1.0 - smoothstep(0.47, 0.5, dist);

	// Cogemos el color del pixel de la foto...
	COLOR = texture(TEXTURE, UV);
	// ...y le aplicamos la mascara circular al canal alpha (transparencia).
	COLOR.a *= circle;
}
