class_name TechUI
extends CanvasLayer

var panel: Panel
var title: Label
var close_btn: Button
var main_container: VBoxContainer
var tech_manager: TechManager
var is_open: bool = false

func _ready() -> void:
	layer = 20 # Por encima del resto
	
	panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.9)
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = Color.AQUA.darkened(0.5)
	style.corner_radius_top_left = 5; style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5; style.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override("panel", style)
	
	panel.size = Vector2(400, 500)
	panel.position = Vector2(440, 100) # Centro aprox de una pantalla HD
	panel.visible = false
	add_child(panel)
	
	title = Label.new()
	title.position = Vector2(10, 10)
	title.text = "ARBOL DE TECNOLOGIAS"
	title.add_theme_color_override("font_color", Color.AQUA)
	panel.add_child(title)
	
	close_btn = Button.new()
	close_btn.position = Vector2(360, 5)
	close_btn.size = Vector2(35, 35)
	close_btn.text = "X"
	close_btn.pressed.connect(toggle_ui)
	panel.add_child(close_btn)
	
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(10, 50)
	scroll.size = Vector2(380, 440)
	panel.add_child(scroll)
	
	main_container = VBoxContainer.new()
	main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(main_container)

func setup(manager: TechManager) -> void:
	tech_manager = manager

func toggle_ui() -> void:
	is_open = !is_open
	panel.visible = is_open
	if is_open:
		refresh_list()

func refresh_list() -> void:
	if tech_manager == null: return
	
	for child in main_container.get_children():
		child.queue_free()
		
	for tech_id in tech_manager.techs.keys():
		var tech = tech_manager.techs[tech_id]
		_create_tech_entry(tech)

func _create_tech_entry(tech: TechData) -> void:
	var bg = PanelContainer.new()
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.25, 0.8)
	style.border_width_left = 3
	style.border_color = Color.AQUA
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	bg.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	bg.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	var name_lbl = Label.new()
	name_lbl.text = tech.tech_name
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color.CYAN)
	name_lbl.add_theme_constant_override("outline_size", 3)
	name_lbl.add_theme_color_override("font_outline_color", Color(0,0,0,1))
	vbox.add_child(name_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = tech.description
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	vbox.add_child(desc_lbl)
	
	var hbox_cost = HBoxContainer.new()
	vbox.add_child(hbox_cost)
	
	var cost_title = Label.new()
	cost_title.text = "Coste: "
	cost_title.add_theme_font_size_override("font_size", 12)
	hbox_cost.add_child(cost_title)
	
	for item in tech.cost.keys():
		var req = tech.cost[item]
		var cur = tech_manager.research_progress.get(item.id, 0)
		
		var slot = Panel.new()
		slot.custom_minimum_size = Vector2(30, 30)
		var s_style = StyleBoxFlat.new()
		s_style.bg_color = Color(0,0,0,0.5)
		s_style.corner_radius_all = 3
		slot.add_theme_stylebox_override("panel", s_style)
		
		var icon = ItemIconControl.new()
		icon.item = item
		icon.size = Vector2(20, 20)
		icon.position = Vector2(5, 5)
		slot.add_child(icon)
		
		var amt = Label.new()
		if tech_manager.active_research == tech.id:
			amt.text = str(cur) + "/" + str(req)
		else:
			amt.text = str(req)
		amt.position = Vector2(35, 5)
		amt.add_theme_font_size_override("font_size", 12)
		amt.add_theme_color_override("font_color", Color.YELLOW)
		
		var p2 = Control.new()
		p2.custom_minimum_size = Vector2(40 + amt.text.length()*8, 30)
		p2.add_child(slot)
		p2.add_child(amt)
		hbox_cost.add_child(p2)
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 30)
	if tech_manager.is_unlocked(tech.id):
		btn.text = "COMPLETADO"
		btn.disabled = true
		style.border_color = Color.GREEN
		style.bg_color = Color(0.1, 0.25, 0.1, 0.8)
	elif tech_manager.active_research == tech.id:
		btn.text = "INVESTIGANDO..."
		btn.disabled = true
		style.border_color = Color.YELLOW
		style.bg_color = Color(0.25, 0.25, 0.1, 0.8)
	else:
		btn.text = "INICIAR INVESTIGACIÓN"
		btn.pressed.connect(func(): tech_manager.start_research(tech.id); refresh_list())
		
	vbox.add_child(btn)
	main_container.add_child(bg)

func _process(_delta: float) -> void:
	if is_open and tech_manager != null and tech_manager.active_research != "":
		refresh_list()
