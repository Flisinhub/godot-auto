class_name Laboratory
extends RefCounted

var grid_position: Vector2i
var current_size: Vector2i = Vector2i(2, 2)
var direction: GridSettings.Direction = GridSettings.Direction.UP

var input_belts: Array[BeltCell] = []
var is_working: bool = false
var tech_manager: TechManager

func _init(pos: Vector2i, manager: TechManager) -> void:
	grid_position = pos
	tech_manager = manager

func process_tick() -> void:
	is_working = false
	if tech_manager == null or tech_manager.active_research == "": 
		return
		
	# El laboratorio absorbe objetos de cualquier cinta adyacente que le apunte
	for belt in input_belts:
		if belt != null and not belt.is_slot_empty(0):
			var item: ItemData = belt.get_item(0)
			
			# Comprueba si el TechManager necesita este ítem exacto
			if tech_manager.needs_item(item):
				belt.extract_item(0)
				tech_manager.add_progress(item, 1)
				is_working = true

func inject_item(item: ItemData) -> bool:
	if tech_manager != null and tech_manager.needs_item(item):
		tech_manager.add_progress(item, 1)
		is_working = true
		return true
	return false
