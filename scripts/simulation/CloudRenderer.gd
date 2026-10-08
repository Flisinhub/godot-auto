class_name CloudRenderer
extends Node2D

var noise_tex: NoiseTexture2D
var scroll_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	z_index = 50 # Por encima de las cintas y máquinas, pero debajo de la UI
	modulate = Color(0.0, 0.0, 0.0, 0.35) # Sombras oscuras y translúcidas
	
	var noise = FastNoiseLite.new()
	noise.seed = 11111
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.003 # Escala enorme para nubes grandes
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3
	
	# Usar un gradiente fuerte para separar nubes del cielo despejado
	var grad = Gradient.new()
	grad.add_point(0.0, Color.TRANSPARENT)
	grad.add_point(0.5, Color.TRANSPARENT)
	grad.add_point(0.6, Color.WHITE) # Parte visible de la sombra
	grad.add_point(1.0, Color.WHITE)
	
	noise_tex = NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.color_ramp = grad
	noise_tex.width = 1024
	noise_tex.height = 1024
	noise_tex.seamless = true

func _process(delta: float) -> void:
	scroll_offset += Vector2(15.0, 10.0) * delta # Las nubes se mueven con el viento
	if scroll_offset.x > 1024.0: scroll_offset.x -= 1024.0
	if scroll_offset.y > 1024.0: scroll_offset.y -= 1024.0
	queue_redraw()

func _draw() -> void:
	if noise_tex == null or noise_tex.get_image() == null: return
	
	var transform = get_canvas_transform()
	var view_rect = transform.affine_inverse() * get_viewport_rect()
	var tex_size = Vector2(1024, 1024)
	
	var start_x = floor((view_rect.position.x - scroll_offset.x) / tex_size.x) * tex_size.x + scroll_offset.x
	var start_y = floor((view_rect.position.y - scroll_offset.y) / tex_size.y) * tex_size.y + scroll_offset.y
	
	for x in range(start_x, view_rect.position.x + view_rect.size.x + tex_size.x, tex_size.x):
		for y in range(start_y, view_rect.position.y + view_rect.size.y + tex_size.y, tex_size.y):
			draw_texture(noise_tex, Vector2(x, y))
