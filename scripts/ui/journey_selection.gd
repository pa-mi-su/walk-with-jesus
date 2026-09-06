class_name JourneySelection
extends Control

signal journey_selected(journey_id: String)
signal back_requested

@onready var journey_one_button: Button = %JourneyOneButton
@onready var journey_two_button: Button = %JourneyTwoButton
@onready var back_button: Button = %BackButton
@onready var safe_margin: MarginContainer = $SafeMargin


func _ready() -> void:
	journey_one_button.pressed.connect(func() -> void: journey_selected.emit("good_samaritan"))
	journey_two_button.pressed.connect(func() -> void: journey_selected.emit("calming_storm"))
	back_button.pressed.connect(func() -> void: back_requested.emit())
	resized.connect(_update_responsive_layout)
	_update_responsive_layout()


func begin_selection() -> void:
	journey_one_button.grab_focus()


func _update_responsive_layout() -> void:
	if not is_node_ready():
		return
	var extra_wide := size.x / maxf(size.y, 1.0) > 2.0
	safe_margin.offset_left = 70.0 if extra_wide else 30.0
	safe_margin.offset_right = -70.0 if extra_wide else -30.0
	safe_margin.offset_top = 14.0 if extra_wide else 20.0
	safe_margin.offset_bottom = -14.0 if extra_wide else -20.0
