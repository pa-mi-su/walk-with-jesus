class_name JesusGuide
extends Node2D

signal route_completed

@export var route_points := PackedVector2Array([
	Vector2(610.0, 465.0),
	Vector2(505.0, 365.0),
	Vector2(390.0, 265.0),
	Vector2(275.0, 165.0),
])
@export var follower_trigger_distance := 120.0
@export var walking_speed := 92.0

@onready var sprite: Sprite2D = $Sprite2D

var _follower: Node2D
var _route_index := 0
var _moving := false
var _completed := false
var _movement_tween: Tween


func _process(_delta: float) -> void:
	if _follower == null or _moving or _completed:
		return
	if global_position.distance_to(_follower.global_position) <= follower_trigger_distance:
		_advance_to_next_stop()


func reset_with_follower(follower: Node2D) -> void:
	if _movement_tween != null and _movement_tween.is_valid():
		_movement_tween.kill()
	_follower = follower
	_route_index = 0
	_moving = false
	_completed = false
	position = route_points[0]
	visible = true
	_update_visual_scale()


func stop_guiding() -> void:
	if _movement_tween != null and _movement_tween.is_valid():
		_movement_tween.kill()
	_moving = false
	_follower = null


func get_route_index() -> int:
	return _route_index


func _advance_to_next_stop() -> void:
	if _route_index >= route_points.size() - 1:
		_completed = true
		route_completed.emit()
		return
	_route_index += 1
	var next_stop := route_points[_route_index]
	var distance := position.distance_to(next_stop)
	var horizontal_sign := -1.0 if next_stop.x < position.x else 1.0
	sprite.scale.x = absf(sprite.scale.x) * horizontal_sign
	_moving = true
	_movement_tween = create_tween()
	_movement_tween.set_trans(Tween.TRANS_SINE)
	_movement_tween.set_ease(Tween.EASE_IN_OUT)
	_movement_tween.tween_property(self, "position", next_stop, distance / walking_speed)
	_movement_tween.tween_callback(_finish_movement)


func _finish_movement() -> void:
	_moving = false
	_update_visual_scale()


func _update_visual_scale() -> void:
	var depth := clampf((position.y - 40.0) / 650.0, 0.0, 1.0)
	var scale_factor := 0.12 * lerpf(0.72, 1.05, depth)
	var horizontal_sign := signf(sprite.scale.x) if not is_zero_approx(sprite.scale.x) else 1.0
	sprite.scale = Vector2(horizontal_sign * scale_factor, scale_factor)
	sprite.position.y = -768.0 * scale_factor


func _draw() -> void:
	draw_set_transform(Vector2(0.0, 1.0), 0.0, Vector2(1.0, 0.36))
	draw_circle(Vector2.ZERO, 17.0, Color(0.02, 0.055, 0.065, 0.42))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
