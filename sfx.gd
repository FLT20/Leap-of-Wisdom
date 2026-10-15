## =========================================================================
##  EFECTOS DE SONIDO PROCEDIMENTALES  (class_name SFX)
## =========================================================================
##  Genera efectos de sonido por código (sin archivos de audio), para dar
##  "game feel" al saltar, aterrizar y romper maderas. Cada llamada crea un
##  AudioStreamPlayer temporal que se autodestruye al terminar.
##
##  Uso:  SFX.pop(self)   SFX.thud(self)   SFX.crack(self)
## =========================================================================
class_name SFX
extends RefCounted


## Sonido agudo y corto al SALTAR.
static func pop(padre: Node) -> void:
	_play(padre, _tono(520.0, 940.0, 0.13, 0.28))


## Sonido del resorte (salto potenciado con flecha abajo): más largo y brillante.
static func pop_fuerte(padre: Node) -> void:
	_play(padre, _tono(380.0, 1400.0, 0.26, 0.34))


## Sonido cristalino al RECOGER un coleccionable de frases.
static func recoger(padre: Node) -> void:
	_play(padre, _tono(880.0, 1760.0, 0.22, 0.26))


## Sonido grave al ATERRIZAR.
static func thud(padre: Node) -> void:
	_play(padre, _tono(190.0, 90.0, 0.11, 0.32))


## Crujido (ruido) al ROMper una plataforma frágil.
static func crack(padre: Node) -> void:
	_play(padre, _ruido(0.18, 0.30))


# =========================================================================
#  INTERNO
# =========================================================================
## Crea un reproductor temporal, lo reproduce y lo libera al terminar.
static func _play(padre: Node, wav: AudioStreamWAV) -> void:
	if padre == null or not is_instance_valid(padre):
		return
	var p := AudioStreamPlayer.new()
	p.stream = wav
	padre.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


## Genera un tono con envolvente (frecuencia que barre de f_ini a f_fin).
static func _tono(f_ini: float, f_fin: float, dur: float, vol: float) -> AudioStreamWAV:
	var mix := 22050
	var n: int = int(mix * dur)
	var data := PackedByteArray()
	data.resize(n * 2)  # 16 bits mono
	for i in range(n):
		var t := float(i) / n
		var env: float = (1.0 - t) * (1.0 - t)  # decay suave
		var f: float = lerpf(f_ini, f_fin, t)
		var s: float = sin(t * dur * f * TAU) * env * vol
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32000))
	return _empaquetar(data, mix)


## Genera un ruido blanco con envolvente (crujido).
static func _ruido(dur: float, vol: float) -> AudioStreamWAV:
	var mix := 22050
	var n: int = int(mix * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / n
		var env: float = 1.0 - t
		var s: float = randf_range(-1.0, 1.0) * env * vol
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32000))
	return _empaquetar(data, mix)


## Convierte los samples crudos en un AudioStreamWAV reproducible.
static func _empaquetar(data: PackedByteArray, mix: int) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix
	wav.stereo = false
	wav.data = data
	return wav
