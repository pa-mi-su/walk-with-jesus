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
	_save_viewport("movement-1280x720.png")

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
	_save_viewport("movement-844x390.png")
	main.get_node("TestWorld").return_to_title_requested.emit()

	root.size = Vector2i(1024, 768)
	await _wait_for_render()
	_save_viewport("title-1024x768.png")
	quit(0)


func _wait_for_render() -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw


func _save_viewport(file_name: String) -> void:
	var path := "%s/%s" % [PREVIEW_DIRECTORY, file_name]
	var error := root.get_texture().get_image().save_png(path)
	if error == OK:
		print("Saved preview: " + ProjectSettings.globalize_path(path))
	else:
		printerr("Failed to save preview %s: %s" % [path, error_string(error)])
