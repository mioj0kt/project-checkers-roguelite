class_name PieceCommander
extends PieceData

func _init():
	id = "commander"
	name = "Comandante"
	rarity = Rarity.COMMON
	texture_white_path = "res://assets/pieces/commander-white.png"
	texture_black_path = "res://assets/pieces/commander-black.png"     
	texture_white_king_path = "res://assets/pieces/commander-white-king.png"
	texture_black_king_path = "res://assets/pieces/commander-black-king.png"
	description = "Líder Inimigo! Eliminá-lo garante a vitória imediata da partida."
	color_override = Color(0.85, 0.15, 0.25)
