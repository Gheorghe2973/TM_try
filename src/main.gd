extends MarginContainer

var exploding_enabled: bool = false
var reverse_time_enabled: bool = false
var reverse_interval: int = 10

func _ready() -> void:
	$GameOfLife.populate()
	$Timer.paused = true

func _on_actions_action_requested(action_id: StringName, params: Dictionary) -> void:
	match action_id:
		&"animate":
			var animate: bool = bool(params.get("animate", false))
			$Timer.paused = animate
			%Cursor.visible = animate
		&"clear":
			$Timer.paused = true
			$GameOfLife.clear()
		&"interval":
			var interval: float = params.get("interval", 0.1)
			$Timer.start(interval)
		&"populate":
			var bias: float = float(params.get("bias", 0.2))
			$Timer.paused = true
			$GameOfLife.populate(bias)
		&"step":
			$GameOfLife.evolve()

func _on_game_of_life_updated(cells: Array[bool], stats: Dictionary, zones: Dictionary) -> void:
	for i in len(cells):
		var point: Vector2i = $GameOfLife.get_cell_point(i)
		var zone_type: String = zones.get(point, "")
		var tile: int

		match zone_type:
			"friendly":
				tile = 3  # green
			"deadly":
				tile = 4  # red
			"barrier":
				tile = 6  # yellow
			_:
				tile = 2 if cells[i] else 1  # blue/alive or gray/dead

		%Grid.set_cell(point, 0, Vector2i(tile, 0))

	%Actions.set_generation(stats.generation)
	%Actions.set_population(stats.population, stats.population_percent)

func _on_sub_viewport_container_gui_input(event: InputEvent) -> void:
	if event.is_echo() or not $Timer.paused:
		return
	var point: Vector2i = %Grid.local_to_map(%Grid.get_local_mouse_position())
	if event is InputEventMouseMotion and $GameOfLife.has_point(point):
		%Actions.set_cursor(point)
		%Cursor.position = %Grid.map_to_local(point) * %Grid.scale
	if event is InputEventMouseButton and event.is_action_released("ui_left_mouse_button"):
		$GameOfLife.toggle($GameOfLife.get_cell_index(point))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var point: Vector2i = %Grid.local_to_map(%Grid.get_local_mouse_position())
		if not $GameOfLife.has_point(point):
			return
		match event.keycode:
			KEY_A:
				$GameOfLife.set_zone(point, "friendly")
			KEY_S:
				$GameOfLife.set_zone(point, "deadly")
			KEY_C:
				$GameOfLife.set_zone(point, "barrier")
			KEY_X:
				exploding_enabled = not exploding_enabled
				print("Exploding Cells:", exploding_enabled)
				$GameOfLife.set_exploding_mode(exploding_enabled)
			KEY_R:
				reverse_time_enabled = not reverse_time_enabled
				print("Reversing Time:", reverse_time_enabled)
				$GameOfLife.set_reverse_mode(reverse_time_enabled, reverse_interval)
