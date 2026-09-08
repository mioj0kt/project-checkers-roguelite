class_name RuleSecondMove
extends RuleCard

var has_used_extra_step: bool = false

func _init() -> void:
	id = "second_move"
	name = "Segundo Movimento"
	description = "Ao realizar um passo simples sem capturar, voce pode mover outra peca antes de passar o turno."
	category = Category.TURN
	scope = Scope.PLAYER_ONLY
	priority = 50
	cost = 9

func on_game_event(event_name: StringName, _context: Dictionary, _board: RefCounted) -> void:
	if event_name == &"turn_started":
		has_used_extra_step = false
