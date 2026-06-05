# src/core/board.gd
class_name Board
extends RefCounted

const SIZE := 19  # 默认大小，保持类常量兼容

var size: int

var _grid: Array[Array]  # _grid[row][col] → Stone.Type

func _init(board_size: int = SIZE) -> void:
	size = board_size
	_grid = []
	_grid.resize(size)
	for row in size:
		_grid[row] = []
		_grid[row].resize(size)
		for col in size:
			_grid[row][col] = Stone.Type.EMPTY

func get_stone(row: int, col: int) -> Stone.Type:
	return _grid[row][col]

func set_stone(row: int, col: int, stone: Stone.Type) -> void:
	_grid[row][col] = stone

func is_on_board(row: int, col: int) -> bool:
	return row >= 0 and row < size and col >= 0 and col < size

func clear() -> void:
	for row in size:
		for col in size:
			_grid[row][col] = Stone.Type.EMPTY

func clone() -> Board:
	var b: Board = load("res://src/core/board.gd").new(size)
	for row in size:
		b._grid[row] = _grid[row].duplicate(true)
	return b

func get_neighbors(row: int, col: int) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var deltas: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	for d in deltas:
		var nr: int = row + d.x
		var nc: int = col + d.y
		if is_on_board(nr, nc):
			neighbors.append(Vector2i(nr, nc))
	return neighbors
