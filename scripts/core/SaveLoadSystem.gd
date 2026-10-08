class_name SaveLoadSystem
extends RefCounted

const SAVE_PATH: String = "user://factory_save.json"

static func save_game(main: Main) -> void:
	var data: Dictionary = {
		"belts": [], "drills": [], "smelters": [],
		"chests": [], "splitters": [], "mergers": [], "assemblers": [], "laboratories": [],
		"inserters": [],
		"player_inventory": {},
		"unlocked_techs": main.tech_manager.unlocked_techs,
		"active_research": main.tech_manager.active_research,
		"research_progress": {}
	}
	
	for belt in main.belts: data.belts.append({"x": belt.grid_position.x, "y": belt.grid_position.y, "dir": belt.direction})
	for drill in main.drills: data.drills.append({"x": drill.grid_position.x, "y": drill.grid_position.y, "dir": drill.direction})
	for smelter in main.smelters:
		var recipe_id = smelter.active_recipe.id if smelter.active_recipe != null else ""
		var in_inv = {}; for i in smelter.input_inventory.keys(): in_inv[i.id] = smelter.input_inventory[i]
		var out_inv = {}; for i in smelter.output_inventory.keys(): out_inv[i.id] = smelter.output_inventory[i]
		data.smelters.append({"x": smelter.grid_position.x, "y": smelter.grid_position.y, "dir": smelter.direction, "recipe": recipe_id, "in": in_inv, "out": out_inv})
	for chest in main.chests:
		var inv = {}; for i in chest.inventory.keys(): inv[i.id] = chest.inventory[i]
		data.chests.append({"x": chest.grid_position.x, "y": chest.grid_position.y, "inventory": chest.current_total, "items": inv})
	for splitter in main.splitters: data.splitters.append({"x": splitter.grid_position.x, "y": splitter.grid_position.y, "dir": splitter.direction})
	for merger in main.mergers: data.mergers.append({"x": merger.grid_position.x, "y": merger.grid_position.y, "dir": merger.direction})
	for assembler in main.assemblers:
		var recipe_id = assembler.active_recipe.id if assembler.active_recipe != null else ""
		var in_inv = {}; for i in assembler.input_inventory.keys(): in_inv[i.id] = assembler.input_inventory[i]
		var out_inv = {}; for i in assembler.output_inventory.keys(): out_inv[i.id] = assembler.output_inventory[i]
		data.assemblers.append({"x": assembler.grid_position.x, "y": assembler.grid_position.y, "dir": assembler.direction, "recipe": recipe_id, "in": in_inv, "out": out_inv})
	for lab in main.laboratories: data.laboratories.append({"x": lab.grid_position.x, "y": lab.grid_position.y, "dir": lab.direction})
	
	for ins in main.inserters:
		var held = ins.held_item.id if ins.held_item != null else ""
		data.inserters.append({"x": ins.grid_position.x, "y": ins.grid_position.y, "dir": ins.direction, "held": held})
		
	for item in main.player_inventory.keys():
		data.player_inventory[item.id] = main.player_inventory[item]
		
	for item_id in main.tech_manager.research_progress.keys():
		data.research_progress[item_id] = main.tech_manager.research_progress[item_id]
		
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
	
	# Romper ciclos de referencias circulares en las cintas para evitar Memory Leaks
	for belt in main.belts: belt.next_cell = null
	
	main.grid_manager.clear_grid()
	main.belts.clear()
	main.drills.clear()
	main.smelters.clear()
	main.chests.clear()
	main.splitters.clear()
	main.mergers.clear()
	main.assemblers.clear()
	main.laboratories.clear()
	main.inserters.clear()
	main.simulation._belts.clear()
	main.player_inventory.clear()
	
	main.tech_manager.unlocked_techs.clear()
	main.tech_manager.active_research = ""
	main.tech_manager.research_progress.clear()
	
	if data.has("unlocked_techs"):
		for t in data.unlocked_techs: main.tech_manager.unlocked_techs.append(t)
	if data.has("active_research"):
		main.tech_manager.active_research = data.active_research
	if data.has("research_progress"):
		for item_id in data.research_progress.keys():
			main.tech_manager.research_progress[item_id] = int(data.research_progress[item_id])
	
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
			if s.has("recipe") and s.recipe != "": smelter.active_recipe = main._get_recipe_by_id(s.recipe)
			if s.has("in"):
				for item_id in s.in.keys():
					var it = main._get_item_by_id(item_id); if it != null: smelter.input_inventory[it] = int(s.in[item_id])
			if s.has("out"):
				for item_id in s.out.keys():
					var it = main._get_item_by_id(item_id); if it != null: smelter.output_inventory[it] = int(s.out[item_id])
			main.grid_manager.occupy_cell(smelter.grid_position, smelter)
			main.smelters.append(smelter)
			
	if data.has("chests"):
		for c in data.chests:
			var chest = StorageChest.new(Vector2i(int(c.x), int(c.y)))
			if c.has("inventory"): chest.current_total = int(c.inventory)
			if c.has("items"):
				for item_id in c.items.keys():
					var it = main._get_item_by_id(item_id); if it != null: chest.inventory[it] = int(c.items[item_id])
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
			if a.has("recipe") and a.recipe != "": assembler.active_recipe = main._get_recipe_by_id(a.recipe)
			if a.has("in"):
				for item_id in a.in.keys():
					var it = main._get_item_by_id(item_id); if it != null: assembler.input_inventory[it] = int(a.in[item_id])
			if a.has("out"):
				for item_id in a.out.keys():
					var it = main._get_item_by_id(item_id); if it != null: assembler.output_inventory[it] = int(a.out[item_id])
			main.grid_manager.occupy_area(assembler.grid_position, size, assembler)
			main.assemblers.append(assembler)
			
	if data.has("laboratories"):
		for l in data.laboratories:
			var size = GridSettings.get_rotated_size(Vector2i(2,2), int(l.dir) as GridSettings.Direction)
			var lab = Laboratory.new(Vector2i(int(l.x), int(l.y)), main.tech_manager)
			main.grid_manager.occupy_area(lab.grid_position, size, lab)
			main.laboratories.append(lab)
			
	if data.has("inserters"):
		for i_data in data.inserters:
			var ins = Inserter.new(Vector2i(int(i_data.x), int(i_data.y)), int(i_data.dir) as GridSettings.Direction, main)
			if i_data.has("held") and i_data.held != "":
				ins.held_item = main._get_item_by_id(i_data.held)
			main.grid_manager.occupy_cell(ins.grid_position, ins)
			main.inserters.append(ins)
			
	if data.has("player_inventory"):
		for item_id in data.player_inventory.keys():
			var item = main._get_item_by_id(item_id)
			if item != null:
				main.player_inventory[item] = int(data.player_inventory[item_id])
			
	main._reconnect_all()
	main._update_ui_text()
