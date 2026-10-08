class_name MachineUI
extends CanvasLayer

var panel: Panel
var title: Label
var status_lbl: Label
var recipe_btn: OptionButton
var input_lbl: Label
var output_lbl: Label
var close_btn: Button

var current_machine: Variant = null
var available_recipes: Array[RecipeData] = []

func _ready() -> void:
	layer = 10 # Asegurar que dibuja por encima del juego
	
	panel = Panel.new()
	panel.size = Vector2(300, 400)
	panel.position = Vector2(800, 50) # Lado derecho
	panel.visible = false
	add_child(panel)
	
	title = Label.new()
	title.position = Vector2(10, 10)
	title.text = "Inspector de Máquina"
	panel.add_child(title)
	
	status_lbl = Label.new()
	status_lbl.position = Vector2(10, 40)
	status_lbl.add_theme_color_override("font_color", Color.YELLOW)
	panel.add_child(status_lbl)
	
	var r_label = Label.new()
	r_label.position = Vector2(10, 70)
	r_label.text = "Receta Activa:"
	panel.add_child(r_label)
	
	recipe_btn = OptionButton.new()
	recipe_btn.position = Vector2(10, 100)
	recipe_btn.size = Vector2(280, 40)
	recipe_btn.item_selected.connect(_on_recipe_selected)
	panel.add_child(recipe_btn)
	
	input_lbl = Label.new()
	input_lbl.position = Vector2(10, 160)
	input_lbl.text = "Inventario Entrada:\n- Vacio"
	panel.add_child(input_lbl)
	
	output_lbl = Label.new()
	output_lbl.position = Vector2(10, 260)
	output_lbl.text = "Inventario Salida:\n- Vacio"
	panel.add_child(output_lbl)
	
	close_btn = Button.new()
	close_btn.position = Vector2(10, 350)
	close_btn.size = Vector2(280, 40)
	close_btn.text = "Cerrar Panel"
	close_btn.pressed.connect(func(): panel.visible = false; current_machine = null)
	panel.add_child(close_btn)

func _process(_delta: float) -> void:
	if not panel.visible or current_machine == null: return
	
	# Actualizar estado en vivo
	if "is_working" in current_machine:
		status_lbl.text = "Estado: TRABAJANDO" if current_machine.is_working else "Estado: DETENIDO/ESPERANDO"
		status_lbl.add_theme_color_override("font_color", Color.GREEN if current_machine.is_working else Color.RED)
		
	if "input_inventory" in current_machine:
		var in_text = "Inventario Entrada:\n"
		for item in current_machine.input_inventory.keys():
			in_text += "- " + item.item_name + ": " + str(current_machine.input_inventory[item]) + "\n"
		input_lbl.text = in_text
		
	if "output_inventory" in current_machine:
		var out_text = "Inventario Salida:\n"
		for item in current_machine.output_inventory.keys():
			out_text += "- " + item.item_name + ": " + str(current_machine.output_inventory[item]) + "\n"
		output_lbl.text = out_text

func setup_recipes(recipes: Array[RecipeData]) -> void:
	available_recipes = recipes

func open_for_machine(machine: Variant) -> void:
	current_machine = machine
	panel.visible = true
	recipe_btn.clear()
	
	if machine is Smelter:
		title.text = "Fundición (1x1)"
	elif machine is Assembler:
		title.text = "Ensambladora (3x3)"
	elif machine is MiningDrill:
		title.text = "Extractor Minero"
		recipe_btn.disabled = true
		return
	else:
		return
		
	recipe_btn.disabled = false
	recipe_btn.add_item("Ninguna (Pausada)", 0)
	
	var idx = 1
	var active_idx = 0
	for r in available_recipes:
		# Filtro simple: Si es Fundición, solo recetas de 1 entrada. Si es ensambladora, de 2+.
		# Por flexibilidad, dejaremos todas por ahora, o filtramos según lógica:
		var is_smelting = (r.inputs.size() == 1 and r.outputs.size() == 1)
		if (machine is Smelter and is_smelting) or (machine is Assembler and not is_smelting):
			recipe_btn.add_item(_format_recipe_name(r), idx)
			recipe_btn.set_item_metadata(idx, r)
			if machine.active_recipe == r:
				active_idx = idx
			idx += 1
			
	recipe_btn.select(active_idx)

func _format_recipe_name(r: RecipeData) -> String:
	var out_name = ""
	for item in r.outputs.keys(): out_name = item.item_name
	return "Fabricar: " + out_name

func _on_recipe_selected(index: int) -> void:
	if current_machine == null: return
	if index == 0:
		current_machine.active_recipe = null
	else:
		current_machine.active_recipe = recipe_btn.get_item_metadata(index)
