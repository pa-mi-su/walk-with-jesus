extends Node

@onready var title_screen: Control = $TitleScreen
@onready var character_selection: CharacterSelection = $CharacterSelection
@onready var test_world: Node2D = $TestWorld


func _ready() -> void:
	title_screen.start_requested.connect(_on_start_requested)
	character_selection.character_confirmed.connect(_on_character_confirmed)
	character_selection.back_requested.connect(_on_character_selection_back_requested)
	test_world.return_to_title_requested.connect(_on_return_to_title_requested)
	character_selection.visible = false
	test_world.visible = false


func _on_start_requested() -> void:
	title_screen.visible = false
	character_selection.visible = true
	character_selection.begin_selection()


func _on_character_confirmed(character: Dictionary) -> void:
	character_selection.visible = false
	test_world.visible = true
	test_world.set_player_character(character)
	test_world.begin_session()


func _on_character_selection_back_requested() -> void:
	character_selection.visible = false
	title_screen.visible = true
	title_screen.focus_primary_action()


func _on_return_to_title_requested() -> void:
	test_world.end_session()
	test_world.visible = false
	character_selection.visible = false
	title_screen.visible = true
	title_screen.focus_primary_action()
