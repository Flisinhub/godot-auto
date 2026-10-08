class_name GridCursor
extends Node2D

@export var cursor_color: Color = Color(0.2, 0.8, 0.2, 0.4)

func _process(_delta: float) -> void:
	# 1. Obtener la posición flotante del ratón
	var mouse_pos: Vector2 = get_global_mouse_position()
	
	# 2. Transformar a coordenadas lógicas puras (Vector2i)
	var grid_pos: Vector2i = GridSettings.world_to_grid(mouse_pos)
	
	# 3. Re-proyectar al mundo para obtener la esquina superior izquierda de la celda
	var snapped_pos: Vector2 = GridSettings.grid_to_world(grid_pos)
	
	# 4. Comprobar si hubo un salto para forzar el redibujado solo cuando se mueve
	if global_position != snapped_pos:
		global_position = snapped_pos
		queue_redraw()

func _draw() -> void:
	var size: float = float(GridSettings.CELL_SIZE)
	var rect: Rect2 = Rect2(Vector2.ZERO, Vector2(size, size))
	
	# Fondo semitransparente
	draw_rect(rect, cursor_color, true)
	
	# Borde delimitador
	var border_color: Color = cursor_color
	border_color.a = 1.0
	draw_rect(rect, border_color, false, 2.0)
