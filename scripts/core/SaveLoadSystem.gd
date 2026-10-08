class_name SaveLoadSystem
extends RefCounted

const SAVE_PATH: String = "user://factory_save.json"

static func save_game(main: Main) -> void:
	var data: Dictionary = {
		"belts": [], "drills": [], "smelters": [],
		"chests": [], "splitters": [], "mergers": [], "assemblers": [],
		"player_inventory": {}
	}
	
	for belt in main.belts: data.belts.append({"x": belt.grid_position.x, "y": belt.grid_position.y, "dir": belt.direction})
	for drill in main.drills: data.drills.append({"x": drill.grid_position.x, "y": drill.grid_position.y, "dir": drill.direction})
	for smelter in main.smelters: data.smelters.append({"x": smelter.grid_position.x, "y": smelter.grid_position.y, "dir": smelter.direction})
	for chest in main.chests: data.chests.append({"x": chest.grid_position.x, "y": chest.grid_position.y, "inventory": chest.current_total})
	for splitter in main.splitters: data.splitters.append({"x": splitter.grid_position.x, "y": splitter.grid_position.y, "dir": splitter.direction})
	for merger in main.mergers: data.mergers.append({"x": merger.grid_position.x, "y": merger.grid_position.y, "dir": merger.direction})
	for assembler in main.assemblers: data.assemblers.append({"x": assembler.grid_position.x, "y": assembler.grid_position.y, "dir": assembler.direction})
		
	for item in main.player_inventory.keys():
		data.player_inventory[item.id] = main.player_inventory[item]
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

static func load_game(main: Main) -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file: return
	var content = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(content)
	if data == null: return
	
	main.grid_manager.clear_grid()
	main.belts.clear()
	main.drills.clear()
	main.smelters.clear()
	main.chests.clear()
	main.splitters.clear()
	main.mergers.clear()
	main.assemblers.clear()
	main.simulation._belts.clear()
	main.player_inventory.clear()
	
	if data.has("belts"):
		for b in data.belts:
			var belt = BeltCell.new(Vector2i(int(b.x), int(b.y)), int(b.dir) as GridSettings.Direction)
			main.grid_manager.occupy_cell(belt.grid_position, belt)
			main.simulation.register_belt(belt)
			main.belts.append(belt)
			
	if data.has("drills"):
		for d in data.drills:
			var drill = MiningDrill.new(Vector2i(int(d.x), int(d.y)), int(d.dir) as GridSettings.Direction, main.resource_map)
			main.grid_manager.occupy_cell(drill.grid_position, drill)
			main.drills.append(drill)
			
	if data.has("smelters"):
		for s in data.smelters:
			var smelter = Smelter.new(Vector2i(int(s.x), int(s.y)), int(s.dir) as GridSettings.Direction)
			main.grid_manager.occupy_cell(smelter.grid_position, smelter)
			main.smelters.append(smelter)
			
	if data.has("chests"):
		for c in data.chests:
			var chest = StorageChest.new(Vector2i(int(c.x), int(c.y)))
			main.grid_manager.occupy_cell(chest.grid_position, chest)
			main.chests.append(chest)
			
	if data.has("splitters"):
		for sp in data.splitters:
			var splitter = Splitter.new(Vector2i(int(sp.x), int(sp.y)), int(sp.dir) as GridSettings.Direction)
			main.grid_manager.occupy_cell(splitter.grid_position, splitter)
			main.splitters.append(splitter)
			
	if data.has("mergers"):
		for m in data.mergers:
			var merger = Merger.new(Vector2i(int(m.x), int(m.y)), int(m.dir) as GridSettings.Direction)
			main.grid_manager.occupy_cell(merger.grid_position, merger)
			main.mergers.append(merger)
			
	if data.has("assemblers"):
		for a in data.assemblers:
			var size = GridSettings.get_rotated_size(Vector2i(3,3), int(a.dir) as GridSettings.Direction)
			var assembler = Assembler.new(Vector2i(int(a.x), int(a.y)), int(a.dir) as GridSettings.Direction)
			main.grid_manager.occupy_area(assembler.grid_position, size, assembler)
			main.assemblers.append(assembler)
			
	if data.has("player_inventory"):
		for item_id in data.player_inventory.keys():
			var item = main._get_item_by_id(item_id)
			if item != null:
				main.player_inventory[item] = int(data.player_inventory[item_id])
			
	main._reconnect_all()
	main._update_ui_text()
