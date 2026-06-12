extends Node

const MIX_RATE := 44100.0

var player: AudioStreamPlayer

func _ready() -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = MIX_RATE
	stream.buffer_length = 0.08
	player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -14.0
	add_child(player)

func ui_tap() -> void:
	_vibrate(12)
	_play_tone(760.0, 0.035, 0.08)

func confirm() -> void:
	_vibrate(18)
	_play_tone(560.0, 0.055, 0.09)

func warning() -> void:
	_vibrate(35)
	_play_tone(190.0, 0.08, 0.11)

func _vibrate(milliseconds: int) -> void:
	if milliseconds <= 0:
		return
	DisplayServer.vibrate_handheld(milliseconds)

func _play_tone(frequency: float, duration: float, amplitude: float) -> void:
	if player == null or not SaveManager.is_sound_enabled():
		return
	player.stop()
	player.play()
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frames := int(MIX_RATE * duration)
	for i in range(frames):
		var progress := float(i) / maxf(1.0, float(frames))
		var envelope := 1.0 - progress
		var sample := sin((float(i) / MIX_RATE) * TAU * frequency) * amplitude * envelope
		playback.push_frame(Vector2(sample, sample))
