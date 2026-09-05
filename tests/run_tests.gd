extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("Running Walk With Jesus checks...")
	_check_project_configuration()
	await _check_main_flow()
	await _check_player_movement()

	if _failures == 0:
		print("PASS: all checks passed")
		quit(0)
	else:
		printerr("FAIL: %d check(s) failed" % _failures)
		quit(1)


func _check_project_configuration() -> void:
	_expect_equal(
		ProjectSettings.get_setting("display/window/handheld/orientation"),
		1,
		"project is locked to landscape orientation"
	)
	_expect_equal(
		ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		"gl_compatibility",
		"project uses the Compatibility renderer"
	)
	_expect_true(
		ResourceLoader.exists("res://scenes/app/main.tscn"),
		"main scene exists"
	)


func _check_main_flow() -> void:
	var main_scene := load("res://scenes/app/main.tscn") as PackedScene
	_expect_true(main_scene != null, "main scene loads")
	if main_scene == null:
		return

	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame

	var title_screen := main.get_node("TitleScreen") as Control
	var character_selection := main.get_node("CharacterSelection") as CharacterSelection
	var world := main.get_node("TestWorld") as Node2D
	var world_interface := world.get_node("Interface") as CanvasLayer
	var journey_camera := world.get_node("JourneyCamera") as Camera2D
	_expect_true(title_screen.visible, "title screen is initially visible")
	_expect_equal(
		title_screen.find_children("*", "Button", true, false).size(),
		1,
		"title screen has one unambiguous journey-start action"
	)
	_expect_true(not character_selection.visible, "character selection is initially hidden")
	_expect_true(not world.visible, "test world is initially hidden")
	_expect_true(not world_interface.visible, "world interface does not leak onto the title screen")
	_expect_true(not journey_camera.enabled, "world camera cannot move the title screen")

	title_screen.start_requested.emit()
	await process_frame
	_expect_true(not title_screen.visible, "starting hides the title screen")
	_expect_true(character_selection.visible, "starting reveals character selection")
	_expect_true(not world.visible, "world waits for a character choice")
	_expect_true(not journey_camera.enabled, "world camera cannot move character selection off-screen")
	_expect_equal(character_selection.get_character_count(), 4, "four fictional travelers are available")

	character_selection.select_character_by_index(1)
	character_selection.confirm_selection()
	await process_frame
	var game_state := root.get_node("GameState")
	_expect_true(game_state.has_selected_character(), "the chosen character is stored in session state")
	_expect_equal(game_state.selected_character.id, "mara", "the correct character is selected")
	_expect_true(not character_selection.visible, "confirming hides character selection")
	_expect_true(world.visible, "confirming reveals the test world")
	_expect_true(world_interface.visible, "confirming reveals the world interface")
	_expect_true(journey_camera.enabled, "world camera activates only after the journey begins")
	var player := world.get_node("WorldContent/Player") as TravelerPlayer
	var guide := world.get_node("WorldContent/JesusGuide") as JesusGuide
	_expect_true(guide != null, "Jesus is present as a separate guide")
	_expect_true(guide != player, "Jesus is never the player-controlled character")
	_expect_equal(player.sprite.texture.resource_path, "res://assets/generated/traveler-mara.png", "the selected traveler appears in the world")

	var initial_guide_position := guide.position
	player.position = initial_guide_position + Vector2(60.0, 40.0)
	await process_frame
	await process_frame
	_expect_equal(guide.get_route_index(), 1, "Jesus leads onward when the player catches up")
	_expect_true(guide.get_walk_amount() > 0.0, "Jesus uses a visible walking cycle while leading")

	main.queue_free()
	await process_frame


func _check_player_movement() -> void:
	var world_scene := load("res://scenes/world/test_world.tscn") as PackedScene
	_expect_true(world_scene != null, "test world scene loads")
	if world_scene == null:
		return

	var world := world_scene.instantiate()
	root.add_child(world)
	world.begin_session()
	await physics_frame
	await physics_frame

	var player := world.get_node("WorldContent/Player") as TravelerPlayer
	var starting_position := player.global_position
	var camera := world.get_node("JourneyCamera") as Camera2D
	var starting_camera_position := camera.position
	var peak_walk_amount := 0.0
	world._set_walk_target(starting_position + Vector2(-250.0, -220.0))
	for _frame in range(100):
		await physics_frame
		peak_walk_amount = maxf(peak_walk_amount, player.get_walk_amount())
	_expect_true(player.global_position.distance_to(starting_position) > 200.0, "player travels beyond the opening screen area")
	_expect_true(camera.position.distance_to(starting_camera_position) > 80.0, "camera follows the journey down the road")
	_expect_true(peak_walk_amount > 0.5, "the selected traveler uses a visible walking cycle")

	world.queue_free()
	await process_frame


func _expect_true(condition: bool, description: String) -> void:
	if condition:
		print("  PASS: " + description)
	else:
		_failures += 1
		printerr("  FAIL: " + description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_expect_true(actual == expected, "%s (expected %s, got %s)" % [description, expected, actual])
