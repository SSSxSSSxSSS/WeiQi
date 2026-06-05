# src/game/game_controller.gd
class_name GameController
extends Control

enum State { COLOR_SELECT, SIZE_SELECT, DIFFICULTY_SELECT, PLAYER_TURN, AI_TURN, GAME_OVER }

var _state: State = State.COLOR_SELECT
var _board: Board
var _rules: GoRules
var _ai: AiBase
var _player_color: Stone.Type
var _ai_color: Stone.Type
var _consecutive_passes: int = 0
var _komi: float = 7.5

var _board_renderer: BoardRenderer
var _color_panel: Panel
var _size_panel: Panel
var _difficulty_panel: Panel
var _hud_label: Label
var _game_over_label: Label
var _pass_button: Button
var _undo_button: Button
var _history: Array[Board] = []
var _board_size: int = 19
var _restart_button: Button

func _ready() -> void:
	randomize()
	_board = Board.new()
	_rules = GoRules.new()
	_board_renderer = BoardRenderer.new()
	add_child(_board_renderer)
	_board_renderer.board_clicked.connect(_on_board_clicked)
	_create_ui()
	_enter_color_select()

func _create_ui() -> void:
	# HUD 标签
	_hud_label = Label.new()
	_hud_label.position = Vector2(10, 10)
	_hud_label.add_theme_font_size_override("font_size", 20)
	add_child(_hud_label)

	# 终局标签（初始隐藏）
	_game_over_label = Label.new()
	_game_over_label.position = Vector2(300, 350)
	_game_over_label.add_theme_font_size_override("font_size", 28)
	_game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over_label.visible = false
	add_child(_game_over_label)

	# 颜色选择面板
	_color_panel = Panel.new()
	_color_panel.position = Vector2(280, 300)
	_color_panel.size = Vector2(200, 120)
	add_child(_color_panel)

	var black_btn: Button = Button.new()
	black_btn.text = "执黑先手"
	black_btn.position = Vector2(20, 20)
	black_btn.size = Vector2(160, 35)
	black_btn.pressed.connect(_on_color_black)
	_color_panel.add_child(black_btn)

	var white_btn: Button = Button.new()
	white_btn.text = "执白后手"
	white_btn.position = Vector2(20, 65)
	white_btn.size = Vector2(160, 35)
	white_btn.pressed.connect(_on_color_white)
	_color_panel.add_child(white_btn)

	# 棋盘尺寸选择面板（初始隐藏）
	_size_panel = Panel.new()
	_size_panel.position = Vector2(280, 300)
	_size_panel.size = Vector2(200, 155)
	_size_panel.visible = false
	add_child(_size_panel)

	for sz in [9, 13, 19]:
		var btn: Button = Button.new()
		btn.text = "%d × %d" % [sz, sz]
		btn.position = Vector2(20, 20 + (_size_panel.get_child_count() * 40))
		btn.size = Vector2(160, 35)
		btn.pressed.connect(_on_size_selected.bind(sz))
		_size_panel.add_child(btn)

	# 难度选择面板（初始隐藏）
	_difficulty_panel = Panel.new()
	_difficulty_panel.position = Vector2(280, 300)
	_difficulty_panel.size = Vector2(200, 155)
	_difficulty_panel.visible = false
	add_child(_difficulty_panel)

	var easy_btn: Button = Button.new()
	easy_btn.text = "简单（随机）"
	easy_btn.position = Vector2(20, 20)
	easy_btn.size = Vector2(160, 35)
	easy_btn.pressed.connect(_on_difficulty_easy)
	_difficulty_panel.add_child(easy_btn)

	var normal_btn: Button = Button.new()
	normal_btn.text = "普通（启发式）"
	normal_btn.position = Vector2(20, 60)
	normal_btn.size = Vector2(160, 35)
	normal_btn.pressed.connect(_on_difficulty_normal)
	_difficulty_panel.add_child(normal_btn)

	var hard_btn: Button = Button.new()
	hard_btn.text = "困难（启发式+）"
	hard_btn.position = Vector2(20, 100)
	hard_btn.size = Vector2(160, 35)
	hard_btn.pressed.connect(_on_difficulty_hard)
	_difficulty_panel.add_child(hard_btn)

	# Pass 按钮（初始隐藏）
	_pass_button = Button.new()
	_pass_button.text = "Pass"
	_pass_button.position = Vector2(800, 10)
	_pass_button.size = Vector2(80, 35)
	_pass_button.visible = false
	_pass_button.pressed.connect(_on_player_pass)
	add_child(_pass_button)

	# 悔棋按钮（初始隐藏）
	_undo_button = Button.new()
	_undo_button.text = "悔棋"
	_undo_button.position = Vector2(890, 10)
	_undo_button.size = Vector2(80, 35)
	_undo_button.visible = false
	_undo_button.pressed.connect(_on_undo)
	add_child(_undo_button)

	# 重新开始按钮（初始隐藏）
	_restart_button = Button.new()
	_restart_button.text = "重新开始"
	_restart_button.position = Vector2(400, 420)
	_restart_button.size = Vector2(160, 40)
	_restart_button.visible = false
	_restart_button.pressed.connect(_on_restart)
	add_child(_restart_button)

func _enter_color_select() -> void:
	_state = State.COLOR_SELECT
	_color_panel.visible = true
	_difficulty_panel.visible = false
	_pass_button.visible = false
	_hud_label.text = "请选择棋子颜色"

func _on_color_black() -> void:
	_player_color = Stone.Type.BLACK
	_ai_color = Stone.Type.WHITE
	_enter_size_select()

func _on_color_white() -> void:
	_player_color = Stone.Type.WHITE
	_ai_color = Stone.Type.BLACK
	_enter_size_select()

func _enter_size_select() -> void:
	_state = State.SIZE_SELECT
	_color_panel.visible = false
	_size_panel.visible = true
	_hud_label.text = "请选择棋盘大小"

func _on_size_selected(sz: int) -> void:
	_board_size = sz
	_enter_difficulty_select()

func _enter_difficulty_select() -> void:
	_state = State.DIFFICULTY_SELECT
	_color_panel.visible = false
	_difficulty_panel.visible = true
	_hud_label.text = "请选择难度"

func _on_difficulty_easy() -> void:
	_ai = AiRandom.new()
	_start_game()

func _on_difficulty_normal() -> void:
	_ai = AiHeuristic.new(AiHeuristic.Level.NORMAL)
	_start_game()

func _on_difficulty_hard() -> void:
	_ai = AiHeuristic.new(AiHeuristic.Level.HARD)
	_start_game()

func _start_game() -> void:
	_size_panel.visible = false
	_difficulty_panel.visible = false
	_board = Board.new(_board_size)
	_rules = GoRules.new()
	_history.clear()
	_consecutive_passes = 0
	_board_renderer.set_board(_board)
	_pass_button.visible = true
	_undo_button.visible = true
	_update_hud()
	if _player_color == Stone.Type.BLACK:
		_enter_player_turn()
	else:
		_enter_ai_turn()

func _enter_player_turn() -> void:
	_state = State.PLAYER_TURN
	_pass_button.visible = true
	_undo_button.visible = not _history.is_empty()
	_hud_label.text = "你的回合（%s）" % ("黑棋" if _player_color == Stone.Type.BLACK else "白棋")

func _on_board_clicked(pos: Vector2) -> void:
	if _state != State.PLAYER_TURN:
		return
	var grid: Vector2i = _board_renderer.pixel_to_grid(pos)
	if grid == Vector2i(-1, -1):
		return
	_history.append(_board.clone())
	var result: MoveResult = _rules.play_move(_board, grid.x, grid.y, _player_color)
	if not result.valid:
		_history.pop_back()
		_hud_label.text = "无效落子: %s" % result.reason
		return
	_consecutive_passes = 0
	_board_renderer.set_last_move(grid)
	_board_renderer.queue_redraw()
	if _rules.is_game_over(_consecutive_passes):
		_end_game()
	else:
		_enter_ai_turn()

func _on_player_pass() -> void:
	if _state != State.PLAYER_TURN:
		return
	_rules.do_pass()
	_consecutive_passes += 1
	if _rules.is_game_over(_consecutive_passes):
		_end_game()
	else:
		_enter_ai_turn()

func _enter_ai_turn() -> void:
	_state = State.AI_TURN
	_pass_button.visible = false
	_undo_button.visible = false
	_hud_label.text = "AI 思考中（%s - %s）..." % [_ai.get_name(), _ai.get_level()]
	_history.append(_board.clone())
	await get_tree().process_frame
	var move: Vector2i = _ai.get_move(_board, _ai_color)
	if move == Vector2i(-1, -1):
		_rules.do_pass()
		_consecutive_passes += 1
	else:
		_rules.play_move(_board, move.x, move.y, _ai_color)
		_consecutive_passes = 0
		_board_renderer.set_last_move(move)
	_board_renderer.queue_redraw()
	if _rules.is_game_over(_consecutive_passes):
		_end_game()
	else:
		_enter_player_turn()

func _end_game() -> void:
	_state = State.GAME_OVER
	_pass_button.visible = false
	var score: Dictionary = GoScoring.score(_board, _komi)
	var winner_text: String = "黑胜" if score["winner"] == Stone.Type.BLACK else "白胜"
	_game_over_label.text = "游戏结束！%s\n黑: %.1f  白: %.1f (贴目 %.1f)" % [
		winner_text, score["black_score"], score["white_score"], _komi
	]
	_game_over_label.visible = true
	_restart_button.visible = true
	_hud_label.text = "游戏结束"

func _on_undo() -> void:
	if _state != State.PLAYER_TURN or _history.is_empty():
		return
	_board = _history.pop_back()
	_rules = GoRules.new()  # 重置规则状态
	_board_renderer.set_board(_board)
	_board_renderer.set_last_move(Vector2i(-1, -1))
	_board_renderer.queue_redraw()
	_undo_button.visible = not _history.is_empty()
	_hud_label.text = "已悔棋"

func _on_restart() -> void:
	_restart_button.visible = false
	_game_over_label.visible = false
	_enter_color_select()

func _update_hud() -> void:
	_hud_label.text = "%s - %s 难度" % [
		"黑棋" if _player_color == Stone.Type.BLACK else "白棋",
		_ai.get_level()
	]
