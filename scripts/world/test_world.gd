extends Node2D

signal return_to_title_requested

@onready var road_background: Sprite2D = $RoadBackground
@onready var world_content: Node2D = $WorldContent
@onready var navigation_region: NavigationRegion2D = $WorldContent/NavigationRegion2D
@onready var player: TravelerPlayer = $WorldContent/Player
@onready var back_button: Button = %BackButton
@onready var interface: CanvasLayer = $Interface
@onready var interface_margin: MarginContainer = $Interface/SafeMargin
@onready var instruction_label: Label = %InstructionLabel
@onready var destination_marker: Node2D = $WorldContent/DestinationMarker

var _session_active := false


func _ready() -> void:
	_build_navigation_area()
	back_button.pressed.connect(func() -> void: return_to_title_requested.emit())
	player.destination_reached.connect(_on_destination_reached)
	interface.visible = false
	destination_marker.visible = false
	get_viewport().size_changed.connect(_update_responsive_interface)
	_update_responsive_interface()
	_update_world_layout()
	queue_redraw()


func begin_session() -> void:
	_session_active = true
	interface.visible = true
	player.position = Vector2(700.0, 590.0)
	player.stop()
	destination_marker.visible = false
	queue_redraw()


func end_session() -> void:
	_session_active = false
	interface.visible = false
	player.stop()
	destination_marker.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _session_active or not visible:
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


func _build_navigation_area() -> void:
	# The polygon follows the visible road, so taps on scenery resolve to its nearest edge.
	var polygon := NavigationPolygon.new()
	polygon.vertices = PackedVector2Array([
		Vector2(560.0, 690.0),
		Vector2(500.0, 550.0),
		Vector2(380.0, 400.0),
		Vector2(245.0, 255.0),
		Vector2(40.0, 105.0),
		Vector2(40.0, 40.0),
		Vector2(260.0, 40.0),
		Vector2(430.0, 170.0),
		Vector2(575.0, 305.0),
		Vector2(710.0, 450.0),
		Vector2(925.0, 650.0),
		Vector2(965.0, 690.0),
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
	if not is_node_ready() or road_background.texture == null:
		return
	var viewport_size := get_viewport_rect().size
	var texture_size := road_background.texture.get_size()
	var cover_scale := maxf(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	road_background.position = viewport_size * 0.5
	road_background.scale = Vector2.ONE * cover_scale
	world_content.position = (viewport_size - Vector2(1280.0, 720.0)) * 0.5


func _draw() -> void:
	draw_rect(Rect2(-640.0, -360.0, 2560.0, 1440.0), Color("092330"))
