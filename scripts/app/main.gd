extends Node

@onready var title_screen: Control = $TitleScreen
@onready var journey_selection: JourneySelection = $JourneySelection
@onready var character_selection: CharacterSelection = $CharacterSelection
@onready var test_world: Node2D = $TestWorld
@onready var storm_world: StormWorld = $StormWorld

var _selected_journey_id := "good_samaritan"


func _ready() -> void:
	title_screen.start_requested.connect(_on_start_requested)
	journey_selection.journey_selected.connect(_on_journey_selected)
	journey_selection.back_requested.connect(_on_journey_selection_back_requested)
	character_selection.character_confirmed.connect(_on_character_confirmed)
	character_selection.back_requested.connect(_on_character_selection_back_requested)
	test_world.return_to_title_requested.connect(_on_return_to_title_requested)
	test_world.journey_selection_requested.connect(_on_journey_selection_requested)
	storm_world.return_to_title_requested.connect(_on_return_to_title_requested)
	storm_world.journey_selection_requested.connect(_on_journey_selection_requested)
	journey_selection.visible = false
	character_selection.visible = false
	test_world.visible = false
	storm_world.visible = false


func _on_start_requested() -> void:
	title_screen.visible = false
	journey_selection.visible = true
	journey_selection.begin_selection()


func _on_journey_selected(journey_id: String) -> void:
	_selected_journey_id = journey_id
	get_node("/root/GameState").select_journey(journey_id)
	journey_selection.visible = false
	character_selection.visible = true
	character_selection.begin_selection()


func _on_character_confirmed(character: Dictionary) -> void:
	character_selection.visible = false
	if _selected_journey_id == "calming_storm":
		storm_world.visible = true
		storm_world.set_player_character(character)
		storm_world.begin_session()
	else:
		test_world.visible = true
		test_world.set_player_character(character)
		test_world.begin_session()


func _on_character_selection_back_requested() -> void:
	character_selection.visible = false
	journey_selection.visible = true
	journey_selection.begin_selection()


func _on_journey_selection_back_requested() -> void:
	journey_selection.visible = false
	title_screen.visible = true
	title_screen.focus_primary_action()


func _on_return_to_title_requested() -> void:
	_end_worlds()
	journey_selection.visible = false
	title_screen.visible = true
	title_screen.focus_primary_action()


func _on_journey_selection_requested() -> void:
	_end_worlds()
	title_screen.visible = false
	journey_selection.visible = true
	journey_selection.begin_selection()


func _end_worlds() -> void:
	test_world.end_session()
	storm_world.end_session()
	test_world.visible = false
	storm_world.visible = false
	character_selection.visible = false
