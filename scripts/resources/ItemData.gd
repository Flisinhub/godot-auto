class_name ItemData
extends Resource

@export var id: StringName = &"unknown_item"
@export var item_name: String = "Unknown Item"
@export var type: String = "ore" # Puede ser "ore", "ingot", o "gear"
@export var color: Color = Color.WHITE

@export var texture: Texture2D

## Dibuja el objeto geométrico proceduralmente (usado en cintas y brazos)
static func draw_icon(canvas: CanvasItem, center: Vector2, size: float, item: ItemData) -> void:
	var c = item.color
	
	if item.type == "ore":
		# Dibujar una roca asimétrica dentada
		var pts = PackedVector2Array([
			center + Vector2(-size, -size*0.5), center + Vector2(-size*0.5, -size),
			center + Vector2(size*0.5, -size*0.8), center + Vector2(size, -size*0.2),
			center + Vector2(size*0.8, size*0.8), center + Vector2(0, size),
			center + Vector2(-size*0.8, size*0.5)
		])
		canvas.draw_polygon(pts, PackedColorArray([c, c, c, c, c, c, c]))
		canvas.draw_polyline(pts, c.darkened(0.4), 2.0)
		
	elif item.type == "ingot":
		# Dibujar un trapezoide (forma de lingote)
		var pts = PackedVector2Array([
			center + Vector2(-size, size*0.5), center + Vector2(-size*0.7, -size*0.5),
			center + Vector2(size*0.7, -size*0.5), center + Vector2(size, size*0.5)
		])
		canvas.draw_polygon(pts, PackedColorArray([c, c, c, c]))
		canvas.draw_polyline(pts, c.lightened(0.5), 1.0) # Brillo metálico
		
	elif item.type == "gear":
		# Dibujar engranaje con dientes
		canvas.draw_circle(center, size, c)
		canvas.draw_circle(center, size*0.4, Color(0.1, 0.1, 0.1)) # Agujero
		for i in range(8):
			var angle = i * PI / 4.0
			var p1 = center + Vector2(size*0.8, 0).rotated(angle - 0.15)
			var p2 = center + Vector2(size*1.3, 0).rotated(angle)
			var p3 = center + Vector2(size*0.8, 0).rotated(angle + 0.15)
			canvas.draw_polygon(PackedVector2Array([p1, p2, p3]), PackedColorArray([c, c, c]))
