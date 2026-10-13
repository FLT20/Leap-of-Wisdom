## =========================================================================
##  FRASES DE DIÁLOGO DEL JUEGO
## =========================================================================
##  Única fuente de verdad para todos los textos inspiradores.
##  Cada lista pertenece a un contexto y la usan DialogManager
##  (dialog.gd) o los nodos del juego directamente.
## =========================================================================

class_name Frases


# =========================================================================
#  FRASES DE GAME OVER (se muestran al caer)
# =========================================================================
const FRASES_GAME_OVER := [
	"Caíste, pero rendirse no es una opción. ¡Otra vez!",
	"Cada caída es un escalón más en tu camino. Levántate.",
	"Los que nunca se rinden son los que llegan más alto.",
	"Tropezar está permitido; quedarse en el suelo, no.",
	"No contamos las caídas, sino las veces que te levantas.",
	"El que persevera alcanza la cima. Tú puedes.",
	"Hoy caíste, mañana vuelas. No te detengas.",
	"Un paso atrás no significa derrota, es impulso.",
	"Las estrellas no se rindieron: siguen brillando allá arriba.",
	"Solo pierde quien deja de intentarlo. Sigue.",
	"La cumbre espera a quien no se cansa de subir.",
	"Respira. Reintenta. Nadie nació sabiendo volar.",
	"Cada error te deja más cerca de la cima.",
	"El mundo es de quien se levanta una vez más.",
	"No importa cuánto caigas, importa cuánto subas después.",
	"Grandes cosas nacen después de una buena caída.",
	"Tu límite está más arriba de lo que crees. ¡Vamos!",
	"Quien no se rinde jamás conoce la palabra final.",
	"Esta vez caíste; la próxima, vuelas. Palabra.",
	"Los campeones se hacen a base de volver a empezar.",
	"Levántate: la vista desde arriba merece el esfuerzo.",
	"Nadie dijo que fuera fácil, solo que valdría la pena.",
	"Cada final es un nuevo borrador. Escribe otro.",
	"La perseverancia es el superpoder de los valientes.",
	"No es cuán fuerte es el golpe, sino seguir de pie.",
	"Subir cansa, pero quedarte abajo cansa más. ¡Arriba!",
	"El cielo es para quien insiste incluso al caer.",
	"Un nuevo intento es una nueva oportunidad. Tómate la tuya.",
	"Caer cien veces y levantarse es de gigantes.",
	"Tus sueños están más arriba que tus miedos.",
	"El esfuerzo es la llave que abre el camino.",
	"Si caes, vuelve a intentarlo con más determinación.",
	"Cada día es una nueva oportunidad de subir más alto.",
	"La cima no se alcanza sin caer, pero tampoco sin seguir.",
	"Respira hondo y elige levantarte otra vez.",
	"Ya no estás lejos, solo te faltan unas pocas respiraciones.",
	"El camino se abre a quien lo quiere recorrer.",
	"Sígueme, no pierdas la vista de la meta.",
	"Reta a ti mismo, no a la fría realidad.",
	"La perseverancia es el compañero que nunca duerme contigo.",
	"Las estrellas no se preocupan por tus caídas, solo por tus sueños.",
	"Un pequeño esfuerzo hoy puede crear un gran logro mañana.",
	"El resorte de la vida siempre te devuelve a la cima.",
	"Al llegar a la cima, verás por qué siguieron bajando.",
	"La risa y la vida te acompañan si no te rindes.",
	"La compasión y la paciencia son tu mejor aliada.",
	"El aroma de la victoria se cuela entre las sombras.",
	"El próximo intento es un regalo del destino.",
	"Los más altos picos se alcanzan con paciencia.",
	"La victoria es una meta que se alcanza con cuidado.",
	"La voluntad fuerte hace que el camino se abra.",
	"En cada caída, una nueva oportunidad de triunfar.",
	"El miedo es solo la señal de que estás cerca de algo grande.",
	"El éxito no es un fin, es el inicio de una nueva historia.",
	"La esperanza es la fuerza que te mantiene recto."
]


# =========================================================================
#  FRASES DE INICIO (burbuja manual con la tecla M)
# =========================================================================
## Se muestran al pedirlas pulsando M. DialogManager las usa para
## decidir qué frase encaja con el contexto actual del personaje.
const FRASES_INICIO := [
	"¡Vamos! Pulsa ESPACIO para saltar y sube alto.",
	"¡Tú puedes! Usa las flechas y el espacio para avanzar.",
	"Empieza poco a poco: salta de madera en madera.",
	"¡Ánimo! Cada salto te acerca a la cima.",
	"No tengas miedo: salta y verás qué alto llegas.",
	"Muévete con las flechas y salta con ESPACIO. ¡Vamos!",
	"¡Hoy es tu día! Da el primer salto hacia arriba.",
	"Respira hondo y salta. Lo harás genial.",
	"¡Empieza ya! Las mejores vistas están arriba.",
	"Un solo salto puede cambiarlo todo. ¡Inténtalo!"
]


# =========================================================================
#  FRASES AUTOMÁTICAS (alias de compatibilidad)
# =========================================================================
## DialogManager las usa cuando se pide una frase sin contexto concreto.
## Apuntan a las mismas frases de inicio para no duplicar datos.
const FRASES_AUTOMATICAS := FRASES_INICIO


# =========================================================================
#  FRASES DE ACCIÓN (se activan al hacer algo concreto)
# =========================================================================
const FRASES_SALTO := [
	"¡Arriba! Eso es, sigue subiendo.",
	"¡Muy bien! Vas por buen camino.",
	"¡Eso es! Cada salto cuenta.",
	"¡Sigue así! Lo estás haciendo genial.",
	"¡Vamos! Estás más cerca de la cima."
]

const FRASES_CAIDA := [
	"¡No pasa nada! Vuelve a intentarlo.",
	"Caer está bien: lo importante es seguir.",
	"¡Tranquilo! Todos caen, tú sigues adelante.",
	"Aterriza y vuelve a saltar. ¡Tú puedes!",
	"Un tropiezo no es el final. ¡Ánimo!"
]

const FRASES_ATERRIZAJE := [
	"¡Bien! Apoyo firme, sigue así.",
	"¡Perfecto! Ya estás de vuelta en pie.",
	"¡Muy bien! Ahora a por el siguiente salto.",
	"¡Genial! Pisa firme y continúa.",
	"¡Eso es! Pulsa de nuevo para seguir."
]

const FRASES_CAMINAR := [
	"¡Ya estás en marcha! Continúa.",
	"Buen control, sigue así.",
	"Cada paso te acerca a la cima.",
	"El mundo es de quien se mueve.",
	"La página no se escribe si no se empieza."
]

const FRASES_ALTURA := [
	"¡Muy alto! Sigues subiendo.",
	"Mira todo desde aquí. ¡Increíble!",
	"Cuanto más subes, mejor se ve. ¡Sigue!",
	"Estás dejando atrás el suelo. ¡Bien hecho!",
	"Desde aquí todo se ve pequeño. ¡Impresionante!",
	"Vas conquistando el cielo paso a paso. ¡Genial!",
	"Las alturas son para valientes como tú. ¡Arriba!",
	"Cada metro cuenta, y tú sumas muchos. ¡Eso es!"
]

const FRASES_QUIETO := [
	"El reposo es parte del camino. Continúa cuando estés listo.",
	"Un momento de calma es el inicio de una nueva subida.",
	"Respira. Hasta los que escalan paran a mirar la vista.",
	"Tómate tu tiempo: la prisa no sube montañas.",
	"Quieto hoy, mañana con más fuerza. Tú decides cuándo.",
	"Una pausa sabia vale más que diez pasos torpes."
]
