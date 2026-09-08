class_name CardExtraTurn
extends ActionCard

func _init() -> void:
	id = "extra_turn"
	name = "Segundo Turno"
	description = "Concede um turno adicional imediatamente apos realizar a sua jogada deste turno."
	rarity = Rarity.LEGENDARY
	target_type = TargetType.NONE

func execute(_board: Board, _target_pos: Vector2i, _human_team: int, context: Dictionary = {}) -> void:
	var main_node = context.get("main")
	if main_node and "extra_turns_pending" in main_node:
		main_node.extra_turns_pending += 1
