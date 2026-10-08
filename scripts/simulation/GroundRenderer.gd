class_name GroundRenderer
extends Node2D

var noise_tex: NoiseTexture2D

func _ready() -> void:
	z_index = -100 # Se dibuja por detrás de absolutamente todo
	
	# Configurar el generador de Ruido Fractal (Terreno orgánico)
	var noise = FastNoiseLite.new()
	noise.seed = 98765 # Semilla fija para el planeta
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.015
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5
	
	# Gradiente de colores del suelo: De Tierra Profunda -> Tierra -> Césped -> Musgo Oscuro
	var grad = Gradient.new()
	grad.add_point(0.0, Color("#2b1d10"))  # Dirt dark
	grad.add_point(0.35, Color("#3d2a17")) # Dirt mid
	grad.add_point(0.45, Color("#2b3815")) # Grass transition
	grad.add_point(0.7, Color("#1f2e0c"))  # Grass lush
	grad.add_point(1.0, Color("#141f06"))  # Moss / Dark vegetation
	
	# Generar la textura procedural dinámicamente
	noise_tex = NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.color_ramp = grad
	noise_tex.width = 1024
	noise_tex.height = 1024
	noise_tex.seamless = true
	noise_tex.generate_mipmaps = false

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Evitar crasheos mientras Godot calcula el ruido en segundo plano
	if noise_tex == null: return
	
	var transform = get_canvas_transform()
	var view_rect = transform.affine_inverse() * get_viewport_rect()
	var tex_size = Vector2(1024, 1024)
	
	# Calcular la cuadrícula de mosaico para rellenar la cámara infinitamente
	var start_x = floor(view_rect.position.x / tex_size.x) * tex_size.x
	var start_y = floor(view_rect.position.y / tex_size.y) * tex_size.y
	
	for x in range(start_x, view_rect.position.x + view_rect.size.x + tex_size.x, tex_size.x):
		for y in range(start_y, view_rect.position.y + view_rect.size.y + tex_size.y, tex_size.y):
			draw_texture(noise_tex, Vector2(x, y))
