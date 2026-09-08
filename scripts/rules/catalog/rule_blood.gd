class_name RuleBlood
extends RuleCard

var consecutive_captures: int = 0

func _init() -> void:
	id = "blood"
	name = "Sangue"
	description = "A cada captura consecutiva no mesmo turno, a peca se enfurece: ganha +1 casa de alcance de salto para a proxima captura."
	category = Category.COMBO
	scope = Scope.PLAYER_ONLY
	rarity = Rarity.COMMON
	priority = 15
	cost = 7

func modify_step_distance(piece: BoardPiece, current_distance: int, _board: RefCounted) -> int:
	# Se a peça já capturou neste turno, aumenta a passada de salto
	if consecutive_captures > 0:
		return current_distance + 1
	return current_distance

func on_game_event(event_name: StringName, context: Dictionary, _board: RefCounted) -> void:
	match event_name:
		&"on_capture_executed":
			var attacker: BoardPiece = context.get("attacker")
			if attacker and attacker.owner_team == _board.human_team_color:
				consecutive_captures += 1
		&"on_turn_end", &"on_turn_start":
			consecutive_captures = 0
