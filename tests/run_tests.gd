extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("Running Walk With Jesus checks...")
	_check_project_configuration()
	_check_scripture_quiz_content()
	await _check_main_flow()
	await _check_level_two_selection_flow()
	await _check_player_movement()
	await _check_complete_journey()
	await _check_storm_journey()

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


func _check_scripture_quiz_content() -> void:
	var raw_text := FileAccess.get_file_as_string("res://content/journeys/good_samaritan.json")
	var journey: Variant = JSON.parse_string(raw_text)
	_expect_true(journey is Dictionary, "Good Samaritan content is valid JSON")
	if not journey is Dictionary:
		return
	var question_count := 0
	for stop: Variant in journey.get("stops", []):
		if not stop is Dictionary or bool(stop.get("completion", false)) or str(stop.get("interaction_type", "scripture_quiz")) != "scripture_quiz":
			continue
		question_count += 1
		var correct_count := 0
		for choice: Variant in stop.get("choices", []):
			if choice is Dictionary and bool(choice.get("correct", false)):
				correct_count += 1
		_expect_equal(correct_count, 1, "Scripture question %d has exactly one correct answer" % question_count)
	_expect_equal(question_count, 4, "Journey 1 contains four scored Scripture questions")
	var storm: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/journeys/calming_storm.json"))
	_expect_true(storm is Dictionary, "Calming the Storm content is valid JSON")
	if storm is Dictionary:
		var storm_questions: Array = storm.get("questions", [])
		_expect_equal(storm_questions.size(), 3, "Journey 2 contains three scored Scripture questions")
		for index in range(storm_questions.size()):
			var correct_count := 0
			for choice: Variant in storm_questions[index].get("choices", []):
				if choice is Dictionary and bool(choice.get("correct", false)):
					correct_count += 1
			_expect_equal(correct_count, 1, "Journey 2 question %d has exactly one correct answer" % (index + 1))


func _check_main_flow() -> void:
	var main_scene := load("res://scenes/app/main.tscn") as PackedScene
	_expect_true(main_scene != null, "main scene loads")
	if main_scene == null:
		return

	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame

	var title_screen := main.get_node("TitleScreen") as Control
	var journey_selection := main.get_node("JourneySelection") as JourneySelection
	var character_selection := main.get_node("CharacterSelection") as CharacterSelection
	var world := main.get_node("TestWorld") as Node2D
	var storm_world := main.get_node("StormWorld") as StormWorld
	var world_interface := world.get_node("Interface") as CanvasLayer
	var journey_camera := world.get_node("JourneyCamera") as Camera2D
	_expect_true(title_screen.visible, "title screen is initially visible")
	_expect_equal(
		title_screen.find_children("*", "Button", true, false).size(),
		1,
		"title screen has one unambiguous journey-start action"
	)
	_expect_true(not character_selection.visible, "character selection is initially hidden")
	_expect_true(not journey_selection.visible, "journey selection is initially hidden")
	_expect_true(not world.visible, "test world is initially hidden")
	_expect_true(not storm_world.visible, "Journey 2 world is initially hidden")
	_expect_true(not world_interface.visible, "world interface does not leak onto the title screen")
	_expect_true(not journey_camera.enabled, "world camera cannot move the title screen")

	title_screen.start_requested.emit()
	await process_frame
	_expect_true(not title_screen.visible, "starting hides the title screen")
	_expect_true(journey_selection.visible, "starting reveals the two-level journey selection")
	_expect_equal(journey_selection.find_children("*", "Button", true, false).size(), 3, "journey selection offers two levels and one back action")
	_expect_true(not character_selection.visible, "traveler selection waits for a journey choice")
	journey_selection.journey_selected.emit("good_samaritan")
	await process_frame
	_expect_true(not journey_selection.visible, "choosing Journey 1 hides the level selector")
	_expect_true(character_selection.visible, "choosing a journey reveals character selection")
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
	var story_overlay := world.get_node("StoryOverlay") as StoryOverlay
	_expect_true(guide != null, "Jesus is present as a separate guide")
	_expect_true(guide != player, "Jesus is never the player-controlled character")
	_expect_equal(player.sprite.texture.resource_path, "res://assets/generated/traveler-mara.png", "the selected traveler appears in the world")
	_expect_equal(world.get_journey_phase(), "intro", "the journey begins with clear guidance")
	_expect_equal(world.get_story_stop_count(), 6, "Journey 1 provides questions, a mercy encounter, and reflection")
	_expect_true(story_overlay.visible, "the player is explicitly invited to follow Jesus")

	guide.walking_speed = 1000.0
	world.encounter_time_scale = 0.01
	world.start_journey()
	_expect_equal(world.get_journey_phase(), "opening_approach", "Journey 1 starts with the traveler approaching in real time")
	_expect_true(world.desperate_traveler.visible, "the desperate traveler is visible during the approach")
	_expect_equal(world.get_provision_count("bread"), 1, "bread remains until the traveler reaches the satchel")
	await _wait_for_journey_phase(world, "opening_taken")
	_expect_equal(world.get_provision_count("bread"), 0, "the opening theft removes the traveler's bread")
	_expect_true(world.desperate_action_label.visible, "the theft is identified visibly in the world")
	await _wait_for_journey_phase(world, "opening_event")
	world.continue_story()
	_expect_equal(world.get_journey_phase(), "leading", "accepting the invitation starts the guided journey")
	_expect_equal(guide.get_route_index(), 1, "Jesus leads toward the first story stop")
	_expect_true(guide.guide_cue.visible, "an on-road marker identifies Jesus as the guide to follow")
	var guide_peak_walk_amount := 0.0
	for _frame in range(40):
		await process_frame
		guide_peak_walk_amount = maxf(guide_peak_walk_amount, guide.get_walk_amount())
		if world.get_journey_phase() == "catch_up":
			break
	_expect_true(guide_peak_walk_amount > 0.0, "Jesus uses a visible walking cycle while leading")
	_expect_equal(world.get_journey_phase(), "catch_up", "reaching a route stop tells the player to catch up")

	player.position = guide.position + Vector2(45.0, 35.0)
	await process_frame
	_expect_equal(world.get_journey_phase(), "story", "catching Jesus opens an interactive story stop")
	_expect_true(story_overlay.visible, "story interaction appears instead of leaving the player with nothing")
	var strength_before_wrong_answer: float = world.get_traveler_strength()
	world.choose_story_response(1)
	_expect_equal(world.get_journey_phase(), "story_response", "an answer produces immediate Scripture feedback")
	_expect_true(not world.was_last_answer_correct(), "the game identifies an incorrect Scripture answer")
	_expect_equal(world.get_traveler_strength(), strength_before_wrong_answer - 15.0, "an incorrect answer costs 15 Journey Strength")
	world.continue_story()
	_expect_equal(world.get_journey_phase(), "leading", "the story choice continues into the next guided leg")
	_expect_equal(guide.get_route_index(), 2, "Jesus resumes leading after the interaction")

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
	world.encounter_time_scale = 0.01
	var hidden_caches: Array[Node] = []
	for collectible: Node in get_nodes_in_group("journey_collectibles"):
		if world.is_ancestor_of(collectible):
			hidden_caches.append(collectible)
	_expect_equal(hidden_caches.size(), 4, "the road has four scarce provision caches")
	_expect_true(not hidden_caches[0].is_revealed(), "roadside provisions begin hidden")
	world.start_journey()
	await _wait_for_journey_phase(world, "opening_event")
	world.continue_story()
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
	_expect_equal(world.get_provision_count("bread") + world.get_provision_count("water"), 0, "following the main road does not hand out free provisions")
	player.stop()
	player.global_position = hidden_caches[0].global_position + Vector2(100.0, 0.0)
	await physics_frame
	await process_frame
	_expect_true(hidden_caches[0].is_revealed(), "approaching a roadside detour reveals its hidden cache")
	world._set_walk_target(hidden_caches[0].global_position)
	for _frame in range(90):
		if world.get_provision_count("bread") + world.get_provision_count("water") > 0:
			break
		await physics_frame
	_expect_true(world.get_provision_count("bread") + world.get_provision_count("water") > 0, "exploring the detour collects and restores a provision")

	world.queue_free()
	await process_frame


func _check_level_two_selection_flow() -> void:
	var main := (load("res://scenes/app/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	main.get_node("TitleScreen").start_requested.emit()
	main.get_node("JourneySelection").journey_selected.emit("calming_storm")
	await process_frame
	main.get_node("CharacterSelection").select_character_by_index(2)
	main.get_node("CharacterSelection").confirm_selection()
	await process_frame
	_expect_true(main.get_node("StormWorld").visible, "selecting Journey 2 opens its own storm world")
	_expect_true(not main.get_node("TestWorld").visible, "Journey 1 remains hidden when Journey 2 is selected")
	_expect_equal(main.get_node("StormWorld").get_journey_phase(), "intro", "Journey 2 starts after traveler selection")
	_expect_equal(root.get_node("GameState").selected_journey_id, "calming_storm", "the selected level is stored in session state")
	main.queue_free()
	await process_frame


func _check_complete_journey() -> void:
	var world_scene := load("res://scenes/world/test_world.tscn") as PackedScene
	var world := world_scene.instantiate()
	root.add_child(world)
	world.begin_session()
	world.encounter_time_scale = 0.01
	world.jesus_guide.walking_speed = 1800.0
	world.start_journey()
	await _wait_for_journey_phase(world, "opening_event")
	world.continue_story()

	var correct_answers := [0, 1, 0, 1]
	for route_index in range(1, 7):
		for _frame in range(90):
			if world.get_journey_phase() == "catch_up":
				break
			await process_frame
		_expect_equal(world.jesus_guide.get_route_index(), route_index, "Jesus reaches guided stop %d" % route_index)
		world.player.stop()
		world.player.position = (
			world.desperate_traveler.position + Vector2(40.0, 30.0)
			if route_index == 5
			else world.jesus_guide.position + Vector2(40.0, 30.0)
		)
		await process_frame
		if route_index == 5:
			_expect_equal(world.get_journey_phase(), "mercy_scene", "the return encounter remains visible before the choice appears")
			_expect_true(not world.story_overlay.visible, "the decision card waits while the player sees the traveler")
			await _wait_for_journey_phase(world, "story")
		if route_index <= 4:
			_expect_equal(world.get_journey_phase(), "story", "stop %d opens a Scripture question" % route_index)
			var strength_before_answer: float = world.get_traveler_strength()
			world.choose_story_response(correct_answers[route_index - 1])
			_expect_equal(world.get_journey_phase(), "story_response", "stop %d responds to the answer" % route_index)
			_expect_true(world.was_last_answer_correct(), "stop %d recognizes the correct Scripture answer" % route_index)
			_expect_equal(world.get_traveler_strength(), strength_before_answer, "a correct answer preserves Journey Strength")
			world.continue_story()
		elif route_index == 5:
			_expect_equal(world.get_journey_phase(), "story", "the desperate traveler returns for a lived mercy choice")
			_expect_true(world.desperate_traveler.visible, "the recurring traveler is visible at the later encounter")
			world.choose_story_response(0)
			_expect_equal(world.get_journey_phase(), "mercy_action", "the chosen mercy response plays visibly in the world")
			await _wait_for_journey_phase(world, "story_response")
			_expect_true(world.was_last_answer_correct(), "forgiving and helping records mercy in action")
			world.continue_story()
		else:
			_expect_equal(world.get_journey_phase(), "reflection", "the final stop opens the journey reflection")
			world.continue_story()

	_expect_equal(world.get_journey_phase(), "complete", "Journey 1 reaches a clear completion state")
	_expect_equal(world.get_correct_answer_count(), 4, "the completion result retains the Scripture score")
	_expect_true(world.story_overlay.visible, "completion displays a visible journey result")
	_expect_equal(world.story_overlay.primary_button.text, "Choose the Next Journey  →", "completion offers a clear route to the next journey")
	var return_requested := [false]
	world.journey_selection_requested.connect(func() -> void: return_requested[0] = true)
	world.continue_story()
	_expect_true(return_requested[0], "the completion action returns to journey selection")
	world.queue_free()
	await process_frame


func _check_storm_journey() -> void:
	var storm_scene := load("res://scenes/world/storm_world.tscn") as PackedScene
	_expect_true(storm_scene != null, "Journey 2 storm scene loads")
	if storm_scene == null:
		return
	var world := storm_scene.instantiate() as StormWorld
	root.add_child(world)
	world.begin_session()
	_expect_equal(world.get_journey_phase(), "intro", "Journey 2 begins with the Sea of Galilee introduction")
	world.continue_story()
	await process_frame
	await physics_frame
	await physics_frame
	_expect_equal(world.get_journey_phase(), "prepare_deck", "Journey 2 begins with non-combat deck preparation")
	_expect_equal(world.get_completed_task_count(), 0, "deck tasks do not complete automatically at the starting position")
	var first_task: Node
	for task: Node in get_nodes_in_group("storm_tasks"):
		if world.is_ancestor_of(task) and not task.is_queued_for_deletion():
			first_task = task
			break
	world._set_walk_target(first_task.global_position)
	for _frame in range(300):
		if world.get_completed_task_count() > 0:
			break
		await physics_frame
	_expect_true(world.get_completed_task_count() > 0, "walking to a marked deck station completes its action")
	_complete_storm_tasks(world)
	await process_frame
	_expect_equal(world.get_journey_phase(), "question", "securing the deck opens the first Scripture question")
	world.choose_story_response(0)
	world.continue_story()
	await process_frame
	_expect_equal(world.get_journey_phase(), "bail_water", "the storm requires the player to bail water")
	_complete_storm_tasks(world)
	await process_frame
	_expect_equal(world.get_journey_phase(), "question", "bailing water opens the second Scripture question")
	world.choose_story_response(1)
	world.continue_story()
	await process_frame
	_expect_equal(world.get_journey_phase(), "reach_jesus", "the player must cross the deck to reach Jesus")
	world.player.position = world.jesus.position
	await process_frame
	_expect_equal(world.get_journey_phase(), "question", "reaching Jesus opens the final Scripture question")
	world.choose_story_response(0)
	world.continue_story()
	_expect_equal(world.get_journey_phase(), "reflection", "Journey 2 ends with reflection after the storm")
	world.continue_story()
	_expect_equal(world.get_journey_phase(), "complete", "Journey 2 reaches a visible completion result")
	_expect_equal(world.get_correct_answer_count(), 3, "Journey 2 result retains all correct answers")
	_expect_true(world.story_overlay.visible, "Journey 2 completion result remains visible")
	var selection_requested := [false]
	world.journey_selection_requested.connect(func() -> void: selection_requested[0] = true)
	world.continue_story()
	_expect_true(selection_requested[0], "Journey 2 completion returns to journey selection")
	world.queue_free()
	await process_frame


func _complete_storm_tasks(world: StormWorld) -> void:
	var tasks: Array[Node] = []
	for task: Node in get_nodes_in_group("storm_tasks"):
		if world.is_ancestor_of(task) and not task.is_queued_for_deletion():
			tasks.append(task)
	_expect_equal(tasks.size(), 3, "the current storm action has three deck tasks")
	for task: Node in tasks:
		task._on_body_entered(world.player)


func _wait_for_journey_phase(world: Node, expected_phase: String, max_frames := 180) -> void:
	for _frame in range(max_frames):
		if world.get_journey_phase() == expected_phase:
			return
		await process_frame


func _expect_true(condition: bool, description: String) -> void:
	if condition:
		print("  PASS: " + description)
	else:
		_failures += 1
		printerr("  FAIL: " + description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_expect_true(actual == expected, "%s (expected %s, got %s)" % [description, expected, actual])
