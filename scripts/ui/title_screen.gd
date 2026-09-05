extends Control

signal start_requested

@onready var start_button: Button = %StartButton
@onready var safe_margin: MarginContainer = $SafeMargin
@onready var hero_panel: PanelContainer = %HeroPanel
@onready var hero_columns: HBoxContainer = %HeroColumns
@onready var journey_card: PanelContainer = %JourneyCard


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	resized.connect(_update_responsive_layout)
	_update_responsive_layout()
	focus_primary_action()


func focus_primary_action() -> void:
	if is_node_ready():
		start_button.grab_focus()


func _on_start_pressed() -> void:
	start_requested.emit()


func _update_responsive_layout() -> void:
	if not is_node_ready():
		return
	var extra_wide := size.x / maxf(size.y, 1.0) > 2.0
	safe_margin.offset_left = 88.0 if extra_wide else 30.0
	safe_margin.offset_right = -88.0 if extra_wide else -30.0
	safe_margin.offset_top = 20.0
	safe_margin.offset_bottom = -20.0
	hero_panel.custom_minimum_size = Vector2(1120.0, 480.0)
	hero_columns.add_theme_constant_override("separation", 30 if extra_wide else 38)
	journey_card.custom_minimum_size = Vector2(420.0, 390.0)
	start_button.custom_minimum_size.y = 78.0 if extra_wide else 66.0
