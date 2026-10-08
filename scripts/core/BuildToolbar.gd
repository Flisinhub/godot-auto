class_name BuildToolbar
extends Control

signal mode_changed(new_mode: BuildMode)

enum BuildMode {
	NONE,
	BELT,
	DRILL,
	SMELTER,
	CHEST,
	DEMOLISH
}

## Bucle de entrada para cambiar modos de construcción vía teclado
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.keycode:
			KEY_1: mode_changed.emit(BuildMode.BELT)
			KEY_2: mode_changed.emit(BuildMode.DRILL)
			KEY_3: mode_changed.emit(BuildMode.SMELTER)
			KEY_4: mode_changed.emit(BuildMode.CHEST)
			KEY_5: mode_changed.emit(BuildMode.DEMOLISH)
			KEY_ESCAPE: mode_changed.emit(BuildMode.NONE)
