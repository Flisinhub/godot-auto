class_name Inserter
extends RefCounted

var grid_position: Vector2i
var direction: GridSettings.Direction
var held_item: ItemData = null

var is_working: bool = false
var main_ref: Main

func _init(pos: Vector2i, dir: GridSettings.Direction, main: Main) -> void:
	grid_position = pos
	direction = dir
	main_ref = main

func process_tick() -> void:
	is_working = false
	
	if held_item == null:
		# INTENTAR RECOGER DE LA PARTE TRASERA
		var pickup_pos = grid_position - GridSettings.get_direction_vector(direction)
		var source = main_ref.grid_manager.get_entity_at(pickup_pos)
		
		var item = _try_extract(source)
		if item != null:
			held_item = item
			is_working = true
	else:
		# INTENTAR DEJAR EN LA PARTE FRONTAL
		var drop_pos = grid_position + GridSettings.get_direction_vector(direction)
		var target = main_ref.grid_manager.get_entity_at(drop_pos)
		
		if _try_insert(target, held_item):
			held_item = null
			is_working = true

func _try_extract(source: Variant) -> ItemData:
	if source == null: return null
	
	if source is BeltCell:
		if not source.is_slot_empty(0): return source.extract_item(0)
		if not source.is_slot_empty(1): return source.extract_item(1)
		
	elif source is StorageChest:
		if source.current_total > 0:
			var items = source.inventory.keys()
			if items.size() > 0:
				var it = items[0]
				source.inventory[it] -= 1
				if source.inventory[it] <= 0: source.inventory.erase(it)
				source.current_total -= 1
				return it
				
	elif source is Smelter or source is Assembler:
		if source.output_inventory.size() > 0:
			var items = source.output_inventory.keys()
			if items.size() > 0:
				var it = items[0]
				source.output_inventory[it] -= 1
				if source.output_inventory[it] <= 0: source.output_inventory.erase(it)
				return it
				
	elif source is MiningDrill:
		if source.output_buffer != null:
			var it = source.output_buffer
			source.output_buffer = null
			return it
			
	return null

func _try_insert(target: Variant, item: ItemData) -> bool:
	if target == null: return false
	
	if target is BeltCell:
		# Preferir SIEMPRE el slot 1 (entrada) para no "teletransportar" encima de cintas bloqueadas
		if target.is_slot_empty(1):
			target.set_item(1, item)
			return true
		# Si está completamente vacío, podemos usar el 0 como fallback visual (cinta final)
		elif target.is_slot_empty(0) and target.next_cell == null:
			target.set_item(0, item)
			return true
			
	elif target is StorageChest:
		if target.current_total < target.max_capacity:
			target.inventory[item] = target.inventory.get(item, 0) + 1
			target.current_total += 1
			return true
			
	elif target is Smelter or target is Assembler:
		if target.active_recipe != null and target.active_recipe.inputs.has(item):
			var max_in = target.active_recipe.inputs[item] * 10
			var cur = target.input_inventory.get(item, 0)
			if cur < max_in:
				target.input_inventory[item] = cur + 1
				return true
				
	elif target is Laboratory:
		return target.inject_item(item)
			
	return false
