class_name CharacterSelection
extends Control

signal character_confirmed(character: Dictionary)
signal back_requested

const CHARACTER_CATALOG_PATH := "res://content/characters.json"

@onready var character_grid: GridContainer = %CharacterGrid
@onready var continue_button: Button = %ContinueButton
@onready var back_button: Button = %BackButton
@onready var selection_status: Label = %SelectionStatus
@onready var safe_margin: MarginContainer = $SafeMargin

var _characters: Array[Dictionary] = []
var _cards: Array[Button] = []
var _selected_index := -1


func _ready() -> void:
	continue_button.pressed.connect(confirm_selection)
	back_button.pressed.connect(func() -> void: back_requested.emit())
	resized.connect(_update_responsive_layout)
	_load_character_catalog()
	_build_character_cards()
	_update_responsive_layout()


func begin_selection() -> void:
	_selected_index = -1
	continue_button.disabled = true
	continue_button.text = "Choose a traveler"
	selection_status.text = "Choose the person you will play"
	for card in _cards:
		card.button_pressed = false


func select_character_by_index(index: int) -> void:
	if index < 0 or index >= _characters.size():
		return
	_selected_index = index
	for card_index in range(_cards.size()):
		_cards[card_index].button_pressed = card_index == index
	var character := _characters[index]
	selection_status.text = "%s will walk with Jesus" % character.display_name
	continue_button.text = "Continue as %s   →" % character.display_name
	continue_button.disabled = false
	continue_button.grab_focus()


func confirm_selection() -> void:
	if _selected_index < 0:
		return
	var character := _characters[_selected_index]
	get_node("/root/GameState").select_character(character)
	character_confirmed.emit(character)


func get_character_count() -> int:
	return _characters.size()


func _load_character_catalog() -> void:
	var raw_text := FileAccess.get_file_as_string(CHARACTER_CATALOG_PATH)
	var parsed: Variant = JSON.parse_string(raw_text)
	if not parsed is Dictionary or not parsed.has("characters") or not parsed.characters is Array:
		push_error("Invalid character catalog: %s" % CHARACTER_CATALOG_PATH)
		return
	for entry: Variant in parsed.characters:
		if _is_valid_character(entry):
			_characters.append((entry as Dictionary).duplicate(true))


func _is_valid_character(entry: Variant) -> bool:
	if not entry is Dictionary:
		return false
	for required_key in ["id", "display_name", "description", "texture_path", "accent_color"]:
		if not entry.has(required_key) or str(entry[required_key]).is_empty():
			push_error("Character entry is missing '%s'" % required_key)
			return false
	if not ResourceLoader.exists(str(entry.texture_path)):
		push_error("Character texture does not exist: %s" % entry.texture_path)
		return false
	return true


func _build_character_cards() -> void:
	for index in range(_characters.size()):
		var character := _characters[index]
		var card := _create_character_card(character)
		card.pressed.connect(select_character_by_index.bind(index))
		character_grid.add_child(card)
		_cards.append(card)


func _create_character_card(character: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(238.0, 345.0)
	card.toggle_mode = true
	card.clip_contents = true
	card.add_theme_stylebox_override("normal", _card_style(Color(character.accent_color), false, 0.58))
	card.add_theme_stylebox_override("hover", _card_style(Color(character.accent_color), false, 0.84))
	card.add_theme_stylebox_override("pressed", _card_style(Color(character.accent_color), true, 1.0))
	card.add_theme_stylebox_override("focus", _card_style(Color(character.accent_color), false, 0.84))

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(0.0, 260.0)
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait.texture = load(str(character.texture_path))
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(portrait)

	var name_label := Label.new()
	name_label.text = str(character.display_name)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color("fbfdff"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(name_label)

	var description_label := Label.new()
	description_label.text = str(character.description)
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.add_theme_font_size_override("font_size", 14)
	description_label.add_theme_color_override("font_color", Color("b6ccd4"))
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(description_label)
	return card


func _card_style(accent: Color, selected: bool, alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.15, 0.2, alpha)
	style.border_color = accent if selected else Color(accent, 0.46)
	var border_width := 3 if selected else 1
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(22)
	return style


func _update_responsive_layout() -> void:
	if not is_node_ready():
		return
	var extra_wide := size.x / maxf(size.y, 1.0) > 2.0
	safe_margin.offset_left = 88.0 if extra_wide else 30.0
	safe_margin.offset_right = -88.0 if extra_wide else -30.0
	for card in _cards:
		card.custom_minimum_size = Vector2(238.0, 360.0 if extra_wide else 345.0)
