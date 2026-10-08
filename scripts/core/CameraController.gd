class_name CameraController
extends Camera2D

@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 4.0

var _is_dragging: bool = false
var _last_mouse_pos: Vector2

var target_zoom: float = 1.0
var target_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	target_position = position
	target_zoom = zoom.x

func _process(delta: float) -> void:
	# Suavizado cinemático
	zoom = zoom.lerp(Vector2(target_zoom, target_zoom), 15.0 * delta)
	position = position.lerp(target_position, 20.0 * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.is_pressed():
				_is_dragging = true
				_last_mouse_pos = event.position
			else:
				_is_dragging = false
				
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clamp(target_zoom + zoom_speed * 2.0, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clamp(target_zoom - zoom_speed * 2.0, min_zoom, max_zoom)
			
	elif event is InputEventMouseMotion and _is_dragging:
		var delta_pos: Vector2 = _last_mouse_pos - event.position
		target_position += delta_pos / zoom
		position += delta_pos / zoom # Evita que el pan se sienta gomoso al arrastrar
		_last_mouse_pos = event.position
