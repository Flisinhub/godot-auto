class_name ItemIconControl
extends Control

var item: ItemData

func _ready() -> void:
	custom_minimum_size = Vector2(40, 40)
	
func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if item != null:
		# Dibujar el icono geométrico procedural centrado
		ItemData.draw_icon(self, size / 2.0, min(size.x, size.y) * 0.4, item)
