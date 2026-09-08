class_name CardRecruit
extends ActionCard

func _init() -> void:
	id = "recruit"
	name = "Recrutamento"
	description = "Invoca uma peca comum em uma casa escura vazia nas duas primeiras linhas do seu lado."
	rarity = Rarity.RARE
	target_type = TargetType.EMPTY_TILE

func is_valid_target(board: Board, target_pos: Vector2i, human_team: int, context: Dictionary = {}) -> bool:
	if not super.is_valid_target(board, target_pos, human_team, context):
		return false
	# Apenas nas 2 últimas linhas do tabuleiro (campo do jogador)
	return target_pos.y >= (board.rows - 2)

func execute(board: Board, target_pos: Vector2i, human_team: int, _context: Dictionary = {}) -> void:
	board.grid[target_pos.y][target_pos.x] = BoardPiece.new(human_team, false)
