extends Node

@onready var title_screen: Control = $TitleScreen
@onready var test_world: Node2D = $TestWorld


func _ready() -> void:
	title_screen.start_requested.connect(_on_start_requested)
	test_world.return_to_title_requested.connect(_on_return_to_title_requested)
	test_world.visible = false


func _on_start_requested() -> void:
	title_screen.visible = false
	test_world.visible = true
	test_world.begin_session()


func _on_return_to_title_requested() -> void:
	test_world.end_session()
	test_world.visible = false
	title_screen.visible = true
	title_screen.focus_primary_action()
