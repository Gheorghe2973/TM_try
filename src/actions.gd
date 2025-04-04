extends HBoxContainer

signal action_requested(action_id: StringName, params: Dictionary)

const CURSOR_LABEL_MASK: String = "Cursor at %s"
const GENERATION_LABEL_MASK: String = "Generation: %d"
const POPULATION_LABEL_MASK: String = "Population: %d (%.1f%%)"
const INTERVAL_LABEL_MASK: String = "%0.1fs"
const INTERVAL_OPTIONS: Array[float] = [0.1, 0.2, 0.5, 1.0]


func _ready() -> void:
	_setup_interval_options()
	set_cursor(Vector2i.ZERO)
	set_generation(0)
	set_population(0, 0.0)


func set_cursor(point: Vector2i) -> void:
	$Cursor.text = CURSOR_LABEL_MASK % point


func set_generation(val: int) -> void:
	$Generation.text = GENERATION_LABEL_MASK % val


func set_population(population: int, population_percent: float) -> void:
	$Population.text = POPULATION_LABEL_MASK % [population, population_percent * 100]


func _on_action_button_pressed(action_id: StringName) -> void:
	var params := {}
	if action_id in [&"clear", &"populate"]:
		$Animate.button_pressed = false
	if action_id == &"populate":
		params.bias = $Rate.value / 100
	action_requested.emit(action_id, params)


func _on_animate_toggled(toggled_on: bool) -> void:
	$Step.disabled = toggled_on
	action_requested.emit(&"animate", {animate = not toggled_on})


func _on_interval_options_item_selected(index: int) -> void:
	action_requested.emit(&"interval", {interval = $IntervalOptions.get_item_metadata(index)})


func _setup_interval_options() -> void:
	var index := 0
	for interval: float in INTERVAL_OPTIONS:
		$IntervalOptions.add_item(INTERVAL_LABEL_MASK % interval)
		$IntervalOptions.set_item_metadata(index, interval)
		index += 1
