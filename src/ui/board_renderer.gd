# src/ui/board_renderer.gd
class_name BoardRenderer
extends Node2D

const CELL_SIZE := 36
const BOARD_PADDING := 40
const STONE_RADIUS := 16

var _board: Board
var _last_move: Vector2i = Vector2i(-1, -1)
var _scale: float = 1.0

signal board_clicked(screen_pos: Vector2)

func _init() -> void:
	_board = Board.new()

func _ready() -> void:
	_update_scale_and_position()
	get_tree().root.size_changed.connect(_update_scale_and_position)

func _update_scale_and_position() -> void:
	var vs: Vector2 = get_viewport().get_visible_rect().size
	var design_size: int = BOARD_PADDING * 2 + CELL_SIZE * (_board.size - 1)
	_scale = minf(vs.x, vs.y) / float(design_size)
	_scale = maxf(_scale, 0.5)
	position = (vs - Vector2(design_size * _scale, design_size * _scale)) / 2.0

func set_board(board: Board) -> void:
	_board = board
	_update_scale_and_position()
	queue_redraw()

func set_last_move(pos: Vector2i) -> void:
	_last_move = pos
	queue_redraw()

func grid_to_pixel(row: int, col: int) -> Vector2:
	return Vector2(BOARD_PADDING + col * CELL_SIZE, BOARD_PADDING + row * CELL_SIZE)

func pixel_to_grid(screen_pos: Vector2) -> Vector2i:
	var local: Vector2 = (screen_pos - position) / _scale
	var col: int = int(round((local.x - BOARD_PADDING) / float(CELL_SIZE)))
	var row: int = int(round((local.y - BOARD_PADDING) / float(CELL_SIZE)))
	if row < 0 or row >= _board.size or col < 0 or col >= _board.size:
		return Vector2i(-1, -1)
	return Vector2i(row, col)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_scale, _scale))
	var board_px: int = CELL_SIZE * (_board.size - 1)
	_draw_board(board_px)
	_draw_star_points()
	_draw_stones()
	_draw_last_move_marker()

func _draw_board(board_px: int) -> void:
	var total_size: int = BOARD_PADDING * 2 + board_px
	draw_rect(Rect2(0, 0, total_size, total_size), Color(0.855, 0.722, 0.49))
	for i in _board.size:
		var offset: int = BOARD_PADDING + i * CELL_SIZE
		draw_line(Vector2(BOARD_PADDING, offset), Vector2(BOARD_PADDING + board_px, offset), Color.BLACK, 1.0)
		draw_line(Vector2(offset, BOARD_PADDING), Vector2(offset, BOARD_PADDING + board_px), Color.BLACK, 1.0)

func _draw_star_points() -> void:
	if _board.size != 19:
		return  # 星位仅 19 路棋盘
	var stars: Array[Vector2i] = [
		Vector2i(3,3), Vector2i(3,9), Vector2i(3,15),
		Vector2i(9,3), Vector2i(9,9), Vector2i(9,15),
		Vector2i(15,3), Vector2i(15,9), Vector2i(15,15),
	]
	for s in stars:
		draw_circle(grid_to_pixel(s.x, s.y), 4, Color.BLACK)

func _draw_stones() -> void:
	for row in _board.size:
		for col in _board.size:
			var stone: Stone.Type = _board.get_stone(row, col)
			if stone == Stone.Type.EMPTY:
				continue
			var pos: Vector2 = grid_to_pixel(row, col)
			if stone == Stone.Type.BLACK:
				draw_circle(pos, STONE_RADIUS, Color(0.1, 0.1, 0.1))
				draw_circle(pos - Vector2(4, 4), 5, Color(0.3, 0.3, 0.3))
			else:
				draw_circle(pos, STONE_RADIUS, Color(0.94, 0.94, 0.86))
				draw_arc(pos, STONE_RADIUS, 0, TAU, 32, Color(0.6, 0.6, 0.6), 1.0)

func _draw_last_move_marker() -> void:
	if _last_move.x < 0:
		return
	draw_circle(grid_to_pixel(_last_move.x, _last_move.y), 5, Color.RED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		board_clicked.emit(event.position)
