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

    return MoveResult.new(true, captured, "")
