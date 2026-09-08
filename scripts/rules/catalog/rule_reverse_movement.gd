class_name RuleReverseMovement
extends RuleCard

func _init() -> void:
	id = "reverse_movement"
	name = "Movimento Reverso"
	description = "Suas pecas comuns podem recuar andando nas diagonais para tras."
	category = Category.MOVEMENT
	scope = Scope.PLAYER_ONLY
	priority = 10
	cost = 6

func modify_move_directions(piece: BoardPiece, current_dirs: Array[Vector2i], _human_team: int, _board: RefCounted) -> Array[Vector2i]:
	if not piece.is_king:
		return [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]
	return current_dirs
