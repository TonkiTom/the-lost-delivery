extends Node2D

@onready var world = get_parent()

var weather_types = ["clear", "rain", "fog", "storm"]
var current_weather = "clear"
var weather_intensity = 0.0
var weather_timer = 0.0
var weather_duration = 30.0

var rain_particles: CanvasLayer
var fog_overlay: ColorRect

func _ready() -> void:
	rain_particles = CanvasLayer.new()
	rain_particles.layer = 2
	add_child(rain_particles)
	
	fog_overlay = ColorRect.new()
	fog_overlay.anchors_preset = 15
	fog_overlay.color = Color(1, 1, 1, 0)
	rain_particles.add_child(fog_overlay)
	
	randomize()
	change_weather("clear")

func _process(delta: float) -> void:
	weather_timer += delta
	if weather_timer >= weather_duration:
		change_weather(weather_types[randi() % weather_types.size()])
		weather_timer = 0.0
	
	update_weather_effects(delta)

func change_weather(new_weather: String) -> void:
	current_weather = new_weather
	weather_intensity = 0.0
	
	match current_weather:
		"clear":
			fog_overlay.color = Color(1, 1, 1, 0)
		"rain":
			create_rain_effect()
		"fog":
			fog_overlay.color = Color(0.8, 0.8, 0.9, 0.3)
		"storm":
			create_storm_effect()

func create_rain_effect() -> void:
	var rain_container = Control.new()
	rain_container.anchors_preset = 15
	
	for i in range(50):
		var rain_drop = Line2D.new()
		rain_drop.add_point(Vector2(randf() * 1280, randf() * 720))
		rain_drop.add_point(Vector2(randf() * 1280, randf() * 720 + 20))
		rain_drop.width = 1.0
		rain_drop.default_color = Color(0.7, 0.7, 0.8, 0.6)
		rain_container.add_child(rain_drop)
	
	for child in rain_particles.get_children():
		if child != fog_overlay:
			child.queue_free()
	
	rain_particles.add_child(rain_container)
	fog_overlay.color = Color(1, 1, 1, 0.1)

func create_storm_effect() -> void:
	fog_overlay.color = Color(0.3, 0.3, 0.4, 0.5)
	create_rain_effect()

func update_weather_effects(delta: float) -> void:
	if current_weather == "rain" or current_weather == "storm":
		weather_intensity = minf(weather_intensity + delta * 0.5, 1.0)
	else:
		weather_intensity = maxf(weather_intensity - delta * 0.3, 0.0)

func get_weather_info() -> Dictionary:
	return {
		"type": current_weather,
		"intensity": weather_intensity
	}
