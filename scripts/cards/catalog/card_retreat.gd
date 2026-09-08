class_name CardRetreat
extends ActionCard

func _init() -> void:
	id = "retreat"
	name = "Recuar"
	description = "Permite que a peca selecionada recue uma casa na diagonal para tras neste turno (se estiver livre)."
	rarity = Rarity.COMMON
	target_type = TargetType.ALLY_PIECE

func execute(_board: Board, target_pos: Vector2i, _human_team: int, context: Dictionary = {}) -> void:
	var main_node = context.get("main")
	if main_node and "temporary_retreat_piece_pos" in main_node:
		main_node.temporary_retreat_piece_pos = target_pos
