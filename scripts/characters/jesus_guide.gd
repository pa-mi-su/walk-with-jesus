class_name JesusGuide
extends Node2D

signal route_completed
signal stop_reached(route_index: int)

@export var route_points := PackedVector2Array([
	Vector2(1310.0, 1030.0),
	Vector2(1120.0, 875.0),
	Vector2(915.0, 710.0),
	Vector2(705.0, 535.0),
	Vector2(500.0, 360.0),
	Vector2(300.0, 175.0),
	Vector2(215.0, 110.0),
])
@export var follower_trigger_distance := 120.0
@export var walking_speed := 92.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var guide_cue: Label = $GuideCue

var _follower: Node2D
var _route_index := 0
var _moving := false
var _completed := false
var _movement_tween: Tween
var _walk_phase := 0.0
var _walk_amount := 0.0


func _process(delta: float) -> void:
	_update_walk_animation(delta, _moving)
	if _moving:
		_update_visual_scale()


func reset_with_follower(follower: Node2D) -> void:
	if _movement_tween != null and _movement_tween.is_valid():
		_movement_tween.kill()
	_follower = follower
	_route_index = 0
	_moving = false
	_completed = false
	position = route_points[0]
	visible = true
	guide_cue.visible = false
	_update_visual_scale()


func stop_guiding() -> void:
	if _movement_tween != null and _movement_tween.is_valid():
		_movement_tween.kill()
	_moving = false
	_follower = null
	guide_cue.visible = false


func get_route_index() -> int:
	return _route_index


func get_walk_amount() -> float:
	return _walk_amount


func set_guidance_cue(text: String) -> void:
	guide_cue.text = text
	guide_cue.visible = not text.is_empty()


func lead_to_next_stop() -> bool:
	if _moving or _completed:
		return false
	if _route_index >= route_points.size() - 1:
		_completed = true
		route_completed.emit()
		return false
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
	return true


func _finish_movement() -> void:
	_moving = false
	_update_visual_scale()
	stop_reached.emit(_route_index)


func _update_visual_scale() -> void:
	var depth := clampf((position.y - 70.0) / 1130.0, 0.0, 1.0)
	var scale_factor := 0.12 * lerpf(0.72, 1.05, depth)
	var horizontal_sign := signf(sprite.scale.x) if not is_zero_approx(sprite.scale.x) else 1.0
	sprite.scale = Vector2(horizontal_sign * scale_factor, scale_factor)
	if _walk_amount <= 0.01:
		sprite.position.y = -768.0 * scale_factor


func _update_walk_animation(delta: float, is_walking: bool) -> void:
	_walk_amount = move_toward(_walk_amount, 1.0 if is_walking else 0.0, delta * 8.0)
	if is_walking:
		_walk_phase = fmod(_walk_phase + delta * 9.5, TAU)
	var material := sprite.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("walk_phase", _walk_phase)
		material.set_shader_parameter("walk_amount", _walk_amount)
	var base_y := -768.0 * absf(sprite.scale.y)
	sprite.position.y = base_y - absf(sin(_walk_phase)) * 3.0 * _walk_amount
	sprite.rotation = sin(_walk_phase) * 0.012 * _walk_amount


func _draw() -> void:
	draw_set_transform(Vector2(0.0, 1.0), 0.0, Vector2(1.0, 0.36))
	draw_circle(Vector2.ZERO, 17.0, Color(0.02, 0.055, 0.065, 0.42))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
