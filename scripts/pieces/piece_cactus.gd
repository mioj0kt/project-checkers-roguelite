class_name PieceCactus
extends PieceData

func _init():
	id = "cactus"
	name = "Cacto"
	rarity = Rarity.UNCOMMON
	texture_white_path = "res://assets/pieces/cactus-white.png"
	texture_black_path = "res://assets/pieces/cactus-black.png"     
	texture_white_king_path = "res://assets/pieces/cactus-white-king.png"
	texture_black_king_path = "res://assets/pieces/cactus-black-king.png"
	description = "Espinhoso! Se for capturado por uma peça inimiga, elimina o atacante junto."
	color_override = Color(0.2, 0.85, 0.3)

func on_captured(board: RefCounted, capturer_pos: Vector2i, _my_pos: Vector2i) -> void:
	var attacker_piece: BoardPiece = board.grid[capturer_pos.y][capturer_pos.x]
	if attacker_piece != null and attacker_piece.data != null:
		var attacker_destroyed = attacker_piece.data.take_damage(board, capturer_pos)
		if attacker_destroyed:
			board.piece_destroyed.emit(capturer_pos, attacker_piece)
