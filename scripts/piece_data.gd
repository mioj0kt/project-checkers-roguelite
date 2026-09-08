class_name PieceData
extends RefCounted

# --- Caminhos dos Sprites das Peças ---
const TEXTURE_WHITE_PATH: String = "res://assets/pieces/white.png"
const TEXTURE_BLACK_PATH: String = "res://assets/pieces/black.png"
const TEXTURE_WHITE_KING_PATH: String = "res://assets/pieces/white-king.png"
const TEXTURE_BLACK_KING_PATH: String = "res://assets/pieces/black-king.png"

var is_king: bool = false
var id: String = "common"
var color_override: Color = Color.TRANSPARENT

func _init(p_is_king: bool = false) -> void:
	is_king = p_is_king

func get_texture_for_team(owner_team: int) -> String:
	if owner_team == Board.WHITE:
		return TEXTURE_WHITE_KING_PATH if is_king else TEXTURE_WHITE_PATH
	elif owner_team == Board.BLACK:
		return TEXTURE_BLACK_KING_PATH if is_king else TEXTURE_BLACK_PATH
	return ""

func clone() -> PieceData:
	var copy = PieceData.new(is_king)
	copy.id = id
	copy.color_override = color_override
	return copy
