class_name PieceMidas
extends PieceData

@export var bounty_gold_accumulated: int = 0

func _init() -> void:
	id = "midas"
	name = "Midas"
	rarity = Rarity.RARE
	texture_white_path = "res://assets/pieces/midas-white.png"
	texture_black_path = "res://assets/pieces/midas-black.png"     
	texture_white_king_path = "res://assets/pieces/midas-white-king.png"
	texture_black_king_path = "res://assets/pieces/midas-black-king.png"
	description = "Caça-Recompensas! Cada peça inimiga que esta peça capturar concede +3 Ouro extra no fim do duelo."
	color_override = Color(1.0, 0.85, 0.2)
	bounty_gold_accumulated = 0

func on_after_move(_board: RefCounted, _from_pos: Vector2i, _to_pos: Vector2i) -> void:
	pass

func add_bounty_kill() -> void:
	bounty_gold_accumulated += 3
