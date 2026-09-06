class_name StormTask
extends Area2D

signal completed(task: StormTask)

@onready var label: Label = $Label

var display_name := "SECURE"
var _elapsed := 0.0
var _completed := false


func _ready() -> void:
	add_to_group("storm_tasks")
	body_entered.connect(_on_body_entered)
	label.text = display_name
	queue_redraw()


func configure(name: String, task_position: Vector2) -> void:
	display_name = name
	position = task_position


func _process(delta: float) -> void:
	_elapsed += delta
	scale = Vector2.ONE * (1.0 + sin(_elapsed * 4.0) * 0.06)
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.48))
	draw_circle(Vector2.ZERO, 34.0, Color(0.24, 0.78, 0.88, 0.2))
	draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 32, Color("78dce8"), 4.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _on_body_entered(body: Node) -> void:
	if _completed or not body is TravelerPlayer:
		return
	_completed = true
	set_deferred("monitoring", false)
	completed.emit(self)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE * 1.35, 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)
