# src/ui/sound_manager.gd
class_name SoundManager
extends Node

var _generator: AudioStreamGenerator
var _player: AudioStreamPlayer

func _ready() -> void:
	_generator = AudioStreamGenerator.new()
	_generator.mix_rate = 44100
	_generator.buffer_length = 0.1
	_player = AudioStreamPlayer.new()
	_player.stream = _generator
	add_child(_player)

## 播放落子音效（短促低沉木头声）
func play_stone() -> void:
	_play_tone(220.0, 0.08, 0.3)

## 播放按钮点击音效（清脆咔嗒声）
func play_click() -> void:
	_play_tone(880.0, 0.03, 0.2)

## 播放游戏结束音效
func play_game_over() -> void:
	_play_tone(440.0, 0.06, 0.4)
	await get_tree().create_timer(0.1).timeout
	_play_tone(554.0, 0.06, 0.4)
	await get_tree().create_timer(0.1).timeout
	_play_tone(660.0, 0.12, 0.5)

func _play_tone(freq: float, duration: float, volume: float) -> void:
	var g := _generator as AudioStreamGenerator
	var pb := g.get_playback()
	if pb == null:
		return
	var buf := PackedVector2Array()
	var samples := int(g.mix_rate * duration)
	buf.resize(samples)
	for i in samples:
		var t := float(i) / g.mix_rate
		var v := sin(t * freq * TAU) * volume
		# 指数衰减包络
		v *= exp(-t * 20.0)
		buf[i] = Vector2(v, v)
	pb.push_buffer(buf)
	_player.play()
