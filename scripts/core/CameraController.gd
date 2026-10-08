class_name CameraController
extends Camera2D

@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 4.0

var _is_dragging: bool = false
var _last_mouse_pos: Vector2

var target_zoom: float = 1.0
var target_position: Vector2 = Vector2.ZERO
var shake_intensity: float = 0.0

func _ready() -> void:
	target_position = position
	target_zoom = zoom.x

func add_shake(amount: float) -> void:
	shake_intensity = min(shake_intensity + amount, 20.0)

func _process(delta: float) -> void:
	# Movimiento WASD / Flechas
	var pan_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): pan_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): pan_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): pan_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): pan_dir.x += 1
	
	if pan_dir != Vector2.ZERO:
		target_position += pan_dir.normalized() * (1000.0 / target_zoom) * delta
		
	# Suavizado cinemático
	zoom = zoom.lerp(Vector2(target_zoom, target_zoom), 15.0 * delta)
	
	# Aplicar Temblor de Pantalla (Screen Shake)
	var current_target = target_position
	if shake_intensity > 0.0:
		current_target += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_intensity
		shake_intensity = lerp(shake_intensity, 0.0, 10.0 * delta)
		
	position = position.lerp(current_target, 20.0 * delta)

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
