class_name BuildToolbar
extends Control

signal mode_changed(new_mode: BuildMode)

enum BuildMode {
	NONE = 0,
	BELT = 1,
	DRILL = 2,
	SMELTER = 3,
	CHEST = 4,
	DEMOLISH = 5,
	SPLITTER = 6,
	MERGER = 7,
	ASSEMBLER = 8,
	LABORATORY = 9,
	INSERTER = 10
}

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.keycode:
			KEY_1: mode_changed.emit(BuildMode.BELT)
			KEY_2: mode_changed.emit(BuildMode.DRILL)
			KEY_3: mode_changed.emit(BuildMode.SMELTER)
			KEY_4: mode_changed.emit(BuildMode.CHEST)
			KEY_5: mode_changed.emit(BuildMode.DEMOLISH)
			KEY_6: mode_changed.emit(BuildMode.SPLITTER)
			KEY_7: mode_changed.emit(BuildMode.MERGER)
			KEY_8: mode_changed.emit(BuildMode.ASSEMBLER)
			KEY_ESCAPE: mode_changed.emit(BuildMode.NONE)
