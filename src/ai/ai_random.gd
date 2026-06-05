# src/ai/ai_random.gd
class_name AiRandom
extends AiBase

## 从所有合法落子中随机选一个，无合法落子则 pass
func get_move(board: Board, color: Stone.Type) -> Vector2i:
    var candidates: Array[Vector2i] = []
    var rules := GoRules.new()
    for row in Board.SIZE:
        for col in Board.SIZE:
            var test_board := board.clone()
            var result := rules.play_move(test_board, row, col, color)
            if result.valid:
                candidates.append(Vector2i(row, col))
    if candidates.is_empty():
        return Vector2i(-1, -1)
    candidates.shuffle()
    return candidates[0]

func get_name() -> String:
    return "随机 AI"

func get_level() -> String:
    return "简单"
