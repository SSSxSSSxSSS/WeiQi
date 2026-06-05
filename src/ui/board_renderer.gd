# src/ui/board_renderer.gd
class_name BoardRenderer
extends Node2D

const CELL_SIZE := 36
const BOARD_PADDING := 40
const STONE_RADIUS := 16
const BOARD_SIZE_PX := CELL_SIZE * (Board.SIZE - 1)
const DESIGN_SIZE := BOARD_PADDING * 2 + BOARD_SIZE_PX  # 728

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
	var vs := get_viewport().get_visible_rect().size
	_scale = minf(vs.x, vs.y) / float(DESIGN_SIZE)
	_scale = maxf(_scale, 0.5)  # 最小缩放 0.5
	position = (vs - Vector2(DESIGN_SIZE * _scale, DESIGN_SIZE * _scale)) / 2.0

func set_board(board: Board) -> void:
	_board = board
	queue_redraw()

func set_last_move(pos: Vector2i) -> void:
	_last_move = pos
	queue_redraw()

func grid_to_pixel(row: int, col: int) -> Vector2:
	return Vector2(BOARD_PADDING + col * CELL_SIZE, BOARD_PADDING + row * CELL_SIZE)

func pixel_to_grid(screen_pos: Vector2) -> Vector2i:
	# screen_pos 是 viewport 全局坐标，需减去 Node2D position 再除以缩放
	var local := (screen_pos - position) / _scale
	var col := int(round((local.x - BOARD_PADDING) / float(CELL_SIZE)))
	var row := int(round((local.y - BOARD_PADDING) / float(CELL_SIZE)))
	if row < 0 or row >= Board.SIZE or col < 0 or col >= Board.SIZE:
		return Vector2i(-1, -1)
	return Vector2i(row, col)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_scale, _scale))
	_draw_board()
	_draw_star_points()
	_draw_stones()
	_draw_last_move_marker()

func _draw_board() -> void:
	var total_size := BOARD_PADDING * 2 + BOARD_SIZE_PX
	draw_rect(Rect2(0, 0, total_size, total_size), Color(0.855, 0.722, 0.49))
	for i in Board.SIZE:
		var offset := BOARD_PADDING + i * CELL_SIZE
		draw_line(Vector2(BOARD_PADDING, offset), Vector2(BOARD_PADDING + BOARD_SIZE_PX, offset), Color.BLACK, 1.0)
		draw_line(Vector2(offset, BOARD_PADDING), Vector2(offset, BOARD_PADDING + BOARD_SIZE_PX), Color.BLACK, 1.0)

func _draw_star_points() -> void:
	var stars := [
		Vector2i(3,3), Vector2i(3,9), Vector2i(3,15),
		Vector2i(9,3), Vector2i(9,9), Vector2i(9,15),
		Vector2i(15,3), Vector2i(15,9), Vector2i(15,15),
	]
	for s in stars:
		draw_circle(grid_to_pixel(s.x, s.y), 4, Color.BLACK)

func _draw_stones() -> void:
	for row in Board.SIZE:
		for col in Board.SIZE:
			var stone := _board.get_stone(row, col)
			if stone == Stone.Type.EMPTY:
				continue
			var pos := grid_to_pixel(row, col)
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
