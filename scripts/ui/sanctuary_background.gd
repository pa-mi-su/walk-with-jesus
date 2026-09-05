extends Control


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	# Sanctuary's web experience uses deep blue layers with soft cyan and gold light.
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b2432"))
	var diagonal := PackedVector2Array([
		Vector2.ZERO,
		Vector2(size.x, 0.0),
		Vector2(size.x, size.y * 0.72),
		Vector2(size.x * 0.38, size.y),
		Vector2(0.0, size.y),
	])
	draw_colored_polygon(diagonal, Color(0.08, 0.25, 0.33, 0.72))
	_draw_glow(Vector2(size.x * 0.79, size.y * 0.08), minf(size.x, size.y) * 0.52, Color("4cb6d8"), 0.16)
	_draw_glow(Vector2(size.x * 0.22, size.y * 0.28), minf(size.x, size.y) * 0.42, Color("e5c66a"), 0.11)
	_draw_glow(Vector2(size.x * 0.75, size.y * 0.84), minf(size.x, size.y) * 0.36, Color("c78bb8"), 0.08)


func _draw_glow(center: Vector2, radius: float, color: Color, maximum_alpha: float) -> void:
	for ring in range(12, 0, -1):
		var fraction := float(ring) / 12.0
		var ring_color := color
		ring_color.a = maximum_alpha * (1.0 - fraction) * (1.0 - fraction)
		draw_circle(center, radius * fraction, ring_color)
