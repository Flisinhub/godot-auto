class_name CameraController
extends Camera2D

@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 4.0

var _is_dragging: bool = false
var _last_mouse_pos: Vector2

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.is_pressed():
				_is_dragging = true
				_last_mouse_pos = event.position
			else:
				_is_dragging = false
				
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = (zoom + Vector2(zoom_speed, zoom_speed)).clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = (zoom - Vector2(zoom_speed, zoom_speed)).clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
			
	elif event is InputEventMouseMotion and _is_dragging:
		var delta_pos: Vector2 = _last_mouse_pos - event.position
		position += delta_pos / zoom
		_last_mouse_pos = event.position
