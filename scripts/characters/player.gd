class_name TravelerPlayer
extends CharacterBody2D

signal destination_reached

@export var movement_speed: float = 230.0
@export var movement_bounds := Rect2(88.0, 174.0, 1104.0, 474.0)

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

var _walking_to_target := false
var _facing := Vector2.DOWN


func _ready() -> void:
	navigation_agent.path_desired_distance = 8.0
	navigation_agent.target_desired_distance = 10.0
	navigation_agent.avoidance_enabled = false
	queue_redraw()


func move_to(target: Vector2) -> void:
	navigation_agent.target_position = target
	_walking_to_target = true


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
		queue_redraw()

	move_and_slide()
	global_position = Vector2(
		clampf(global_position.x, movement_bounds.position.x, movement_bounds.end.x),
		clampf(global_position.y, movement_bounds.position.y, movement_bounds.end.y)
	)


func _draw() -> void:
	# The placeholder character is intentionally original, simple geometry.
	draw_set_transform(Vector2(0.0, 12.0), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 20.0, Color(0.05, 0.09, 0.08, 0.32))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var robe := PackedVector2Array([
		Vector2(-14.0, -2.0),
		Vector2(14.0, -2.0),
		Vector2(20.0, 34.0),
		Vector2(-20.0, 34.0),
	])
	draw_colored_polygon(robe, Color("80523d"))
	draw_polyline(PackedVector2Array([robe[0], robe[1], robe[2], robe[3], robe[0]]), Color("422e28"), 2.0)
	draw_circle(Vector2(0.0, -17.0), 13.0, Color("bd8059"))
	draw_arc(Vector2(0.0, -20.0), 13.0, PI, TAU, 18, Color("46342c"), 5.0)
	var facing_tip := _facing.normalized() * 9.0
	draw_circle(Vector2(facing_tip.x * 0.35, -16.0 + facing_tip.y * 0.18), 1.8, Color("302521"))
