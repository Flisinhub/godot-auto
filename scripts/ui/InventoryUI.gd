class_name InventoryUI
extends CanvasLayer

var main_node: Node
var panel: Panel
var grid: GridContainer

func _ready() -> void:
	layer = 15
	
	panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.6, 1.0, 0.8)
	style.corner_radius_top_left = 8; style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	
	# Centrar en pantalla
	panel.size = Vector2(400, 300)
	panel.position = Vector2(440, 210) 
	panel.visible = false
	add_child(panel)
	
	var title = Label.new()
	title.text = "INVENTARIO DEL JUGADOR"
	title.position = Vector2(20, 15)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	panel.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "[TAB] para cerrar"
	subtitle.position = Vector2(260, 18)
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", Color.GRAY)
	panel.add_child(subtitle)
	
	grid = GridContainer.new()
	grid.columns = 5
	grid.position = Vector2(20, 50)
	grid.size = Vector2(360, 230)
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	panel.add_child(grid)

func toggle() -> void:
	panel.visible = !panel.visible
	if panel.visible:
		refresh()

func refresh() -> void:
	# Limpiar slots antiguos
	for c in grid.get_children():
		c.queue_free()
		
	if main_node == null: return
	
	# Generar casillas chulas
	var inv = main_node.player_inventory
	for item in inv.keys():
		var amount = inv[item]
		if amount <= 0: continue
		
		var slot = Panel.new()
		slot.custom_minimum_size = Vector2(64, 64)
		
		var s_style = StyleBoxFlat.new()
		s_style.bg_color = Color(0.12, 0.12, 0.18, 0.9)
		s_style.border_width_left = 1; s_style.border_width_right = 1
		s_style.border_width_top = 1; s_style.border_width_bottom = 1
		s_style.border_color = Color(0.3, 0.4, 0.5, 0.5)
		s_style.corner_radius_top_left = 4; s_style.corner_radius_top_right = 4
		s_style.corner_radius_bottom_left = 4; s_style.corner_radius_bottom_right = 4
		slot.add_theme_stylebox_override("panel", s_style)
		
		var icon = ItemIconControl.new()
		icon.item = item
		icon.position = Vector2(12, 8)
		icon.size = Vector2(40, 40)
		slot.add_child(icon)
		
		var lbl = Label.new()
		lbl.text = str(amount)
		lbl.position = Vector2(5, 42)
		lbl.size = Vector2(54, 20)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl.add_theme_font_size_override("font_size", 14)
		# Darle un contorno al texto para que resalte
		lbl.add_theme_constant_override("outline_size", 4)
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		slot.add_child(lbl)
		
		grid.add_child(slot)
