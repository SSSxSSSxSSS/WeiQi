# src/core/move_result.gd
class_name MoveResult
extends RefCounted

var valid: bool = false
var captured: Array[Vector2i] = []
var reason: String = ""

func _init(p_valid: bool = false, p_captured: Array[Vector2i] = [], p_reason: String = "") -> void:
    valid = p_valid
    captured = p_captured
    reason = p_reason
