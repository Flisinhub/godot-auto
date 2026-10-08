class_name ToolbarUI
extends CanvasLayer

var main_node: Node
var slots: Array[Panel] = []

func _ready() -> void:
	layer = 5
	
	var container = HBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	container.position = Vector2(400, 520) # Centro inferior aprox
	add_child(container)
	
	var hotkeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
	var labels = ["Cinta", "Extrac", "Horno", "Cofre", "BOMBA", "Diviso", "Union", "Ensamb", "Labora", "Brazo"]
	var colors = [Color.GRAY, Color.YELLOW, Color.ORANGE, Color.SADDLE_BROWN, Color.RED, Color.CYAN, Color.MAGENTA, Color.BLUE, Color.PURPLE, Color.YELLOW_GREEN]
	
	for i in range(10):
		var slot = Panel.new()
		slot.custom_minimum_size = Vector2(50, 50)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
		style.border_width_all = 2
		style.border_color = Color(0.3, 0.3, 0.3)
		style.corner_radius_all = 4
		slot.add_theme_stylebox_override("panel", style)
		
		var num_lbl = Label.new()
		num_lbl.text = hotkeys[i]
		num_lbl.add_theme_font_size_override("font_size", 12)
		num_lbl.add_theme_color_override("font_color", Color.LIGHT_GRAY)
		num_lbl.position = Vector2(4, 2)
		slot.add_child(num_lbl)
		
		var icon = ColorRect.new()
		icon.color = colors[i] * 0.8
		icon.size = Vector2(24, 24)
		icon.position = Vector2(13, 13)
		if i == 4: # BOMBA
			icon.color = Color.RED
			var l = Label.new()
			l.text = "X"
			l.position = Vector2(5, 0)
			icon.add_child(l)
		slot.add_child(icon)
		
		var name_lbl = Label.new()
		name_lbl.text = labels[i]
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.position = Vector2(0, 36)
		name_lbl.size = Vector2(50, 15)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(name_lbl)
		
		slots.append(slot)
		container.add_child(slot)

func _process(_delta: float) -> void:
	if main_node == null: return
	
	var mode = main_node.current_mode
	for i in range(10):
		var style = slots[i].get_theme_stylebox("panel") as StyleBoxFlat
		var is_active = false
		
		if mode == BuildToolbar.BuildMode.BELT and i == 0: is_active = true
		elif mode == BuildToolbar.BuildMode.DRILL and i == 1: is_active = true
		elif mode == BuildToolbar.BuildMode.SMELTER and i == 2: is_active = true
		elif mode == BuildToolbar.BuildMode.CHEST and i == 3: is_active = true
		elif mode == BuildToolbar.BuildMode.DEMOLISH and i == 4: is_active = true
		elif mode == BuildToolbar.BuildMode.SPLITTER and i == 5: is_active = true
		elif mode == BuildToolbar.BuildMode.MERGER and i == 6: is_active = true
		elif mode == BuildToolbar.BuildMode.ASSEMBLER and i == 7: is_active = true
		elif mode == BuildToolbar.BuildMode.LABORATORY and i == 8: is_active = true
		elif mode == BuildToolbar.BuildMode.INSERTER and i == 9: is_active = true
		
		if is_active:
			style.border_color = Color.CYAN
			style.bg_color = Color(0.2, 0.3, 0.4, 0.9)
		else:
			style.border_color = Color(0.3, 0.3, 0.3)
			style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
