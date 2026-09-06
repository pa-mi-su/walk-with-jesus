extends SceneTree

const PREVIEW_DIRECTORY := "res://build/previews"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var main_scene := load("res://scenes/app/main.tscn") as PackedScene
	if main_scene == null:
		printerr("Could not load the main scene")
		quit(1)
		return

	var main := main_scene.instantiate()
	root.add_child(main)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW_DIRECTORY))

	root.size = Vector2i(1280, 720)
	await _wait_for_render()
	_save_viewport("title-1280x720.png")

	main.get_node("TitleScreen").start_requested.emit()
	await _wait_for_render()
	_save_viewport("character-selection-1280x720.png")
	main.get_node("CharacterSelection").select_character_by_index(2)
	main.get_node("CharacterSelection").confirm_selection()
	await _wait_for_render()
	_save_viewport("journey-intro-1280x720.png")
	main.get_node("TestWorld").start_journey()
	await _wait_for_render()
	_save_viewport("movement-1280x720.png")
	var desktop_world := main.get_node("TestWorld")
	desktop_world._set_walk_target(desktop_world.player.position + Vector2(-360.0, -300.0))
	for _frame in range(70):
		await physics_frame
	await _wait_for_render()
	_save_viewport("journey-progress-1280x720.png")
	await _advance_to_story_stop(desktop_world)
	_save_viewport("story-stop-1280x720.png")
	desktop_world.choose_story_response(1)
	await _wait_for_render()
	_save_viewport("story-response-1280x720.png")
	await _finish_journey(desktop_world)
	_save_viewport("journey-complete-1280x720.png")

	main.get_node("TestWorld").return_to_title_requested.emit()
	root.size = Vector2i(844, 390)
	await _wait_for_render()
	_save_viewport("title-844x390.png")
	main.get_node("TitleScreen").start_requested.emit()
	await _wait_for_render()
	_save_viewport("character-selection-844x390.png")
	main.get_node("CharacterSelection").select_character_by_index(1)
	main.get_node("CharacterSelection").confirm_selection()
	await _wait_for_render()
	_save_viewport("journey-intro-844x390.png")
	main.get_node("TestWorld").start_journey()
	await _wait_for_render()
	_save_viewport("movement-844x390.png")
	var phone_world := main.get_node("TestWorld")
	phone_world._set_walk_target(phone_world.player.position + Vector2(-300.0, -250.0))
	for _frame in range(60):
		await physics_frame
	await _wait_for_render()
	_save_viewport("journey-progress-844x390.png")
	await _advance_to_story_stop(phone_world)
	_save_viewport("story-stop-844x390.png")
	main.get_node("TestWorld").return_to_title_requested.emit()

	root.size = Vector2i(1024, 768)
	await _wait_for_render()
	_save_viewport("title-1024x768.png")
	quit(0)


func _wait_for_render() -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw


func _advance_to_story_stop(world: Node) -> void:
	for _frame in range(240):
		if world.get_journey_phase() == "catch_up":
			break
		await physics_frame
	world.player.stop()
	world.player.position = world.jesus_guide.position + Vector2(45.0, 35.0)
	await physics_frame
	await _wait_for_render()


func _finish_journey(world: Node) -> void:
	world.jesus_guide.walking_speed = 1800.0
	world.continue_story()
	var correct_answers := [0, 1, 0, 1]
	for route_index in range(2, 6):
		for _frame in range(120):
			if world.get_journey_phase() == "catch_up":
				break
			await physics_frame
		world.player.stop()
		world.player.position = world.jesus_guide.position + Vector2(40.0, 30.0)
		await physics_frame
		await _wait_for_render()
		if route_index < 5:
			world.choose_story_response(correct_answers[route_index - 1])
			await _wait_for_render()
			world.continue_story()
		else:
			world.continue_story()
			await _wait_for_render()


func _save_viewport(file_name: String) -> void:
	var path := "%s/%s" % [PREVIEW_DIRECTORY, file_name]
	var error := root.get_texture().get_image().save_png(path)
	if error == OK:
		print("Saved preview: " + ProjectSettings.globalize_path(path))
	else:
		printerr("Failed to save preview %s: %s" % [path, error_string(error)])
