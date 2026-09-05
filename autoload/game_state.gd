extends Node

var selected_character: Dictionary = {}


func select_character(character: Dictionary) -> void:
	selected_character = character.duplicate(true)


func clear_character() -> void:
	selected_character.clear()


func has_selected_character() -> bool:
	return not selected_character.is_empty()
