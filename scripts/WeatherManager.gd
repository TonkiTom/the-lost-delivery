extends Node

signal weather_changed

var weather_cycle: Array = ["clear", "rain", "fog", "storm"]
var current_weather: String = "clear"
var duration: float = 28.0
var timer: float = 0.0

func _process(delta: float) -> void:
	timer += delta
	if timer >= duration:
		set_weather(weather_cycle[randi() % weather_cycle.size()])
		timer = 0.0

func set_weather(value: String) -> void:
	if not weather_cycle.has(value):
		return
	current_weather = value
	emit_signal("weather_changed", current_weather)

func get_weather() -> String:
	return current_weather
