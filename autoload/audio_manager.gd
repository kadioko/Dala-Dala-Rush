extends Node
## Centralised SFX/music hub.
## SFX are generated procedurally so the project runs without asset files.
## Drop real .ogg/.wav into res://audio/ and assign in `_load_streams()` to replace.

var music_on: bool = true
var sfx_on: bool = true

var _sfx_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer

var _sfx_streams: Dictionary = {}

func _ready() -> void:
	music_on = SaveSystem.get_value("music_on", true)
	sfx_on = SaveSystem.get_value("sfx_on", true)
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "Master"
	add_child(_sfx_player)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = -8.0
	add_child(_music_player)
	_load_streams()

func _load_streams() -> void:
	# Replace these with real audio: load("res://audio/coin.ogg") etc.
	_sfx_streams = {
		"coin": _make_tone(880.0, 0.08),
		"passenger": _make_tone(660.0, 0.12),
		"crash": _make_tone(110.0, 0.35),
		"click": _make_tone(440.0, 0.05),
		"horn": _make_tone(220.0, 0.20),
		"powerup": _make_tone(1320.0, 0.18),
	}

func play_sfx(key: String) -> void:
	if not sfx_on:
		return
	var stream: Variant = _sfx_streams.get(key)
	if stream == null:
		return
	_sfx_player.stream = stream as AudioStream
	_sfx_player.play()

func set_music_on(on: bool) -> void:
	music_on = on
	SaveSystem.set_value("music_on", on)
	if not on and _music_player.playing:
		_music_player.stop()

func set_sfx_on(on: bool) -> void:
	sfx_on = on
	SaveSystem.set_value("sfx_on", on)

func _make_tone(freq: float, duration: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = clamp(1.0 - t / duration, 0.0, 1.0)
		var sample: float = sin(t * freq * TAU) * envelope * 0.4
		var s16: int = int(sample * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav
