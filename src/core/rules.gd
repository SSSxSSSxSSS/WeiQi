# src/core/rules.gd
class_name GoRules
extends RefCounted

var _ko_hash: int = -1

## 落子入口——执行完整落子流程，返回 MoveResult
func play_move(board: Board, row: int, col: int, color: Stone.Type) -> MoveResult:
    # 边界检测
    if not board.is_on_board(row, col):
        return MoveResult.new(false, [], "out_of_bounds")
    # 占位检测
    if board.get_stone(row, col) != Stone.Type.EMPTY:
        return MoveResult.new(false, [], "occupied")

    # 劫检测：落子前局面哈希等于上一手记录则重复
    var pre_hash: int = _hash_board(board)
    if pre_hash == _ko_hash and _ko_hash != -1:
        return MoveResult.new(false, [], "ko")

    # 保存棋盘副本（自杀检测需要还原）
    var board_copy: Board = board.clone()

    # 落子
    board.set_stone(row, col, color)
    var captured: Array[Vector2i] = []

    # 提子：检查四方向邻居，对方棋组无气则移除
    for nb in board.get_neighbors(row, col):
        var nb_stone: Stone.Type = board.get_stone(nb.x, nb.y)
        if nb_stone != Stone.Type.EMPTY and nb_stone != color:
            var group: Dictionary = StoneGroup.build_group(board, nb)
            if group["liberties"].size() == 0:
                for s in group["stones"]:
                    board.set_stone(s.x, s.y, Stone.Type.EMPTY)
                    captured.append(s)

    # 自杀检测：己方棋组无气且未提对方子
    var my_group: Dictionary = StoneGroup.build_group(board, Vector2i(row, col))
    if my_group["liberties"].size() == 0 and captured.size() == 0:
        # 还原棋盘
        for r in Board.SIZE:
            for c in Board.SIZE:
                board.set_stone(r, c, board_copy.get_stone(r, c))
        return MoveResult.new(false, [], "suicide")

    _ko_hash = pre_hash
    return MoveResult.new(true, captured, "")

## Pass：不修改棋盘，清除劫记录
func do_pass() -> void:
    _ko_hash = -1

## 连续 pass 两次则终局
func is_game_over(consecutive_passes: int) -> bool:
    return consecutive_passes >= 2

## 简单多项式哈希——只算棋子位置，忽略空位顺序
func _hash_board(board: Board) -> int:
    var h: int = 0
    for row in Board.SIZE:
        for col in Board.SIZE:
            var s: int = board.get_stone(row, col)
            h = (h * 31 + s) & 0x7FFFFFFF
    return h
