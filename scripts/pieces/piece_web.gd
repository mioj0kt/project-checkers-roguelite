class_name PieceWeb
extends PieceData

func _init() -> void:
	id = "web"
	name = "Emboscada"
	rarity = Rarity.LEGENDARY
	texture_white_path = "res://assets/pieces/web-white.png"
	texture_black_path = "res://assets/pieces/web-black.png"     
	texture_white_king_path = "res://assets/pieces/web-white-king.png"
	texture_black_king_path = "res://assets/pieces/web-black-king.png"
	description = "Armadilha! Pode pular para trás mesmo sem ser Dama. Inimigos que saltarem sobre ela ficam presos (não conseguem se mover por 1 rodada)."
	color_override = Color(0.45, 0.75, 0.55)

# Permite movimentos e capturas em todas as 4 direções diagonais mesmo comum
func get_move_directions(_move_up: bool) -> Array[Vector2i]:
	return [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]

func on_captured(board: RefCounted, capturer_pos: Vector2i, _my_pos: Vector2i) -> void:
	# Prende a peça atacante por 1 rodada
	if board.is_valid_pos(capturer_pos.y, capturer_pos.x):
		var capturer: BoardPiece = board.grid[capturer_pos.y][capturer_pos.x]
		if capturer != null and capturer.data != null:
			capturer.data.freeze_turns = 2
