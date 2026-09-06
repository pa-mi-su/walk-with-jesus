extends Node

var selected_character: Dictionary = {}
var selected_journey_id := "good_samaritan"


func select_character(character: Dictionary) -> void:
	selected_character = character.duplicate(true)


func clear_character() -> void:
	selected_character.clear()


func has_selected_character() -> bool:
	return not selected_character.is_empty()


func select_journey(journey_id: String) -> void:
	selected_journey_id = journey_id
