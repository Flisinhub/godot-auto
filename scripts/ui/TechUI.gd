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
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	bg.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	var name_lbl = Label.new()
	name_lbl.text = tech.tech_name
	vbox.add_child(name_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = tech.description
	desc_lbl.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	vbox.add_child(desc_lbl)
	
	var cost_lbl = Label.new()
	var cost_text = "Coste: "
	for item in tech.cost.keys():
		var req = tech.cost[item]
		var cur = tech_manager.research_progress.get(item.id, 0)
		if tech_manager.active_research == tech.id:
			cost_text += str(cur) + "/" + str(req) + " " + item.item_name + ", "
		else:
			cost_text += str(req) + " " + item.item_name + ", "
	cost_lbl.text = cost_text
	cost_lbl.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(cost_lbl)
	
	var btn = Button.new()
	if tech_manager.is_unlocked(tech.id):
		btn.text = "Completado"
		btn.disabled = true
		bg.modulate = Color(0.5, 1.0, 0.5)
	elif tech_manager.active_research == tech.id:
		btn.text = "Investigando..."
		btn.disabled = true
		bg.modulate = Color(1.0, 1.0, 0.5)
	else:
		btn.text = "Iniciar Investigacion"
		btn.pressed.connect(func(): tech_manager.start_research(tech.id); refresh_list())
		
	vbox.add_child(btn)
	main_container.add_child(bg)

func _process(_delta: float) -> void:
	# Refrescar barra de progreso si estamos investigando y el panel está abierto
	if is_open and tech_manager != null and tech_manager.active_research != "":
		refresh_list()
