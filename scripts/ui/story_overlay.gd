class_name StoryOverlay
extends CanvasLayer

signal primary_pressed
signal choice_selected(index: int)

@onready var safe_margin: MarginContainer = $SafeMargin
@onready var story_card: PanelContainer = %StoryCard
@onready var kicker_label: Label = %KickerLabel
@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var prompt_label: Label = %PromptLabel
@onready var reference_label: Label = %ReferenceLabel
@onready var choices: HBoxContainer = %Choices
@onready var choice_one: Button = %ChoiceOne
@onready var choice_two: Button = %ChoiceTwo
@onready var response_label: Label = %ResponseLabel
@onready var primary_button: Button = %PrimaryButton


func _ready() -> void:
	choice_one.pressed.connect(func() -> void: choice_selected.emit(0))
	choice_two.pressed.connect(func() -> void: choice_selected.emit(1))
	primary_button.pressed.connect(func() -> void: primary_pressed.emit())
	get_viewport().size_changed.connect(_update_responsive_layout)
	_update_responsive_layout()
	visible = false


func show_intro(intro: Dictionary) -> void:
	_set_common(intro)
	prompt_label.visible = false
	choices.visible = false
	response_label.visible = false
	reference_label.visible = false
	primary_button.text = str(intro.get("action_label", "Follow Jesus  →"))
	primary_button.visible = true
	_show_and_focus(primary_button)


func show_story_stop(stop: Dictionary) -> void:
	_set_common(stop)
	prompt_label.text = str(stop.get("prompt", "What will you do?"))
	prompt_label.visible = true
	reference_label.text = str(stop.get("reference", ""))
	reference_label.visible = not reference_label.text.is_empty()
	var stop_choices: Array = stop.get("choices", [])
	choice_one.text = str(stop_choices[0].get("label", "Choice one")) if stop_choices.size() > 0 else "Choice one"
	choice_two.text = str(stop_choices[1].get("label", "Choice two")) if stop_choices.size() > 1 else "Choice two"
	choices.visible = stop_choices.size() >= 2
	response_label.visible = false
	primary_button.visible = false
	_show_and_focus(choice_one)


func show_choice_response(response: String, action_label: String) -> void:
	choices.visible = false
	prompt_label.visible = false
	response_label.text = response
	response_label.visible = true
	primary_button.text = action_label
	primary_button.visible = true
	_show_and_focus(primary_button)


func show_completion(stop: Dictionary) -> void:
	_set_common(stop)
	prompt_label.visible = false
	choices.visible = false
	response_label.visible = false
	reference_label.text = str(stop.get("reference", ""))
	reference_label.visible = not reference_label.text.is_empty()
	primary_button.text = str(stop.get("action_label", "Complete journey"))
	primary_button.visible = true
	_show_and_focus(primary_button)


func close() -> void:
	visible = false


func _set_common(content: Dictionary) -> void:
	kicker_label.text = str(content.get("kicker", "JOURNEY"))
	title_label.text = str(content.get("title", ""))
	body_label.text = str(content.get("body", ""))


func _show_and_focus(control: Control) -> void:
	visible = true
	control.call_deferred("grab_focus")


func _update_responsive_layout() -> void:
	if not is_node_ready():
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var extra_wide := viewport_size.x / maxf(viewport_size.y, 1.0) > 2.0
	safe_margin.offset_left = 48.0 if extra_wide else 70.0
	safe_margin.offset_right = -48.0 if extra_wide else -70.0
	safe_margin.offset_top = 18.0 if extra_wide else 42.0
	safe_margin.offset_bottom = -18.0 if extra_wide else -42.0
	story_card.custom_minimum_size = Vector2(720.0 if extra_wide else 780.0, 300.0 if extra_wide else 390.0)
	title_label.add_theme_font_size_override("font_size", 27 if extra_wide else 34)
	body_label.add_theme_font_size_override("font_size", 15 if extra_wide else 18)
