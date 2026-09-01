class_name PieceFire
extends PieceData

func _init():
	id = "fire"
	name = "Fogo"
	rarity = Rarity.UNCOMMON
	texture_white_path = "res://assets/pieces/fire-white.png"
	texture_black_path = "res://assets/pieces/fire-black.png"     
	texture_white_king_path = "res://assets/pieces/fire-white-king.png"
	texture_black_king_path = "res://assets/pieces/fire-black-king.png"
	description = "Incendiária! Deixa um rastro de fogo na casa de onde saiu, bloqueando passagens por 2 turnos."
	color_override = Color.ORANGE_RED

func on_after_move(board: RefCounted, from_pos: Vector2i, _to_pos: Vector2i) -> void:
	board.scorched_tiles[from_pos] = 3
