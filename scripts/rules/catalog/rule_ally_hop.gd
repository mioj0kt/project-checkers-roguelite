class_name RuleAllyHop
extends RuleCard

func _init() -> void:
	id = "ally_hop"
	name = "Salto Camarada"
	description = "Suas pecas podem pular sobre pecas aliadas na diagonal como se fossem capturas, avancando 2 casas sem destruir a aliada."
	category = Category.MOVEMENT
	scope = Scope.PLAYER_ONLY
	priority = 12
	cost = 6

func modify_move_directions(_piece: BoardPiece, current_dirs: Array[Vector2i], _human_team: int, _board: RefCounted) -> Array[Vector2i]:
	return current_dirs
