class_name TravelerPlayer
extends CharacterBody2D

signal destination_reached

@export var movement_speed: float = 230.0
@export var movement_bounds := Rect2(40.0, 40.0, 930.0, 650.0)
@export var sprite_base_scale := 0.12

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: Sprite2D = $Sprite2D

var _walking_to_target := false
var _facing := Vector2.UP
var _walk_phase := 0.0
var _walk_amount := 0.0
var _full_strength_speed := 230.0


func _ready() -> void:
	_full_strength_speed = movement_speed
	navigation_agent.path_desired_distance = 8.0
	navigation_agent.target_desired_distance = 10.0
	navigation_agent.avoidance_enabled = false
	_update_visual()
	queue_redraw()


func move_to(target: Vector2) -> void:
	navigation_agent.target_position = target
	_walking_to_target = true


func set_character_texture(texture: Texture2D) -> void:
	if texture == null:
		push_error("Cannot set an empty player character texture")
		return
	sprite.texture = texture
	_update_visual()


func stop() -> void:
	_walking_to_target = false
	velocity = Vector2.ZERO
	if is_node_ready():
		navigation_agent.target_position = global_position


func _physics_process(_delta: float) -> void:
	var keyboard_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if keyboard_direction.length_squared() > 0.01:
		_walking_to_target = false
		velocity = keyboard_direction.normalized() * movement_speed
	elif _walking_to_target:
		if navigation_agent.is_navigation_finished():
			stop()
			destination_reached.emit()
		else:
			var next_path_position := navigation_agent.get_next_path_position()
			velocity = global_position.direction_to(next_path_position) * movement_speed
	else:
		velocity = Vector2.ZERO

	if velocity.length_squared() > 0.01:
		_facing = velocity.normalized()

	move_and_slide()
	position = Vector2(
		clampf(position.x, movement_bounds.position.x, movement_bounds.end.x),
		clampf(position.y, movement_bounds.position.y, movement_bounds.end.y)
	)
	_update_visual()
	_update_walk_animation(_delta, velocity.length_squared() > 0.01)


func get_walk_amount() -> float:
	return _walk_amount


func set_strength_ratio(ratio: float) -> void:
	movement_speed = lerpf(_full_strength_speed * 0.58, _full_strength_speed, clampf(ratio, 0.0, 1.0))


func _update_visual() -> void:
	if not is_node_ready():
		return
	var depth := clampf((position.y - movement_bounds.position.y) / movement_bounds.size.y, 0.0, 1.0)
	var perspective_scale := lerpf(0.72, 1.05, depth)
	var horizontal_sign := -1.0 if _facing.x < -0.05 else 1.0
	var visual_scale := sprite_base_scale * perspective_scale
	sprite.scale = Vector2(horizontal_sign * visual_scale, visual_scale)
	sprite.position.y = -768.0 * visual_scale
	queue_redraw()


func _update_walk_animation(delta: float, is_walking: bool) -> void:
	_walk_amount = move_toward(_walk_amount, 1.0 if is_walking else 0.0, delta * 8.0)
	if is_walking:
		_walk_phase = fmod(_walk_phase + delta * 10.0, TAU)
	var material := sprite.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("walk_phase", _walk_phase)
		material.set_shader_parameter("walk_amount", _walk_amount)
	var base_y := -768.0 * absf(sprite.scale.y)
	sprite.position.y = base_y - absf(sin(_walk_phase)) * 3.0 * _walk_amount
	sprite.rotation = sin(_walk_phase) * 0.012 * _walk_amount


func _draw() -> void:
	var depth := clampf((position.y - movement_bounds.position.y) / movement_bounds.size.y, 0.0, 1.0)
	var shadow_radius := lerpf(12.0, 20.0, depth)
	draw_set_transform(Vector2(0.0, 1.0), 0.0, Vector2(1.0, 0.36))
	draw_circle(Vector2.ZERO, shadow_radius, Color(0.02, 0.055, 0.065, 0.42))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
