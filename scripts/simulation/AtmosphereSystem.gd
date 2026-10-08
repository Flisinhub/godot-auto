class_name AtmosphereSystem
extends Node

var canvas_modulate: CanvasModulate
var world_environment: WorldEnvironment
var time_of_day: float = 0.0 # 0.0 to 1.0 (0=Dawn, 0.25=Noon, 0.5=Dusk, 0.75=Midnight)
var cycle_speed: float = 0.01 # Velocidad del día

func _ready() -> void:
	# Sistema de Iluminación 2D Global
	canvas_modulate = CanvasModulate.new()
	add_child(canvas_modulate)
	
	# Efectos de Post-Procesado (Glow / Bloom)
	world_environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_CANVAS
	
	# Configurar Glow para las luces y hornos calientes
	env.glow_enabled = true
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.glow_intensity = 0.8
	env.glow_strength = 1.2
	env.glow_hdr_threshold = 1.0 # Solo brilla lo que dibujemos con Color(r,g,b, >1.0)
	
	# Ligeros ajustes de contraste
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.1
	env.adjustment_saturation = 1.1
	
	world_environment.environment = env
	add_child(world_environment)

func _process(delta: float) -> void:
	time_of_day += cycle_speed * delta
	if time_of_day > 1.0: time_of_day -= 1.0
	
	# Calcular el color ambiental según la hora
	var ambient_color = Color.WHITE
	
	if time_of_day < 0.2:
		# Amanecer
		ambient_color = Color.html("#5a4d63").lerp(Color.WHITE, time_of_day / 0.2)
	elif time_of_day < 0.4:
		# Día completo
		ambient_color = Color.WHITE
	elif time_of_day < 0.6:
		# Atardecer
		var t = (time_of_day - 0.4) / 0.2
		ambient_color = Color.WHITE.lerp(Color.html("#ff9a55"), t)
	elif time_of_day < 0.8:
		# Anochecer a Noche oscura
		var t = (time_of_day - 0.6) / 0.2
		ambient_color = Color.html("#ff9a55").lerp(Color.html("#1a1a2b"), t)
	else:
		# Noche oscura profunda
		var t = (time_of_day - 0.8) / 0.2
		ambient_color = Color.html("#1a1a2b").lerp(Color.html("#5a4d63"), t)
		
	# Mantener un mínimo de luz para que el jugador vea algo
	ambient_color = ambient_color.lightened(0.2)
	canvas_modulate.color = ambient_color
