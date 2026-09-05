extends Node2D

signal return_to_title_requested

const TILE_WIDTH := 112.0
const TILE_HEIGHT := 56.0
const GRID_SIZE := Vector2i(10, 8)
const GRID_ORIGIN := Vector2(640.0, 112.0)

@onready var navigation_region: NavigationRegion2D = $NavigationRegion2D
@onready var player: TravelerPlayer = $Player
@onready var back_button: Button = %BackButton
@onready var interface: CanvasLayer = $Interface
@onready var interface_margin: MarginContainer = $Interface/SafeMargin
@onready var instruction_label: Label = $Interface/SafeMargin/Layout/TopBar/InstructionPanel/Instruction

var _destination_marker := Vector2.ZERO
var _show_destination := false
var _session_active := false


func _ready() -> void:
	_build_navigation_area()
	back_button.pressed.connect(func() -> void: return_to_title_requested.emit())
	player.destination_reached.connect(_on_destination_reached)
	interface.visible = false
	get_viewport().size_changed.connect(_update_responsive_interface)
	_update_responsive_interface()
	queue_redraw()


func begin_session() -> void:
	_session_active = true
	interface.visible = true
	player.global_position = Vector2(640.0, 420.0)
	player.stop()
	_show_destination = false
	queue_redraw()


func end_session() -> void:
	_session_active = false
	interface.visible = false
	player.stop()
	_show_destination = false


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
	_destination_marker = closest_point
	_show_destination = true
	player.move_to(closest_point)
	queue_redraw()


func _on_destination_reached() -> void:
	_show_destination = false
	queue_redraw()


func _build_navigation_area() -> void:
	var polygon := NavigationPolygon.new()
	polygon.vertices = PackedVector2Array([
		Vector2(88.0, 174.0),
		Vector2(1192.0, 174.0),
		Vector2(1192.0, 648.0),
		Vector2(88.0, 648.0),
	])
	polygon.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	navigation_region.navigation_polygon = polygon


func _update_responsive_interface() -> void:
	if not is_node_ready():
		return
	var viewport_size := get_viewport_rect().size
	var extra_wide := viewport_size.x / maxf(viewport_size.y, 1.0) > 2.0
	back_button.custom_minimum_size = Vector2(180.0, 82.0) if extra_wide else Vector2(112.0, 50.0)
	back_button.add_theme_font_size_override("font_size", 24 if extra_wide else 18)
	instruction_label.add_theme_font_size_override("font_size", 22 if extra_wide else 18)
	interface_margin.offset_left = 88.0 if extra_wide else 24.0
	interface_margin.offset_right = -88.0 if extra_wide else -24.0


func _draw() -> void:
	draw_rect(Rect2(-640.0, -360.0, 2560.0, 1440.0), Color("8fb0ad"))
	_draw_distant_hills()
	for grid_y in range(GRID_SIZE.y):
		for grid_x in range(GRID_SIZE.x):
			_draw_isometric_tile(Vector2i(grid_x, grid_y))
	_draw_road()
	_draw_landmarks()
	if _show_destination:
		draw_set_transform(_destination_marker, 0.0, Vector2(1.0, 0.48))
		draw_circle(Vector2.ZERO, 18.0, Color(0.91, 0.76, 0.40, 0.24))
		draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 32, Color("e8c468"), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _grid_to_world(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(
		(cell.x - cell.y) * TILE_WIDTH * 0.5,
		(cell.x + cell.y) * TILE_HEIGHT * 0.5
	)


func _draw_isometric_tile(cell: Vector2i) -> void:
	var center := _grid_to_world(cell)
	var diamond := PackedVector2Array([
		center + Vector2(0.0, -TILE_HEIGHT * 0.5),
		center + Vector2(TILE_WIDTH * 0.5, 0.0),
		center + Vector2(0.0, TILE_HEIGHT * 0.5),
		center + Vector2(-TILE_WIDTH * 0.5, 0.0),
	])
	var variation := float((cell.x * 7 + cell.y * 11) % 5) * 0.012
	var tile_color := Color(0.70 + variation, 0.65 + variation, 0.48 + variation)
	draw_colored_polygon(diamond, tile_color)
	draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color(0.36, 0.34, 0.26, 0.18), 1.0)


func _draw_distant_hills() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-100.0, 230.0), Vector2(150.0, 92.0), Vector2(390.0, 216.0),
		Vector2(650.0, 66.0), Vector2(910.0, 208.0), Vector2(1150.0, 100.0),
		Vector2(1400.0, 230.0), Vector2(1400.0, 330.0), Vector2(-100.0, 330.0),
	]), Color("667b64"))
	draw_circle(Vector2(1000.0, 116.0), 54.0, Color("ddbd70"))


func _draw_road() -> void:
	var road := PackedVector2Array([
		Vector2(438.0, 238.0), Vector2(560.0, 238.0), Vector2(876.0, 630.0),
		Vector2(572.0, 630.0),
	])
	draw_colored_polygon(road, Color("d4bb82"))
	draw_polyline(PackedVector2Array([road[0], road[3]]), Color(0.42, 0.34, 0.22, 0.35), 3.0)
	draw_polyline(PackedVector2Array([road[1], road[2]]), Color(0.42, 0.34, 0.22, 0.35), 3.0)


func _draw_landmarks() -> void:
	for position in [Vector2(260.0, 388.0), Vector2(1010.0, 382.0), Vector2(1080.0, 520.0)]:
		draw_circle(position, 18.0, Color("58674b"))
		draw_circle(position + Vector2(13.0, -5.0), 13.0, Color("657557"))
	for position in [Vector2(340.0, 520.0), Vector2(920.0, 560.0), Vector2(1120.0, 310.0)]:
		draw_colored_polygon(PackedVector2Array([
			position + Vector2(-18.0, 10.0), position + Vector2(-5.0, -12.0),
			position + Vector2(16.0, -6.0), position + Vector2(23.0, 12.0),
		]), Color("756e5c"))
