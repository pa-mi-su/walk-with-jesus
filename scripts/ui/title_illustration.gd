extends Control


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var center := size * Vector2(0.5, 0.52)
	var horizon_y := size.y * 0.46
	var sun_radius := minf(size.x, size.y) * 0.16
	draw_circle(Vector2(center.x, horizon_y - sun_radius * 0.35), sun_radius, Color("d9b96e"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, horizon_y + 24.0),
		Vector2(size.x * 0.24, horizon_y - 18.0),
		Vector2(size.x * 0.48, horizon_y + 14.0),
		Vector2(size.x * 0.72, horizon_y - 8.0),
		Vector2(size.x, horizon_y + 28.0),
		Vector2(size.x, size.y),
		Vector2(0.0, size.y),
	]), Color("6f805d"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x * 0.43, size.y),
		Vector2(size.x * 0.48, horizon_y + 18.0),
		Vector2(size.x * 0.54, horizon_y + 18.0),
		Vector2(size.x * 0.69, size.y),
	]), Color("d8c28f"))
	_draw_traveler(Vector2(center.x, size.y * 0.57), 1.0)


func _draw_traveler(position: Vector2, scale_factor: float) -> void:
	var robe := PackedVector2Array([
		position + Vector2(-12.0, 18.0) * scale_factor,
		position + Vector2(12.0, 18.0) * scale_factor,
		position + Vector2(18.0, 58.0) * scale_factor,
		position + Vector2(-18.0, 58.0) * scale_factor,
	])
	draw_colored_polygon(robe, Color("744d3b"))
	draw_circle(position, 13.0 * scale_factor, Color("b97952"))
	draw_line(position + Vector2(11.0, 20.0), position + Vector2(25.0, 51.0), Color("58402f"), 4.0)
