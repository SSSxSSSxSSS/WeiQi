# src/ui/sound_manager.gd
class_name SoundManager
extends Node

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _sample_rate: int = 44100

func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = _sample_rate
	generator.buffer_length = 0.5
	_player = AudioStreamPlayer.new()
	_player.stream = generator
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()

func play_stone() -> void:
	_push_tone(220.0, 0.08, 0.3)

func play_click() -> void:
	_push_tone(880.0, 0.03, 0.2)

func play_game_over() -> void:
	_push_tone(440.0, 0.06, 0.4)
	await get_tree().create_timer(0.1).timeout
	_push_tone(554.0, 0.06, 0.4)
	await get_tree().create_timer(0.1).timeout
	_push_tone(660.0, 0.12, 0.5)

func _push_tone(freq: float, duration: float, volume: float) -> void:
	if _playback == null:
		return
	var samples := int(_sample_rate * duration)
	var buf := PackedVector2Array()
	buf.resize(samples)
	for i in samples:
		var t := float(i) / _sample_rate
		var v := sin(t * freq * TAU) * volume
		v *= exp(-t * 20.0)
		buf[i] = Vector2(v, v)
	_playback.push_buffer(buf)
