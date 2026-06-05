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

    return MoveResult.new(true, captured, "")
