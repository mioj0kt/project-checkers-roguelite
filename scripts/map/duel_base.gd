class_name DuelBase
extends RefCounted

var board: Board
var human_team: int = Board.WHITE
var ai_team: int = Board.BLACK
var captures_by_player: int = 0

func setup(p_board: Board, p_human_team: int, p_ai_team: int, _sudden_death_mgr: SuddenDeathManager) -> void:
	board = p_board
	human_team = p_human_team
	ai_team = p_ai_team
	captures_by_player = 0

func apply_board_modifiers() -> void:
	pass

func get_banner_text() -> String:
	return ""

func on_piece_captured(_captured_piece: BoardPiece) -> void:
	captures_by_player += 1

func on_turn_end(_board: Board) -> void:
	pass

func check_custom_victory() -> Dictionary:
	return {"ended": false, "won": false, "title": "", "details": ""}

func uses_sudden_death() -> bool:
	return true

func requires_full_elimination() -> bool:
	return false

func calculate_reward_gold() -> Dictionary:
	var base_gold = 5
	var capture_gold = captures_by_player
	var midas_gold = 0

	var surviving_pieces = 0
	for r in range(board.rows):
		for c in range(board.cols):
			var piece: BoardPiece = board.grid[r][c]
			if piece != Board.EMPTY and piece.owner_team == human_team:
				surviving_pieces += 1
				if piece.data is PieceMidas:
					midas_gold += piece.data.bounty_gold_accumulated

	var total = base_gold + capture_gold + surviving_pieces + midas_gold

	if RunManager != null:
		RunManager.add_gold(total)

	return {
		"base": base_gold,
		"captures": capture_gold,
		"survival": surviving_pieces,
		"midas": midas_gold,
		"total": total
	}
