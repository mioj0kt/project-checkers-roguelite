class_name PieceTank
extends PieceData

@export var lives_remaining: int = 2

const STANDARD_WHITE_PATH = "res://assets/pieces/white.png"
const STANDARD_BLACK_PATH = "res://assets/pieces/black.png"
const STANDARD_WHITE_KING_PATH = "res://assets/pieces/white-king.png"
const STANDARD_BLACK_KING_PATH = "res://assets/pieces/black-king.png"

func _init() -> void:
	id = "tank"
	name = "Blindada"
	rarity = Rarity.RARE
	description = "Carcaça Resistente! Possui 2 vidas. Sobrevive à primeira captura inimiga e se torna uma peça comum."
	color_override = Color(0.55, 0.55, 0.6)
	lives_remaining = 2

	texture_white_path = "res://assets/pieces/shield-white.png"
	texture_black_path = "res://assets/pieces/shield-black.png"
	texture_white_king_path = "res://assets/pieces/shield-white-king.png"
	texture_black_king_path = "res://assets/pieces/shield-black-king.png"

func can_survive_capture() -> bool:
	lives_remaining -= 1

	if lives_remaining <= 0:
		return false

	name = "Blindada (Rachada)"
	color_override = Color.TRANSPARENT

	texture_white_path = STANDARD_WHITE_PATH
	texture_black_path = STANDARD_BLACK_PATH
	texture_white_king_path = STANDARD_WHITE_KING_PATH
	texture_black_king_path = STANDARD_BLACK_KING_PATH

	description = "Carcaça Destruída! Agora se comporta como uma peça comum de 1 vida."
	return true
