extends Control

signal start_requested

@onready var start_button: Button = %StartButton
@onready var safe_margin: MarginContainer = $SafeMargin
@onready var columns: HBoxContainer = $SafeMargin/Columns
@onready var illustration: Control = $SafeMargin/Columns/Illustration
@onready var panel: PanelContainer = $SafeMargin/Columns/PanelCenter/Panel
@onready var content: VBoxContainer = $SafeMargin/Columns/PanelCenter/Panel/Content
@onready var title_label: Label = $SafeMargin/Columns/PanelCenter/Panel/Content/Title
@onready var subtitle_label: Label = $SafeMargin/Columns/PanelCenter/Panel/Content/Subtitle


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
	var compact := size.x < 1000.0 or size.y < 540.0 or size.x / maxf(size.y, 1.0) > 2.0
	illustration.visible = not compact
	columns.add_theme_constant_override("separation", 18 if compact else 42)
	panel.custom_minimum_size = Vector2(600.0 if compact else 440.0, 0.0)
	content.add_theme_constant_override("separation", 14 if compact else 16)
	title_label.add_theme_font_size_override("font_size", 48)
	subtitle_label.add_theme_font_size_override("font_size", 24 if compact else 21)
	start_button.custom_minimum_size.y = 82.0 if compact else 58.0
	safe_margin.offset_left = 16.0 if compact else 32.0
	safe_margin.offset_top = 10.0 if compact else 24.0
	safe_margin.offset_right = -16.0 if compact else -32.0
	safe_margin.offset_bottom = -10.0 if compact else -24.0
