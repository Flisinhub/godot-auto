class_name WorldGrid
extends Node2D

@export var grid_size: Vector2i = Vector2i(64, 64)
@export var grid_color: Color = Color(1.0, 1.0, 1.0, 0.1)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var cell_size: int = GridSettings.CELL_SIZE
	var width: int = grid_size.x * cell_size
	var height: int = grid_size.y * cell_size
	
	# Dibujar líneas verticales
	for x in range(grid_size.x + 1):
		draw_line(Vector2(x * cell_size, 0), Vector2(x * cell_size, height), grid_color, 1.0)
		
	# Dibujar líneas horizontales
	for y in range(grid_size.y + 1):
		draw_line(Vector2(0, y * cell_size), Vector2(width, y * cell_size), grid_color, 1.0)
