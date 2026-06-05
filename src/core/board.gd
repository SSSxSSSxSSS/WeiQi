# src/core/board.gd
class_name Board
extends RefCounted

const SIZE := 19

var _grid: Array[Array]  # _grid[row][col] → Stone.Type

func _init() -> void:
    _grid = []
    _grid.resize(SIZE)
    for row in SIZE:
        _grid[row] = []
        _grid[row].resize(SIZE)
        for col in SIZE:
            _grid[row][col] = Stone.Type.EMPTY

## 读取指定位置的棋子
func get_stone(row: int, col: int) -> Stone.Type:
    return _grid[row][col]

## 放置棋子
func set_stone(row: int, col: int, stone: Stone.Type) -> void:
    _grid[row][col] = stone

## 检查坐标是否在棋盘范围内
func is_on_board(row: int, col: int) -> bool:
    return row >= 0 and row < SIZE and col >= 0 and col < SIZE

## 清空棋盘
func clear() -> void:
    for row in SIZE:
        for col in SIZE:
            _grid[row][col] = Stone.Type.EMPTY

## 深拷贝——每行 duplicate(true)，避免浅拷贝污染原棋盘
func clone() -> Board:
    var b: Board = load("res://src/core/board.gd").new()
    for row in SIZE:
        b._grid[row] = _grid[row].duplicate(true)
    return b

## 返回 (row,col) 的四方向邻居中在棋盘范围内的坐标
func get_neighbors(row: int, col: int) -> Array[Vector2i]:
    var neighbors: Array[Vector2i] = []
    var deltas: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
    for d in deltas:
        var nr: int = row + d.x
        var nc: int = col + d.y
        if is_on_board(nr, nc):
            neighbors.append(Vector2i(nr, nc))
    return neighbors
