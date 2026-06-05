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
    return MoveResult.new(true, [], "")
