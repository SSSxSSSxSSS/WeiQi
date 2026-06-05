# src/ai/ai_heuristic.gd
class_name AiHeuristic
extends AiBase

enum Level { NORMAL, HARD }

var _level: Level

func _init(level: Level = Level.NORMAL) -> void:
    _level = level

## 对所有合法落子打分，返回最高分位置
func get_move(board: Board, color: Stone.Type) -> Vector2i:
    var candidates: Array[Dictionary] = []  # [{pos, score}]
    var opponent := Stone.opponent(color)

    for row in Board.SIZE:
        for col in Board.SIZE:
            var test_board := board.clone()
            var rules := GoRules.new()
            var result := rules.play_move(test_board, row, col, color)
            if not result.valid:
                continue

            var score := 0.0
            # 角位置 +10
            if (row == 0 or row == 18) and (col == 0 or col == 18):
                score += 10.0
            # 星位 +5
            elif row in [3, 9, 15] and col in [3, 9, 15]:
                score += 5.0
            # 边上 +3
            elif row == 0 or row == 18 or col == 0 or col == 18:
                score += 3.0
            # 能提对方子 +8/子
            score += result.captured.size() * 8.0
            # 随机扰动
            score += randf_range(0.0, 2.0)

            # 困难难度加成
            if _level == Level.HARD:
                # 落子后己方棋组只剩 1 气 → 危险
                var my_group := StoneGroup.build_group(test_board, Vector2i(row, col))
                if my_group["liberties"].size() <= 1:
                    score -= 20.0
                # 对方棋组被逼只剩 1 气 +15
                for nb in test_board.get_neighbors(row, col):
                    var nb_stone := test_board.get_stone(nb.x, nb.y)
                    if nb_stone == opponent:
                        var opp_group := StoneGroup.build_group(test_board, nb)
                        if opp_group["liberties"].size() == 1:
                            score += 15.0

            candidates.append({ "pos": Vector2i(row, col), "score": score })

    if candidates.is_empty():
        return Vector2i(-1, -1)

    # 选最高分
    var best := candidates[0]
    for c in candidates:
        if c["score"] > best["score"]:
            best = c
    return best["pos"]

func get_name() -> String:
    return "启发式 AI"

func get_level() -> String:
    return "普通" if _level == Level.NORMAL else "困难"
