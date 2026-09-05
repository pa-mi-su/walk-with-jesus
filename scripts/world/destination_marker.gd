extends Node2D


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, 20.0, Color(0.38, 0.78, 0.86, 0.2))
	draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 32, Color("8adbea"), 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
