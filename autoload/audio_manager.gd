extends Node
## Centralised SFX/music hub.
##
## REAL AUDIO: drop files into res://audio/ named after each SFX key
## (coin.ogg, crash.ogg, horn.ogg, click.ogg, passenger.ogg, powerup.ogg)
## plus music.ogg for the loop — they are picked up automatically.
## Any key without a file falls back to the procedural sound below,
## so the game always has audio. See docs/AUDIO_ASSETS.md.

const AUDIO_DIR := "res://audio/"
const SFX_KEYS := ["coin", "passenger", "crash", "click", "horn", "powerup"]
## Conductor voice lines — file-only (silent until recordings are added).
## See docs/AUDIO_ASSETS.md.
const VOICE_KEYS := ["voice_mwisho", "voice_twende", "voice_karibu", "voice_mafuta", "voice_kituo"]
const VOICE_POOL := 5  # simultaneous SFX

var music_on: bool = true
var sfx_on: bool = true

var _sfx_players: Array = []
var _next_voice: int = 0
var _music_player: AudioStreamPlayer
var _sfx_streams: Dictionary = {}
var _music_stream: AudioStream

func _ready() -> void:
	music_on = SaveSystem.get_value("music_on", true)
	sfx_on = SaveSystem.get_value("sfx_on", true)
	# Data-contract tests load the real project autoload graph but do not need to
	# synthesize several audio buffers just before immediate headless shutdown.
	if "--logic-contracts" in OS.get_cmdline_user_args():
		return

	for _i in range(VOICE_POOL):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = -10.0
	add_child(_music_player)

	_load_streams()
	if music_on:
		play_music()

# ─── Loading ──────────────────────────────────────────────────────

func _load_streams() -> void:
	for key in SFX_KEYS:
		var file := _try_load_file(key)
		_sfx_streams[key] = file if file != null else _procedural(key)
	for key in VOICE_KEYS:
		var vfile := _try_load_file(key)
		if vfile != null:
			_sfx_streams[key] = vfile
	var music_file := _try_load_file("music")
	_music_stream = music_file if music_file != null else _make_music_loop()

func _try_load_file(key: String) -> AudioStream:
	for ext in ["ogg", "wav", "mp3"]:
		var path := "%s%s.%s" % [AUDIO_DIR, key, ext]
		if ResourceLoader.exists(path):
			var stream := load(path)
			if stream is AudioStream:
				# Ensure music loops if it's an ogg
				if key == "music" and stream is AudioStreamOggVorbis:
					stream.loop = true
				return stream
	return null

# ─── Playback ─────────────────────────────────────────────────────

func play_sfx(key: String) -> void:
	if not sfx_on:
		return
	var stream: Variant = _sfx_streams.get(key)
	if stream == null:
		return
	var p: AudioStreamPlayer = _sfx_players[_next_voice]
	_next_voice = (_next_voice + 1) % VOICE_POOL
	p.stream = stream as AudioStream
	# Keep the horn present over music without making pickups feel equally loud.
	p.volume_db = -1.0 if key == "horn" else (-2.0 if key == "crash" else -4.0)
	p.pitch_scale = 1.0
	p.play()

func play_music() -> void:
	if _music_stream == null or _music_player.playing:
		return
	_music_player.stream = _music_stream
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

## 0.0 (calm) → 1.0 (max speed): music subtly speeds up with the run.
func set_music_intensity(f: float) -> void:
	_music_player.pitch_scale = 1.0 + 0.08 * clampf(f, 0.0, 1.0)

func set_music_on(on: bool) -> void:
	music_on = on
	SaveSystem.set_value("music_on", on)
	if on:
		play_music()
	else:
		stop_music()

func set_sfx_on(on: bool) -> void:
	sfx_on = on
	SaveSystem.set_value("sfx_on", on)

# ─── Procedural fallback synthesis ────────────────────────────────

const RATE := 22050

func _procedural(key: String) -> AudioStreamWAV:
	match key:
		"coin":
			# Bright two-note arpeggio
			return _render(0.16, func(t: float, d: float) -> float:
				var f: float = 988.0 if t < 0.07 else 1319.0
				return sin(t * f * TAU) * _env(t, d, 0.005, 0.6) * 0.4)
		"passenger":
			# Friendly rising chirp
			return _render(0.18, func(t: float, d: float) -> float:
				var f: float = 520.0 + 400.0 * (t / d)
				return sin(t * f * TAU) * _env(t, d, 0.01, 0.5) * 0.35)
		"crash":
			# Noise burst + low thud
			return _render(0.45, func(t: float, d: float) -> float:
				var noise: float = randf_range(-1.0, 1.0) * _env(t, d, 0.0, 0.25)
				var thud: float = sin(t * 70.0 * TAU) * _env(t, d, 0.0, 0.6)
				return (noise * 0.45 + thud * 0.5) * 0.6)
		"click":
			return _render(0.05, func(t: float, d: float) -> float:
				return sin(t * 440.0 * TAU) * _env(t, d, 0.002, 0.9) * 0.3)
		"horn":
			# Short two-pulse dala dala honk: bright enough for traffic, not harsh.
			return _render(0.62, func(t: float, _d: float) -> float:
				var pulse_start: float = 0.0
				var pulse_length: float = 0.17
				if t >= 0.22:
					pulse_start = 0.22
					pulse_length = 0.36
				elif t >= 0.17:
					return 0.0
				var local_t: float = t - pulse_start
				if local_t < 0.0 or local_t > pulse_length:
					return 0.0
				var attack: float = smoothstep(0.0, 0.018, local_t)
				var release: float = smoothstep(0.0, 0.075, pulse_length - local_t)
				var breath: float = 1.0 + 0.008 * sin(local_t * 7.5 * TAU)
				var fundamental: float = 311.0 * breath
				var high_tone: float = 392.0 * breath
				var brass: float = sin(local_t * fundamental * TAU) * 0.55
				brass += sin(local_t * fundamental * 2.0 * TAU) * 0.22
				brass += sin(local_t * fundamental * 3.0 * TAU) * 0.10
				brass += sin(local_t * high_tone * TAU) * 0.34
				brass += sin(local_t * high_tone * 2.0 * TAU) * 0.09
				return clampf(brass * attack * release * 0.56, -0.86, 0.86))
		"powerup":
			# Sparkly upward sweep
			return _render(0.30, func(t: float, d: float) -> float:
				var f: float = 660.0 * pow(2.0, t / d * 1.0)
				return (sin(t * f * TAU) * 0.7 + sin(t * f * 2.0 * TAU) * 0.3) \
					* _env(t, d, 0.01, 0.45) * 0.35)
	return _render(0.1, func(t: float, _d: float) -> float:
		return sin(t * 440.0 * TAU) * 0.3)

## Attack/decay envelope.
func _env(t: float, duration: float, attack: float, decay_pow: float) -> float:
	if t < attack:
		return t / max(attack, 0.0001)
	var rest: float = (t - attack) / max(duration - attack, 0.0001)
	return pow(clamp(1.0 - rest, 0.0, 1.0), 1.0 / max(decay_pow, 0.05))

func _render(duration: float, fn: Callable) -> AudioStreamWAV:
	var samples := int(RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t: float = float(i) / RATE
		var s: float = clamp(fn.call(t, duration), -1.0, 1.0)
		var s16: int = int(s * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav

# ─── Procedural music loop (used until music.ogg is provided) ─────
## Cheerful 8-bar bongo-flava-flavoured chiptune loop in A minor pentatonic.

func _make_music_loop() -> AudioStreamWAV:
	var bpm := 116.0
	var beat := 60.0 / bpm
	var bars := 8
	var duration := beat * 4.0 * bars
	var samples := int(RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)

	# Note tables (Hz). 0 = rest.
	var bass: Array = [110.0, 110.0, 87.31, 98.0]          # A2 A2 F2 G2 per bar pair
	var melody: Array = [                                   # 16 eighth-note steps x repeats
		440.0, 0.0, 523.25, 440.0, 659.25, 0.0, 587.33, 523.25,
		440.0, 392.0, 0.0, 392.0, 329.63, 392.0, 440.0, 0.0,
	]

	for i in range(samples):
		var t: float = float(i) / RATE
		var beat_pos: float = t / beat
		var bar: int = int(beat_pos / 4.0)
		var s: float = 0.0

		# Bass: square wave, one note per bar
		var bf: float = bass[bar % bass.size()]
		var bass_env: float = 1.0 - fmod(beat_pos, 1.0) * 0.35
		s += signf(sin(t * bf * TAU)) * 0.085 * bass_env

		# Melody: eighth notes
		var step: int = int(beat_pos * 2.0) % melody.size()
		var mf: float = melody[step]
		if mf > 0.0:
			var step_t: float = fmod(beat_pos * 2.0, 1.0)
			var menv: float = pow(1.0 - step_t, 0.7)
			s += sin(t * mf * TAU) * 0.10 * menv
			s += sin(t * mf * 2.0 * TAU) * 0.03 * menv

		# Percussion: noise hat on off-beats, kick thump on beats
		var beat_t: float = fmod(beat_pos, 1.0)
		if beat_t < 0.05:
			s += sin(t * 60.0 * TAU) * (1.0 - beat_t / 0.05) * 0.18
		var half_t: float = fmod(beat_pos + 0.5, 1.0)
		if half_t < 0.03:
			s += randf_range(-1.0, 1.0) * (1.0 - half_t / 0.03) * 0.05

		var s16: int = int(clamp(s, -1.0, 1.0) * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = samples
	return wav
