extends Node2D

signal return_to_title_requested

const JOURNEY_CONTENT_PATH := "res://content/journeys/good_samaritan.json"
const INTERACTION_DISTANCE := 135.0
const COLLECTIBLE_SCENE := preload("res://scenes/gameplay/journey_collectible.tscn")
const MAX_TRAVELER_STRENGTH := 100.0
const STRENGTH_DRAIN_PER_SECOND := 5.0
const COLLECTIBLE_LAYOUT := [
	{"kind": "bread", "display_name": "Bread", "strength_restore": 18.0, "texture_path": "res://assets/generated/collectible-bread.png", "position": Vector2(1390.0, 1095.0)},
	{"kind": "water", "display_name": "Water", "strength_restore": 24.0, "texture_path": "res://assets/generated/collectible-water.png", "position": Vector2(1245.0, 975.0)},
	{"kind": "bread", "display_name": "Bread", "strength_restore": 18.0, "texture_path": "res://assets/generated/collectible-bread.png", "position": Vector2(1020.0, 795.0)},
	{"kind": "water", "display_name": "Water", "strength_restore": 24.0, "texture_path": "res://assets/generated/collectible-water.png", "position": Vector2(810.0, 620.0)},
	{"kind": "bread", "display_name": "Bread", "strength_restore": 18.0, "texture_path": "res://assets/generated/collectible-bread.png", "position": Vector2(600.0, 445.0)},
	{"kind": "water", "display_name": "Water", "strength_restore": 24.0, "texture_path": "res://assets/generated/collectible-water.png", "position": Vector2(395.0, 265.0)},
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
@onready var provisions_label: Label = %ProvisionsLabel
@onready var strength_bar: ProgressBar = %StrengthBar
@onready var pickup_toast: Label = %PickupToast

var _session_active := false
var _journey_phase := "inactive"
var _journey_data: Dictionary = {}
var _current_stop: Dictionary = {}
var _provisions := {"bread": 0, "water": 0}
var _traveler_strength := MAX_TRAVELER_STRENGTH
var _pickup_tween: Tween


func _process(delta: float) -> void:
	if not _session_active:
		return
	var lead_position := player.position.lerp(jesus_guide.position, 0.28)
	journey_camera.position = journey_camera.position.lerp(lead_position, 1.0 - exp(-delta * 5.0))
	if _journey_phase in ["leading", "catch_up"] and player.velocity.length_squared() > 0.01:
		_set_traveler_strength(_traveler_strength - STRENGTH_DRAIN_PER_SECOND * delta)
	if _journey_phase == "leading":
		_update_follow_distance("Jesus is leading")
	elif _journey_phase == "catch_up":
		_update_follow_distance("Jesus has stopped ahead")
		if player.global_position.distance_to(jesus_guide.global_position) <= INTERACTION_DISTANCE:
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
	journey_camera.reset_smoothing()
	journey_hint.text = "Your journey is about to begin"
	instruction_label.text = "Listen for your next step"
	jesus_guide.set_guidance_cue("")
	_reset_journey_resources()
	_spawn_collectibles()
	destination_marker.visible = false
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
	story_overlay.close()
	_lead_to_next_stop()


func get_journey_phase() -> String:
	return _journey_phase


func get_story_stop_count() -> int:
	return (_journey_data.get("stops", []) as Array).size()


func get_provision_count(kind: String) -> int:
	return int(_provisions.get(kind, 0))


func get_traveler_strength() -> float:
	return _traveler_strength


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
	elif _journey_phase == "story_response":
		story_overlay.close()
		_lead_to_next_stop()
	elif _journey_phase == "reflection":
		story_overlay.close()
		_journey_phase = "complete"
		jesus_guide.set_guidance_cue("")
		instruction_label.text = "Journey 1 complete"
		journey_hint.text = "Carry mercy into the choices you make"


func _on_story_choice_selected(index: int) -> void:
	if _journey_phase != "story":
		return
	var choices: Array = _current_stop.get("choices", [])
	if index < 0 or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	var required_item := str(choice.get("requires_item", ""))
	if not required_item.is_empty() and get_provision_count(required_item) <= 0:
		return
	if bool(choice.get("consume_item", false)) and not required_item.is_empty():
		_provisions[required_item] = get_provision_count(required_item) - 1
		_update_resource_hud()
	_journey_phase = "story_response"
	story_overlay.show_choice_response(
		str(choice.get("response", "")),
		str(_current_stop.get("action_label", "Continue with Jesus  →"))
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
	jesus_guide.set_guidance_cue("CATCH UP\n↓")
	instruction_label.text = "Catch up to Jesus"
	_update_follow_distance("Jesus has stopped ahead")


func _open_current_story_stop() -> void:
	player.stop()
	jesus_guide.set_guidance_cue("")
	destination_marker.visible = false
	if bool(_current_stop.get("completion", false)):
		_journey_phase = "reflection"
		instruction_label.text = "Journey reflection"
		journey_hint.text = "Listen and reflect"
		story_overlay.show_completion(_current_stop)
	else:
		_journey_phase = "story"
		instruction_label.text = "Choose your response"
		journey_hint.text = "A moment to listen and act"
		story_overlay.show_story_stop(_prepare_stop_for_inventory(_current_stop))


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


func _prepare_stop_for_inventory(stop: Dictionary) -> Dictionary:
	var prepared := stop.duplicate(true)
	var prepared_choices: Array = prepared.get("choices", [])
	for choice: Variant in prepared_choices:
		if not choice is Dictionary:
			continue
		var required_item := str(choice.get("requires_item", ""))
		if required_item.is_empty():
			choice["available"] = true
		else:
			var available := get_provision_count(required_item) > 0
			choice["available"] = available
			if not available:
				choice["label"] = "%s · need %s" % [choice.get("label", "Use supply"), required_item.capitalize()]
	return prepared


func _reset_journey_resources() -> void:
	_provisions = {"bread": 0, "water": 0}
	_traveler_strength = MAX_TRAVELER_STRENGTH
	player.set_strength_ratio(1.0)
	pickup_toast.text = ""
	pickup_toast.modulate.a = 0.0
	_update_resource_hud()


func _spawn_collectibles() -> void:
	_clear_collectibles()
	for collectible_data: Dictionary in COLLECTIBLE_LAYOUT:
		var collectible := COLLECTIBLE_SCENE.instantiate() as JourneyCollectible
		collectible.configure(collectible_data)
		collectible.collected.connect(_on_collectible_collected)
		world_content.add_child(collectible)


func _clear_collectibles() -> void:
	for collectible in get_tree().get_nodes_in_group("journey_collectibles"):
		if is_ancestor_of(collectible):
			collectible.queue_free()


func _on_collectible_collected(_collectible: JourneyCollectible, kind: String, strength_restore: float) -> void:
	add_provision(kind, strength_restore)
	_show_pickup_feedback("%s collected  ·  strength +%d" % [kind.capitalize(), roundi(strength_restore)])


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
