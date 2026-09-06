class_name StormWorld
extends Node2D

signal return_to_title_requested
signal journey_selection_requested

const CONTENT_PATH := "res://content/journeys/calming_storm.json"
const TASK_SCENE := preload("res://scenes/gameplay/storm_task.tscn")
const STORM_BACKGROUND := preload("res://assets/generated/sea-of-galilee-storm.png")
const CALM_BACKGROUND := preload("res://assets/generated/sea-of-galilee-calm.png")
const MAX_STRENGTH := 100.0
const STORM_DRAIN_PER_SECOND := 7.0
const WRONG_ANSWER_PENALTY := 15.0

@onready var background: Sprite2D = $Background
@onready var navigation_region: NavigationRegion2D = $WorldContent/NavigationRegion2D
@onready var world_content: Node2D = $WorldContent
@onready var player: TravelerPlayer = $WorldContent/Player
@onready var jesus: Node2D = $WorldContent/Jesus
@onready var jesus_sprite: Sprite2D = $WorldContent/Jesus/Sprite2D
@onready var jesus_state_label: Label = %JesusStateLabel
@onready var destination_marker: Node2D = $WorldContent/DestinationMarker
@onready var interface: CanvasLayer = $Interface
@onready var back_button: Button = %BackButton
@onready var instruction_label: Label = %InstructionLabel
@onready var task_label: Label = %TaskLabel
@onready var strength_bar: ProgressBar = %StrengthBar
@onready var toast: Label = %Toast
@onready var story_overlay: StoryOverlay = $StoryOverlay

var _active := false
var _phase := "inactive"
var _content: Dictionary = {}
var _question_index := 0
var _correct_answers := 0
var _strength := MAX_STRENGTH
var _tasks_total := 0
var _tasks_completed := 0
var _toast_tween: Tween
var _elapsed := 0.0
var _storm_calm := false


func _ready() -> void:
	back_button.pressed.connect(func() -> void: return_to_title_requested.emit())
	player.destination_reached.connect(func() -> void: destination_marker.visible = false)
	story_overlay.primary_pressed.connect(_on_primary_pressed)
	story_overlay.choice_selected.connect(_on_choice_selected)
	get_viewport().size_changed.connect(_update_layout)
	_load_content()
	interface.visible = false
	destination_marker.visible = false
	_update_layout()


func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	var sleeping := _phase in ["reach_jesus", "question"] and _question_index >= 2
	var target_rotation := 0.0 if _storm_calm else (1.24 if sleeping else 0.08)
	jesus_sprite.rotation = lerp_angle(jesus_sprite.rotation, target_rotation + sin(_elapsed * 1.8) * 0.012, delta * 3.0)
	if _phase in ["prepare_deck", "bail_water", "reach_jesus"] and player.velocity.length_squared() > 0.01:
		_set_strength(_strength - STORM_DRAIN_PER_SECOND * delta)
	if _phase == "reach_jesus" and player.global_position.distance_to(jesus.global_position) <= 82.0:
		player.stop()
		destination_marker.visible = false
		_open_question(2)


func begin_session() -> void:
	_active = true
	interface.visible = true
	_phase = "intro"
	_question_index = 0
	_correct_answers = 0
	_strength = MAX_STRENGTH
	_storm_calm = false
	background.texture = STORM_BACKGROUND
	_set_strength(_strength)
	_clear_tasks()
	_update_layout()
	player.stop()
	jesus.visible = true
	jesus_state_label.text = "JESUS · RESTING IN THE STERN"
	story_overlay.show_intro(_content.get("intro", {}))
	instruction_label.text = "Journey 2 · The Sea of Galilee"
	task_label.text = "Prepare to cross"


func end_session() -> void:
	_active = false
	interface.visible = false
	_phase = "inactive"
	player.stop()
	story_overlay.close()
	_clear_tasks()
	destination_marker.visible = false


func set_player_character(character: Dictionary) -> void:
	var texture_path := str(character.get("texture_path", ""))
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		player.set_character_texture(load(texture_path) as Texture2D)


func get_journey_phase() -> String:
	return _phase


func get_correct_answer_count() -> int:
	return _correct_answers


func get_completed_task_count() -> int:
	return _tasks_completed


func get_strength() -> float:
	return _strength


func choose_story_response(index: int) -> void:
	_on_choice_selected(index)


func continue_story() -> void:
	_on_primary_pressed()


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not visible or _phase not in ["prepare_deck", "bail_water", "reach_jesus"]:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_set_walk_target(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		_set_walk_target(event.position)
		get_viewport().set_input_as_handled()


func _set_walk_target(target: Vector2) -> void:
	var closest := NavigationServer2D.map_get_closest_point(navigation_region.get_navigation_map(), target)
	destination_marker.position = closest
	destination_marker.visible = true
	player.move_direct_to(closest)


func _on_primary_pressed() -> void:
	if _phase == "intro":
		story_overlay.close()
		_start_task_round("prepare_deck")
	elif _phase == "question_response":
		story_overlay.close()
		if _question_index == 0:
			_start_task_round("bail_water")
		elif _question_index == 1:
			_start_reach_jesus()
		else:
			_phase = "reflection"
			story_overlay.show_completion(_content.get("reflection", {}))
	elif _phase == "reflection":
		_phase = "complete"
		story_overlay.show_level_result({
			"kicker": "JOURNEY 2 COMPLETE · FAITH SEAL EARNED",
			"title": "The sea became calm",
			"body": "SCRIPTURE ANSWERS  %d OF 3\nDECK ACTIONS  6 OF 6\nJOURNEY STRENGTH  %d" % [_correct_answers, roundi(_strength)],
			"message": "You faced the storm without fighting and remembered who was present in the boat.",
			"reference": "Journey 2 · Mark 4:35–41",
			"action_label": "Choose Another Journey  →",
		})
		instruction_label.text = "Journey 2 complete"
		task_label.text = "Faith Seal earned"
	elif _phase == "complete":
		journey_selection_requested.emit()


func _on_choice_selected(index: int) -> void:
	if _phase != "question":
		return
	var questions: Array = _content.get("questions", [])
	if _question_index < 0 or _question_index >= questions.size():
		return
	var question: Dictionary = questions[_question_index]
	var choices: Array = question.get("choices", [])
	if index < 0 or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	var correct := bool(choice.get("correct", false))
	if correct:
		_correct_answers += 1
	else:
		_set_strength(_strength - WRONG_ANSWER_PENALTY)
	if _question_index == 2:
		_storm_calm = true
		background.texture = CALM_BACKGROUND
		jesus_state_label.text = "JESUS · THE SEA IS CALM"
		_update_layout()
	_phase = "question_response"
	story_overlay.show_choice_response(str(choice.get("response", "")), str(question.get("action_label", "Continue  →")), correct)


func _start_task_round(round_name: String) -> void:
	_phase = round_name
	_tasks_completed = 0
	var tasks: Array[Dictionary]
	if round_name == "prepare_deck":
		tasks = [
			{"name": "SECURE ROPE", "position": Vector2(0.30, 0.57)},
			{"name": "FASTEN SAIL", "position": Vector2(0.53, 0.45)},
			{"name": "STOW JAR", "position": Vector2(0.78, 0.55)},
		]
		instruction_label.text = "Prepare the boat before the storm"
	else:
		tasks = [
			{"name": "BAIL WATER", "position": Vector2(0.35, 0.65)},
			{"name": "BAIL WATER", "position": Vector2(0.55, 0.62)},
			{"name": "BAIL WATER", "position": Vector2(0.70, 0.53)},
		]
		instruction_label.text = "The boat is filling — bail the water"
	_tasks_total = tasks.size()
	for task_data: Dictionary in tasks:
		var task := TASK_SCENE.instantiate() as StormTask
		task.configure(str(task_data.name), _normalized_position(task_data.position))
		task.completed.connect(_on_task_completed)
		world_content.add_child(task)
	_update_task_label()


func _on_task_completed(task: StormTask) -> void:
	_tasks_completed += 1
	_show_toast("%s complete" % task.display_name.capitalize())
	_update_task_label()
	if _tasks_completed >= _tasks_total:
		player.stop()
		destination_marker.visible = false
		_clear_tasks()
		if _phase == "prepare_deck":
			_open_question(0)
		elif _phase == "bail_water":
			_open_question(1)


func _update_task_label() -> void:
	var action_name := "DECK READY" if _phase == "prepare_deck" else "WATER BAILED"
	task_label.text = "%s  %d OF %d" % [action_name, _tasks_completed, _tasks_total]


func _start_reach_jesus() -> void:
	_phase = "reach_jesus"
	instruction_label.text = "Reach Jesus in the stern"
	task_label.text = "GO TO JESUS"
	jesus_state_label.text = "JESUS · ASLEEP IN THE STERN"
	_show_toast("Cross the pitching deck and reach Jesus")


func _open_question(index: int) -> void:
	_question_index = index
	_phase = "question"
	_hide_toast()
	var questions: Array = _content.get("questions", [])
	story_overlay.show_story_stop(questions[index])
	instruction_label.text = "Answer from Scripture"
	task_label.text = "QUESTION %d OF 3" % (index + 1)


func _set_strength(value: float) -> void:
	_strength = clampf(value, 0.0, MAX_STRENGTH)
	strength_bar.value = _strength
	player.set_strength_ratio(_strength / MAX_STRENGTH)


func _show_toast(message: String) -> void:
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	toast.text = message
	toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.4)
	_toast_tween.tween_property(toast, "modulate:a", 0.0, 0.5)


func _hide_toast() -> void:
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	toast.text = ""
	toast.modulate.a = 0.0


func _clear_tasks() -> void:
	for task in get_tree().get_nodes_in_group("storm_tasks"):
		if is_ancestor_of(task):
			task.queue_free()


func _load_content() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTENT_PATH))
	if parsed is Dictionary:
		_content = (parsed as Dictionary).duplicate(true)
	else:
		push_error("Invalid Journey 2 content: %s" % CONTENT_PATH)


func _normalized_position(normalized: Vector2) -> Vector2:
	var viewport_size := get_viewport_rect().size
	return Vector2(viewport_size.x * normalized.x, viewport_size.y * normalized.y)


func _update_layout() -> void:
	if not is_node_ready():
		return
	var viewport_size := get_viewport_rect().size
	var texture_size := background.texture.get_size()
	var background_scale := maxf(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	background.position = viewport_size * 0.5
	background.scale = Vector2.ONE * background_scale
	var deck_bounds := Rect2(viewport_size.x * 0.16, viewport_size.y * 0.39, viewport_size.x * 0.70, viewport_size.y * 0.39)
	player.movement_bounds = deck_bounds
	player.sprite_base_scale = 0.075 * clampf(viewport_size.y / 720.0, 0.58, 1.0)
	player.position = Vector2(viewport_size.x * 0.72, viewport_size.y * 0.68)
	jesus.position = Vector2(viewport_size.x * 0.24, viewport_size.y * 0.52)
	jesus_sprite.scale = Vector2.ONE * 0.075 * clampf(viewport_size.y / 720.0, 0.58, 1.0)
	_build_navigation_area(deck_bounds)


func _build_navigation_area(bounds: Rect2) -> void:
	var polygon := NavigationPolygon.new()
	polygon.vertices = PackedVector2Array([
		Vector2(bounds.position.x, bounds.position.y + bounds.size.y * 0.35),
		Vector2(bounds.position.x + bounds.size.x * 0.22, bounds.position.y),
		Vector2(bounds.end.x, bounds.position.y + bounds.size.y * 0.28),
		Vector2(bounds.position.x + bounds.size.x * 0.88, bounds.end.y),
		Vector2(bounds.position.x + bounds.size.x * 0.12, bounds.end.y),
	])
	polygon.add_polygon(PackedInt32Array(range(polygon.vertices.size())))
	navigation_region.navigation_polygon = polygon
