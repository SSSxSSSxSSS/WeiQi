# src/ai/ai_base.gd
class_name AiBase
extends RefCounted

## 子类必须重写：返回 AI 选择的落子坐标
## 返回 Vector2i(-1, -1) 表示 pass
func get_move(board: Board, color: Stone.Type) -> Vector2i:
    # 基类默认返回 pass，子类必须重写
    return Vector2i(-1, -1)

func get_name() -> String:
    return "AI 基类"

func get_level() -> String:
    return "未定义"
