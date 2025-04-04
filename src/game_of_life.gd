extends Node

signal updated(cells: Array[bool], stats: Dictionary, zones: Dictionary)

const NEIGHBORS: Array[Vector2i] = [
	Vector2i.UP + Vector2i.LEFT,
	Vector2i.UP,
	Vector2i.UP + Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.DOWN + Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.DOWN + Vector2i.RIGHT,
]

@export_range(10, 80, 1, "suffix:rows")
var grid_height: int = 10
@export_range(10, 144, 1, "suffix:columns")
var grid_width: int = 10

var _current_generation: Array[bool] = []
var _generation: int = 0
var _zones: Dictionary = {}  # point -> zone_type

# Custom rule toggles
var _exploding_mode: bool = false
var _reverse_time_mode: bool = false
var _reverse_interval: int = 10

@onready var _grid_bounds := Rect2i(0, 0, grid_width, grid_height)

func _ready() -> void:
	_current_generation.resize(grid_height * grid_width)

func clear() -> void:
	_current_generation.fill(false)
	_generation = 1
	_zones.clear()
	_emit_updated()

func populate(rate: float = 0.25) -> void:
	for i: int in grid_height * grid_width:
		_current_generation[i] = randf() <= rate
	_generation = 1
	_zones.clear()
	_emit_updated()

func toggle(index: int) -> void:
	if _is_index_within_bounds(index):
		_current_generation[index] = not _current_generation[index]
		_emit_updated()

func set_zone(point: Vector2i, zone_type: String) -> void:
	if has_point(point):
		_zones[point] = zone_type
		_emit_updated()

func set_exploding_mode(enabled: bool) -> void:
	_exploding_mode = enabled

func set_reverse_mode(enabled: bool, interval: int) -> void:
	_reverse_time_mode = enabled
	_reverse_interval = interval

func evolve() -> void:
	var result: Array[bool] = _current_generation.duplicate()

	for i: int in grid_height * grid_width:
		var point: Vector2i = get_cell_point(i)
		var neighbors := 0

		for offset: Vector2i in NEIGHBORS:
			var neighbor := point + offset
			if has_point(neighbor):
				var ni := get_cell_index(neighbor)
				if _current_generation[ni]:
					neighbors += 1

		var alive := _current_generation[i]
		var zone_type: String = _zones.get(point, "")

		match zone_type:
			"friendly":
				result[i] = alive and neighbors >= 1 or (not alive and neighbors == 3)
			"deadly":
				result[i] = alive and neighbors < 3 or (not alive and neighbors == 3)
			"barrier":
				result[i] = (alive and neighbors == 2) or (not alive and neighbors == 4)
			_:
				result[i] = (alive and (neighbors == 2 or neighbors == 3)) or (not alive and neighbors == 3)

		# Exploding Cells
		if _exploding_mode and alive and neighbors >= 3:
			for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var target: Vector2i = point + dir
				if has_point(target):
					var ti := get_cell_index(target)
					result[ti] = true

	# Reversing Time
	if _reverse_time_mode and _generation % _reverse_interval == 0:
		for i in result.size():
			result[i] = not result[i]

	_current_generation = result
	_generation += 1
	_emit_updated()

func get_cell_point(index: int) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(index % grid_width, index / grid_width) if _is_index_within_bounds(index) else -Vector2i.ONE

func get_cell_index(point: Vector2i) -> int:
	return grid_width * point.y + point.x if _grid_bounds.has_point(point) else -1

func has_point(point: Vector2i) -> bool:
	return _grid_bounds.has_point(point)

func _emit_updated() -> void:
	var population: int = _current_generation.reduce(func(sum: int, cell: bool): return sum + int(cell), 0)
	var population_percent := 1.0 * population / (grid_height * grid_width)
	updated.emit(_current_generation, {
		generation = _generation,
		population = population,
		population_percent = population_percent,
	}, _zones)

func _is_index_within_bounds(index: int) -> bool:
	return index >= 0 and index < grid_height * grid_width
