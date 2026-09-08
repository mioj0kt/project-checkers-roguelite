class_name RuleEarlyPromotion
extends RuleCard

func _init() -> void:
	id = "early_promotion"
	name = "Promocao Relampago"
	description = "Suas pecas se tornam Damas ao atingirem a penultima linha do tabuleiro."
	category = Category.PROMOTION
	scope = Scope.PLAYER_ONLY
	priority = 30
	cost = 8

func check_custom_promotion(piece: BoardPiece, to_pos: Vector2i, board: RefCounted) -> bool:
	if piece.is_king:
		return false
	
	# Promove na penúltima linha (se estiver subindo)
	if piece.owner_team == board.human_team_color and to_pos.y <= 1:
		return true
	elif piece.owner_team == board.ai_team_color and to_pos.y >= (board.rows - 2):
		return true
		
	return false
