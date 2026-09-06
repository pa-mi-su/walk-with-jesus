extends Node2D

signal return_to_title_requested
signal journey_selection_requested

const JOURNEY_CONTENT_PATH := "res://content/journeys/good_samaritan.json"
const INTERACTION_DISTANCE := 135.0
const COLLECTIBLE_SCENE := preload("res://scenes/gameplay/journey_collectible.tscn")
const MAX_TRAVELER_STRENGTH := 100.0
const STRENGTH_DRAIN_PER_SECOND := 5.0
const INCORRECT_ANSWER_PENALTY := 15.0
const COLLECTIBLE_LAYOUT := [
	{"kind": "water", "display_name": "water jar", "strength_restore": 24.0, "texture_path": "res://assets/generated/collectible-water.png", "position": Vector2(1276.0, 1223.0)},
	{"kind": "bread", "display_name": "bread bundle", "strength_restore": 18.0, "texture_path": "res://assets/generated/collectible-bread.png", "position": Vector2(696.0, 724.0)},
	{"kind": "water", "display_name": "water jar", "strength_restore": 24.0, "texture_path": "res://assets/generated/collectible-water.png", "position": Vector2(511.0, 560.0)},
	{"kind": "bread", "display_name": "bread bundle", "strength_restore": 18.0, "texture_path": "res://assets/generated/collectible-bread.png", "position": Vector2(297.0, 365.0)},
]

@onready var road_background: Sprite2D = $RoadBackground
@onready var journey_camera: Camera2D = %JourneyCamera
@onready var world_content: Node2D = $WorldContent
@onready var navigation_region: NavigationRegion2D = $WorldContent/NavigationRegion2D
@onready var player: TravelerPlayer = $WorldContent/Player
@onready var jesus_guide: JesusGuide = $WorldContent/JesusGuide
@onready var back_button: Button = %BackButton
@onready var interface: CanvasLayer = $Interface
@onready var interface_margin: MarginContainer = $Interface/SafeMargin
@onready var instruction_label: Label = %InstructionLabel
@onready var journey_hint: Label = %JourneyHint
@onready var destination_marker: Node2D = $WorldContent/DestinationMarker
@onready var story_overlay: StoryOverlay = $StoryOverlay
@onready var desperate_traveler: Node2D = %DesperateTraveler
@onready var desperate_sprite: Sprite2D = $WorldContent/DesperateTraveler/Sprite2D
@onready var desperate_action_label: Label = %ActionLabel
@onready var provisions_label: Label = %ProvisionsLabel
@onready var strength_bar: ProgressBar = %StrengthBar
@onready var pickup_toast: Label = %PickupToast

var _session_active := false
var _journey_phase := "inactive"
var _journey_data: Dictionary = {}
var _current_stop: Dictionary = {}
var _provisions := {"bread": 0, "water": 0}
var _traveler_strength := MAX_TRAVELER_STRENGTH
var _last_answer_correct := false
var _correct_answer_count := 0
var _mercy_shown := false
var _pickup_tween: Tween
var _encounter_tween: Tween
var _desperate_is_walking := false
var _desperate_walk_phase := 0.0
var _desperate_walk_amount := 0.0

# Kept at 1.0 in the game. Automated checks can shorten only the waits.
var encounter_time_scale := 1.0


func _process(delta: float) -> void:
	if not _session_active:
		return
	_update_desperate_animation(delta)
	var mercy_close_up := _is_mercy_stop() and _journey_phase in ["mercy_scene", "story", "mercy_action", "story_response"]
	var lead_position := (
		player.position.lerp(desperate_traveler.position, 0.52)
		if mercy_close_up
		else player.position.lerp(jesus_guide.position, 0.28)
	)
	journey_camera.position = journey_camera.position.lerp(lead_position, 1.0 - exp(-delta * 5.0))
	if _journey_phase in ["leading", "catch_up"] and player.velocity.length_squared() > 0.01:
		_set_traveler_strength(_traveler_strength - STRENGTH_DRAIN_PER_SECOND * delta)
	if _journey_phase == "leading":
		_update_follow_distance("Jesus is leading")
	elif _journey_phase == "catch_up":
		_update_follow_distance("Jesus has stopped ahead")
		var encounter_target: Node2D = desperate_traveler if _is_mercy_stop() else jesus_guide
		if player.global_position.distance_to(encounter_target.global_position) <= INTERACTION_DISTANCE:
			_open_current_story_stop()


func _ready() -> void:
	_build_navigation_area()
	journey_camera.enabled = false
	back_button.pressed.connect(func() -> void: return_to_title_requested.emit())
	player.destination_reached.connect(_on_destination_reached)
	jesus_guide.stop_reached.connect(_on_guide_stop_reached)
	story_overlay.primary_pressed.connect(_on_story_primary_pressed)
	story_overlay.choice_selected.connect(_on_story_choice_selected)
	_load_journey_content()
	interface.visible = false
	destination_marker.visible = false
	get_viewport().size_changed.connect(_update_responsive_interface)
	_update_responsive_interface()
	_update_world_layout()
	queue_redraw()


func begin_session() -> void:
	_session_active = true
	journey_camera.enabled = true
	interface.visible = true
	player.position = Vector2(1450.0, 1145.0)
	player.stop()
	jesus_guide.reset_with_follower(player)
	journey_camera.position = player.position.lerp(jesus_guide.position, 0.28)
	journey_camera.zoom = Vector2.ONE
	journey_camera.reset_smoothing()
	journey_hint.text = "Your journey is about to begin"
	instruction_label.text = "Listen for your next step"
	jesus_guide.set_guidance_cue("")
	_reset_journey_resources()
	_spawn_collectibles()
	destination_marker.visible = false
	desperate_traveler.visible = false
	desperate_action_label.visible = false
	_journey_phase = "intro"
	story_overlay.show_intro(_journey_data.get("intro", {}))
	queue_redraw()


func set_player_character(character: Dictionary) -> void:
	var texture_path := str(character.get("texture_path", ""))
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		push_error("Selected character has no valid texture: %s" % texture_path)
		return
	player.set_character_texture(load(texture_path) as Texture2D)


func end_session() -> void:
	_session_active = false
	journey_camera.enabled = false
	interface.visible = false
	player.stop()
	jesus_guide.stop_guiding()
	story_overlay.close()
	_journey_phase = "inactive"
	_clear_collectibles()
	destination_marker.visible = false
	if _encounter_tween != null and _encounter_tween.is_valid():
		_encounter_tween.kill()
	_desperate_is_walking = false
	desperate_traveler.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _session_active or not visible or _journey_phase not in ["leading", "catch_up"]:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_set_walk_target(_screen_to_world(event.position))
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		_set_walk_target(_screen_to_world(event.position))
		get_viewport().set_input_as_handled()


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * screen_position


func _set_walk_target(target: Vector2) -> void:
	var closest_point := NavigationServer2D.map_get_closest_point(
		navigation_region.get_navigation_map(), target
	)
	destination_marker.position = closest_point
	destination_marker.visible = true
	player.move_to(closest_point)


func _on_destination_reached() -> void:
	destination_marker.visible = false


func start_journey() -> void:
	if _journey_phase != "intro":
		return
	_begin_opening_encounter()


func get_journey_phase() -> String:
	return _journey_phase


func get_story_stop_count() -> int:
	return (_journey_data.get("stops", []) as Array).size()


func get_provision_count(kind: String) -> int:
	return int(_provisions.get(kind, 0))


func get_traveler_strength() -> float:
	return _traveler_strength


func was_last_answer_correct() -> bool:
	return _last_answer_correct


func get_correct_answer_count() -> int:
	return _correct_answer_count


func add_provision(kind: String, strength_restore: float) -> void:
	if kind not in _provisions:
		return
	_provisions[kind] = get_provision_count(kind) + 1
	_set_traveler_strength(_traveler_strength + strength_restore)


func choose_story_response(index: int) -> void:
	_on_story_choice_selected(index)


func continue_story() -> void:
	_on_story_primary_pressed()


func _on_story_primary_pressed() -> void:
	if _journey_phase == "intro":
		start_journey()
	elif _journey_phase == "opening_event":
		story_overlay.close()
		_lead_to_next_stop()
	elif _journey_phase == "story_response":
		story_overlay.close()
		_lead_to_next_stop()
	elif _journey_phase == "reflection":
		_journey_phase = "complete"
		jesus_guide.set_guidance_cue("")
		instruction_label.text = "Journey 1 complete"
		journey_hint.text = "Mercy Seal earned"
		story_overlay.show_journey_result(
			_correct_answer_count,
			4,
			roundi(_traveler_strength),
			get_provision_count("bread"),
			get_provision_count("water"),
			_mercy_shown
		)
	elif _journey_phase == "complete":
		journey_selection_requested.emit()


func _on_story_choice_selected(index: int) -> void:
	if _journey_phase != "story":
		return
	var choices: Array = _current_stop.get("choices", [])
	if index < 0 or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	var feedback_heading := ""
	if str(_current_stop.get("interaction_type", "scripture_quiz")) == "mercy_choice":
		_mercy_shown = bool(choice.get("mercy", false))
		_last_answer_correct = _mercy_shown
		feedback_heading = "MERCY IN ACTION" if _mercy_shown else "MERCY OPPORTUNITY MISSED"
		if _mercy_shown:
			_consume_shared_provision()
		_play_mercy_response(choice, feedback_heading)
		return
	else:
		_last_answer_correct = bool(choice.get("correct", false))
		if _last_answer_correct:
			_correct_answer_count += 1
		else:
			_set_traveler_strength(_traveler_strength - INCORRECT_ANSWER_PENALTY)
	_journey_phase = "story_response"
	story_overlay.show_choice_response(
		str(choice.get("response", "")),
		str(_current_stop.get("action_label", "Continue with Jesus  →")),
		_last_answer_correct,
		feedback_heading
	)


func _lead_to_next_stop() -> void:
	if not jesus_guide.lead_to_next_stop():
		return
	_journey_phase = "leading"
	jesus_guide.set_guidance_cue("FOLLOW\n↓")
	instruction_label.text = "Jesus is leading — follow Him"
	journey_hint.text = "FOLLOW JESUS"


func _on_guide_stop_reached(route_index: int) -> void:
	_current_stop = _find_stop(route_index)
	if _current_stop.is_empty():
		push_error("Journey content has no stop for route index %d" % route_index)
		return
	_journey_phase = "catch_up"
	if str(_current_stop.get("interaction_type", "")) == "mercy_choice":
		desperate_traveler.position = jesus_guide.position + Vector2(95.0, 30.0)
		desperate_traveler.rotation = 0.0
		desperate_traveler.modulate = Color.WHITE
		desperate_traveler.visible = true
		_set_desperate_label_below(true)
		desperate_action_label.text = "SOMEONE IS BESIDE THE ROAD"
		desperate_action_label.visible = true
	jesus_guide.set_guidance_cue("CATCH UP\n↓")
	instruction_label.text = "Approach the traveler beside Jesus" if _is_mercy_stop() else "Catch up to Jesus"
	_update_follow_distance("Jesus has stopped ahead")


func _open_current_story_stop() -> void:
	player.stop()
	jesus_guide.set_guidance_cue("")
	destination_marker.visible = false
	_hide_pickup_feedback()
	if _is_mercy_stop():
		_begin_mercy_scene()
		return
	if bool(_current_stop.get("completion", false)):
		_journey_phase = "reflection"
		instruction_label.text = "Journey reflection"
		journey_hint.text = "Listen and reflect"
		story_overlay.show_completion(_current_stop)
	else:
		_journey_phase = "story"
		instruction_label.text = "Answer from Scripture"
		journey_hint.text = "Choose the correct answer"
		story_overlay.show_story_stop(_current_stop)


func _update_follow_distance(prefix: String) -> void:
	var distance := player.global_position.distance_to(jesus_guide.global_position)
	var approximate_steps := maxi(1, roundi(distance / 7.0))
	journey_hint.text = "%s  ·  about %d steps" % [prefix, approximate_steps]


func _find_stop(route_index: int) -> Dictionary:
	for stop: Variant in _journey_data.get("stops", []):
		if stop is Dictionary and int(stop.get("route_index", -1)) == route_index:
			return (stop as Dictionary).duplicate(true)
	return {}


func _load_journey_content() -> void:
	var raw_text := FileAccess.get_file_as_string(JOURNEY_CONTENT_PATH)
	var parsed: Variant = JSON.parse_string(raw_text)
	if not parsed is Dictionary or not parsed.has("intro") or not parsed.has("stops"):
		push_error("Invalid journey content: %s" % JOURNEY_CONTENT_PATH)
		_journey_data = {"intro": {}, "stops": []}
		return
	_journey_data = (parsed as Dictionary).duplicate(true)


func _reset_journey_resources() -> void:
	_provisions = {"bread": 1, "water": 0}
	_traveler_strength = MAX_TRAVELER_STRENGTH
	_last_answer_correct = false
	_correct_answer_count = 0
	_mercy_shown = false
	player.set_strength_ratio(1.0)
	pickup_toast.text = ""
	pickup_toast.modulate.a = 0.0
	_update_resource_hud()


func _begin_opening_encounter() -> void:
	story_overlay.close()
	player.stop()
	_journey_phase = "opening_approach"
	desperate_traveler.position = player.position + Vector2(330.0, -155.0)
	desperate_traveler.rotation = 0.0
	desperate_traveler.modulate = Color.WHITE
	desperate_traveler.visible = true
	_set_desperate_label_below(false)
	desperate_action_label.text = "A TRAVELER APPROACHES…"
	desperate_action_label.visible = true
	instruction_label.text = "Someone is approaching on the road"
	journey_hint.text = "WATCH WHAT HAPPENS"
	_desperate_is_walking = true
	_encounter_tween = create_tween()
	_encounter_tween.set_trans(Tween.TRANS_SINE)
	_encounter_tween.set_ease(Tween.EASE_IN_OUT)
	_encounter_tween.tween_property(
		desperate_traveler,
		"position",
		player.position + Vector2(58.0, -6.0),
		_scaled_encounter_time(3.2)
	)
	await _encounter_tween.finished
	if _journey_phase != "opening_approach":
		return
	_desperate_is_walking = false
	_journey_phase = "opening_reach"
	desperate_action_label.text = "HE REACHES FOR YOUR SATCHEL"
	instruction_label.text = "The desperate traveler reaches toward your supplies"
	await get_tree().create_timer(_scaled_encounter_time(1.6)).timeout
	if _journey_phase != "opening_reach":
		return
	_journey_phase = "opening_taken"
	_provisions["bread"] = maxi(0, get_provision_count("bread") - 1)
	_update_resource_hud()
	desperate_action_label.text = "BREAD TAKEN  ·  1 → 0"
	instruction_label.text = "Your bread has been taken"
	journey_hint.text = "REMEMBER HIS FACE"
	_show_pickup_feedback("Bread taken from your satchel")
	await get_tree().create_timer(_scaled_encounter_time(2.2)).timeout
	if _journey_phase != "opening_taken":
		return
	_journey_phase = "opening_escape"
	desperate_action_label.text = "THE TRAVELER FLEES DOWN THE ROAD"
	_desperate_is_walking = true
	_encounter_tween = create_tween().set_parallel(true)
	_encounter_tween.set_trans(Tween.TRANS_SINE)
	_encounter_tween.set_ease(Tween.EASE_IN)
	_encounter_tween.tween_property(
		desperate_traveler,
		"position",
		player.position + Vector2(-390.0, -315.0),
		_scaled_encounter_time(2.6)
	)
	_encounter_tween.tween_property(desperate_traveler, "modulate:a", 0.2, _scaled_encounter_time(2.6))
	await _encounter_tween.finished
	if _journey_phase != "opening_escape":
		return
	_desperate_is_walking = false
	desperate_traveler.visible = false
	_journey_phase = "opening_event"
	story_overlay.show_narrative_event(_journey_data.get("opening_event", {}))


func _begin_mercy_scene() -> void:
	_journey_phase = "mercy_scene"
	player.stop()
	desperate_action_label.text = "THE SAME TRAVELER  ·  WEAK AND HUNGRY"
	desperate_action_label.visible = true
	instruction_label.text = "It is the traveler who took your bread"
	journey_hint.text = "WHAT WILL YOU DO?"
	var start_position := desperate_traveler.position
	_encounter_tween = create_tween()
	_encounter_tween.set_trans(Tween.TRANS_SINE)
	_encounter_tween.set_ease(Tween.EASE_IN_OUT)
	_encounter_tween.tween_property(desperate_traveler, "position", start_position + Vector2(0.0, 7.0), _scaled_encounter_time(0.8))
	_encounter_tween.tween_property(desperate_traveler, "position", start_position, _scaled_encounter_time(0.8))
	await _encounter_tween.finished
	if _journey_phase != "mercy_scene":
		return
	await get_tree().create_timer(_scaled_encounter_time(2.4)).timeout
	if _journey_phase != "mercy_scene":
		return
	_journey_phase = "story"
	instruction_label.text = "Choose how you will respond"
	journey_hint.text = "MERCY IS MORE THAN AN ANSWER"
	story_overlay.show_story_stop(_current_stop)


func _play_mercy_response(choice: Dictionary, feedback_heading: String) -> void:
	_journey_phase = "mercy_action"
	story_overlay.close()
	player.stop()
	if _mercy_shown:
		desperate_action_label.text = "YOU FORGIVE HIM AND STOP TO HELP"
		instruction_label.text = "You put the teaching into action"
		journey_hint.text = "MERCY IN ACTION"
		_encounter_tween = create_tween()
		_encounter_tween.set_trans(Tween.TRANS_SINE)
		_encounter_tween.set_ease(Tween.EASE_OUT)
		_encounter_tween.tween_property(desperate_traveler, "position:y", desperate_traveler.position.y - 24.0, _scaled_encounter_time(2.0))
		await _encounter_tween.finished
	else:
		desperate_action_label.text = "YOU RECOVER THE SATCHEL AND TURN AWAY"
		instruction_label.text = "The traveler remains beside the road"
		journey_hint.text = "A MERCY OPPORTUNITY REMAINS"
		await get_tree().create_timer(_scaled_encounter_time(2.8)).timeout
	if _journey_phase != "mercy_action":
		return
	_journey_phase = "story_response"
	story_overlay.show_choice_response(
		str(choice.get("response", "")),
		str(_current_stop.get("action_label", "Continue with Jesus  →")),
		_last_answer_correct,
		feedback_heading
	)


func _is_mercy_stop() -> bool:
	return str(_current_stop.get("interaction_type", "")) == "mercy_choice"


func _set_desperate_label_below(use_below_position: bool) -> void:
	desperate_action_label.offset_left = -180.0 if use_below_position else -125.0
	desperate_action_label.offset_right = 180.0 if use_below_position else 125.0
	desperate_action_label.offset_top = 48.0 if use_below_position else -202.0
	desperate_action_label.offset_bottom = 90.0 if use_below_position else -160.0


func _scaled_encounter_time(seconds: float) -> float:
	return maxf(seconds * encounter_time_scale, 0.02)


func _update_desperate_animation(delta: float) -> void:
	if not desperate_traveler.visible:
		return
	_desperate_walk_amount = move_toward(_desperate_walk_amount, 1.0 if _desperate_is_walking else 0.0, delta * 8.0)
	if _desperate_is_walking:
		_desperate_walk_phase = fmod(_desperate_walk_phase + delta * 9.5, TAU)
	var material := desperate_sprite.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("walk_phase", _desperate_walk_phase)
		material.set_shader_parameter("walk_amount", _desperate_walk_amount)
	var horizontal_sign := -1.0 if _journey_phase == "opening_escape" else 1.0
	desperate_sprite.scale.x = horizontal_sign * absf(desperate_sprite.scale.x)
	desperate_sprite.rotation = sin(_desperate_walk_phase) * 0.012 * _desperate_walk_amount


func _consume_shared_provision() -> void:
	if get_provision_count("bread") > 0:
		_provisions["bread"] = get_provision_count("bread") - 1
	elif get_provision_count("water") > 0:
		_provisions["water"] = get_provision_count("water") - 1
	_update_resource_hud()


func _spawn_collectibles() -> void:
	_clear_collectibles()
	for collectible_data: Dictionary in COLLECTIBLE_LAYOUT:
		var collectible := COLLECTIBLE_SCENE.instantiate() as JourneyCollectible
		collectible.configure(collectible_data)
		collectible.set_traveler(player)
		collectible.collected.connect(_on_collectible_collected)
		collectible.discovered.connect(_on_collectible_discovered)
		world_content.add_child(collectible)


func _clear_collectibles() -> void:
	for collectible in get_tree().get_nodes_in_group("journey_collectibles"):
		if is_ancestor_of(collectible):
			collectible.queue_free()


func _on_collectible_collected(_collectible: JourneyCollectible, kind: String, strength_restore: float) -> void:
	add_provision(kind, strength_restore)
	_show_pickup_feedback("%s collected  ·  strength +%d" % [kind.capitalize(), roundi(strength_restore)])


func _on_collectible_discovered(_collectible: JourneyCollectible, display_name: String) -> void:
	if _journey_phase not in ["leading", "catch_up"]:
		return
	_show_pickup_feedback("A hidden %s glimmers nearby — explore the roadside" % display_name)


func _set_traveler_strength(value: float) -> void:
	_traveler_strength = clampf(value, 0.0, MAX_TRAVELER_STRENGTH)
	player.set_strength_ratio(_traveler_strength / MAX_TRAVELER_STRENGTH)
	_update_resource_hud()


func _update_resource_hud() -> void:
	if not is_node_ready():
		return
	provisions_label.text = "BREAD  %d    WATER  %d" % [get_provision_count("bread"), get_provision_count("water")]
	strength_bar.value = _traveler_strength


func _show_pickup_feedback(message: String) -> void:
	if _pickup_tween != null and _pickup_tween.is_valid():
		_pickup_tween.kill()
	pickup_toast.text = message
	pickup_toast.modulate.a = 1.0
	_pickup_tween = create_tween()
	_pickup_tween.tween_interval(1.3)
	_pickup_tween.tween_property(pickup_toast, "modulate:a", 0.0, 0.5)
	_pickup_tween.tween_callback(func() -> void: pickup_toast.text = "")


func _hide_pickup_feedback() -> void:
	if _pickup_tween != null and _pickup_tween.is_valid():
		_pickup_tween.kill()
	pickup_toast.text = ""
	pickup_toast.modulate.a = 0.0


func _build_navigation_area() -> void:
	# The polygon follows the visible road, so taps on scenery resolve to its nearest edge.
	var polygon := NavigationPolygon.new()
	polygon.vertices = PackedVector2Array([
		Vector2(1260.0, 1225.0),
		Vector2(1050.0, 1025.0),
		Vector2(825.0, 835.0),
		Vector2(610.0, 650.0),
		Vector2(395.0, 455.0),
		Vector2(165.0, 245.0),
		Vector2(120.0, 75.0),
		Vector2(395.0, 75.0),
		Vector2(590.0, 270.0),
		Vector2(790.0, 450.0),
		Vector2(1010.0, 635.0),
		Vector2(1230.0, 820.0),
		Vector2(1575.0, 1110.0),
		Vector2(1600.0, 1195.0),
	])
	polygon.add_polygon(PackedInt32Array(range(polygon.vertices.size())))
	navigation_region.navigation_polygon = polygon


func _update_responsive_interface() -> void:
	if not is_node_ready():
		return
	var viewport_size := get_viewport_rect().size
	var extra_wide := viewport_size.x / maxf(viewport_size.y, 1.0) > 2.0
	back_button.custom_minimum_size = Vector2(180.0, 78.0) if extra_wide else Vector2(128.0, 54.0)
	back_button.add_theme_font_size_override("font_size", 23 if extra_wide else 18)
	instruction_label.add_theme_font_size_override("font_size", 21 if extra_wide else 17)
	interface_margin.offset_left = 88.0 if extra_wide else 24.0
	interface_margin.offset_right = -88.0 if extra_wide else -24.0
	_update_world_layout()


func _update_world_layout() -> void:
	# The camera, not the world, adapts to viewport changes so the road can continue
	# beyond the opening screen on every landscape aspect ratio.
	world_content.position = Vector2.ZERO


func _draw() -> void:
	draw_rect(Rect2(-640.0, -360.0, 2560.0, 1440.0), Color("092330"))
