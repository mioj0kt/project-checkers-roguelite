class_name DuelHard
extends DuelBase

func setup(p_board: Board, p_human_team: int, p_ai_team: int, p_sudden_death_mgr: SuddenDeathManager) -> void:
	super.setup(p_board, p_human_team, p_ai_team, p_sudden_death_mgr)

func apply_board_modifiers() -> void:
	# Nenhum modificador aplicado ao tabuleiro
	pass

func get_banner_text() -> String:
	return "DUELO DIFICIL"

func calculate_reward_gold() -> Dictionary:
	var base_gold = 10
	var capture_gold = captures_by_player * 2

	var surviving_pieces = 0
	for r in range(board.rows):
		for c in range(board.cols):
			var piece: BoardPiece = board.grid[r][c]
			if piece != Board.EMPTY and piece.owner_team == human_team:
				surviving_pieces += 1

	var total = base_gold + capture_gold + surviving_pieces

	if RunManager != null:
		RunManager.add_gold(total)

	return {
		"base": base_gold,
		"captures": capture_gold,
		"survival": surviving_pieces,
		"total": total
	}
