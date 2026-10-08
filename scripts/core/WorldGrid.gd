class_name WorldGrid
extends Node2D

@export var normal_color: Color = Color(1.0, 1.0, 1.0, 0.05)
@export var chunk_color: Color = Color(1.0, 1.0, 1.0, 0.15)
@export var chunk_size: int = 10

func _process(_delta: float) -> void:
	# Forzar redibujado continuo para acompañar a la cámara libre
	queue_redraw()

func _draw() -> void:
	var cell_size: float = float(GridSettings.CELL_SIZE)
	
	# Obtener los límites de visión actuales a través de la matriz de la cámara
	var transform = get_canvas_transform()
	var view_rect = get_viewport_rect()
	
	var top_left = transform.affine_inverse() * view_rect.position
	var bottom_right = transform.affine_inverse() * (view_rect.position + view_rect.size)
	
	var start_x = floor(top_left.x / cell_size) * cell_size
	var end_x = ceil(bottom_right.x / cell_size) * cell_size
	var start_y = floor(top_left.y / cell_size) * cell_size
	var end_y = ceil(bottom_right.y / cell_size) * cell_size
	
	# Líneas verticales
	var x = start_x
	while x <= end_x:
		var grid_idx = int(round(x / cell_size))
		var is_chunk = (grid_idx % chunk_size) == 0
		var color = chunk_color if is_chunk else normal_color
		var w = 2.0 if is_chunk else 1.0
		draw_line(Vector2(x, start_y), Vector2(x, end_y), color, w)
		x += cell_size
		
	# Líneas horizontales
	var y = start_y
	while y <= end_y:
		var grid_idx = int(round(y / cell_size))
		var is_chunk = (grid_idx % chunk_size) == 0
		var color = chunk_color if is_chunk else normal_color
		var w = 2.0 if is_chunk else 1.0
		draw_line(Vector2(start_x, y), Vector2(end_x, y), color, w)
		y += cell_size
