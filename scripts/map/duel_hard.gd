class_name DuelHard
extends DuelBase

var hard_modifiers: Array[String] = []
var commander_eliminated: bool = false
var themed_piece_type: String = ""
var sudden_death_mgr_ref: SuddenDeathManager

func setup(p_board: Board, p_human_team: int, p_ai_team: int, p_sudden_death_mgr: SuddenDeathManager) -> void:
	super.setup(p_board, p_human_team, p_ai_team, p_sudden_death_mgr)
	sudden_death_mgr_ref = p_sudden_death_mgr
	commander_eliminated = false
	_roll_modifiers()

func _roll_modifiers() -> void:
	hard_modifiers.clear()
	var all_mods = [
		"TARGET_PIECE",
		"START_SUDDEN_DEATH",
		"ENEMY_KINGS",
		"EXTRA_PIECES",
		"THEMED_ARMY"
	]
	all_mods.shuffle()

	var count = randi_range(1, 2)
	for i in range(count):
		hard_modifiers.append(all_mods[i])

	if hard_modifiers.has("THEMED_ARMY"):
		var themes = ["cactus", "spring", "fire", "flying_king", "tank", "ghost", "web", "midas"]
		themed_piece_type = themes.pick_random()

func get_banner_text() -> String:
	var lines = ["DUELO DIFICIL"]
	for mod in hard_modifiers:
		match mod:
			"TARGET_PIECE":
				lines.append("- Alvo: Elimine o Comandante")
			"START_SUDDEN_DEATH":
				lines.append("- Morte Subita Ativa")
			"ENEMY_KINGS":
				lines.append("- Inimigo com Damas")
			"EXTRA_PIECES":
				lines.append("- Inimigo em Maioria")
			"THEMED_ARMY":
				match themed_piece_type:
					"cactus": lines.append("- Exercito de Cactos")
					"spring": lines.append("- Batalhao de Molas")
					"fire": lines.append("- Tropa Infernal")
					"flying_king": lines.append("- Esquadrao Alado")
					"tank": lines.append("- Batalhao Blindado")
					"ghost": lines.append("- Legiao Espectral")
					"web": lines.append("- Tropa da Emboscada")
					"midas": lines.append("- Mercenarios de Ouro")
					_: lines.append("- Tropa Tematica")
	return "\n".join(lines)

func _create_themed_piece(piece_id: String) -> PieceData:
	match piece_id:
		"cactus": return PieceCactus.new()
		"spring": return PieceSpring.new()
		"fire": return PieceFire.new()
		"flying_king": return PieceFlyingKing.new()
		"tank": return PieceTank.new()
		"ghost": return PieceGhost.new()
		"web": return PieceWeb.new()
		"midas": return PieceMidas.new()
		_: return PieceData.new()

func apply_board_modifiers() -> void:
	var max_rows = board.get_max_deployment_rows()
	var player_start_row = board.rows - max_rows

	if hard_modifiers.has("THEMED_ARMY"):
		for r in range(max_rows):
			for c in range(board.cols):
				var p: BoardPiece = board.grid[r][c]
				if p != Board.EMPTY and p.owner_team == ai_team:
					var new_piece = _create_themed_piece(themed_piece_type)
					new_piece.is_king = p.data.is_king
					p.data = new_piece

	if hard_modifiers.has("EXTRA_PIECES"):
		var extra_added = 0
		var target_extra = 3
		for r in range(player_start_row - 1):
			for c in range(board.cols):
				if (r + c) % 2 == 1 and board.grid[r][c] == Board.EMPTY and extra_added < target_extra:
					var piece_data = _create_themed_piece(themed_piece_type) if hard_modifiers.has("THEMED_ARMY") else PieceData.new()
					board.grid[r][c] = BoardPiece.new(ai_team, piece_data)
					extra_added += 1
			if extra_added >= target_extra:
				break

	if hard_modifiers.has("TARGET_PIECE"):
		var candidate_positions: Array[Vector2i] = []
		for r in range(max_rows):
			for c in range(board.cols):
				var p: BoardPiece = board.grid[r][c]
				if p != Board.EMPTY and p.owner_team == ai_team:
					candidate_positions.append(Vector2i(c, r))

		if not candidate_positions.is_empty():
			candidate_positions.shuffle()
			var commander_pos = candidate_positions.pop_front()
			board.grid[commander_pos.y][commander_pos.x].data = PieceCommander.new()

	if hard_modifiers.has("ENEMY_KINGS"):
		var ai_piece_positions: Array[Vector2i] = []
		for r in range(max_rows):
			for c in range(board.cols):
				var p: BoardPiece = board.grid[r][c]
				if p != Board.EMPTY and p.owner_team == ai_team:
					ai_piece_positions.append(Vector2i(c, r))

		ai_piece_positions.shuffle()

		var max_possible = max(1, int(ai_piece_positions.size() * 0.4))
		var kings_target = randi_range(1, min(3, max_possible))

		var kings_given = 0
		for pos in ai_piece_positions:
			if kings_given >= kings_target:
				break
			var p: BoardPiece = board.grid[pos.y][pos.x]
			if p != Board.EMPTY and not p.data.is_king:
				p.data.is_king = true
				kings_given += 1

	if sudden_death_mgr_ref != null:
		sudden_death_mgr_ref.set_initial_kings_baseline(board)
		if hard_modifiers.has("START_SUDDEN_DEATH"):
			sudden_death_mgr_ref.start_immediately()

func on_piece_captured(captured_piece: BoardPiece) -> void:
	super.on_piece_captured(captured_piece)
	if captured_piece != null and captured_piece.data != null and captured_piece.data.id == "commander":
		commander_eliminated = true

func _is_commander_alive_on_board() -> bool:
	for r in range(board.rows):
		for c in range(board.cols):
			var p: BoardPiece = board.grid[r][c]
			if p != Board.EMPTY and p.owner_team == ai_team and p.data != null and p.data.id == "commander":
				return true
	return false

func check_custom_victory() -> Dictionary:
	if hard_modifiers.has("TARGET_PIECE"):
		if commander_eliminated or not _is_commander_alive_on_board():
			var reward = calculate_reward_gold()
			var details = "OBJETIVO CONCLUIDO!\nO Comandante inimigo foi eliminado!\n\nRecompensas:\n+ %d Ouro (Vitoria)\n+ %d Ouro (%d Capturas)\n+ %d Ouro (%d Pecas Sobreviventes)\n\nRecompensa Total: +%d Ouro" % [
				reward.base, reward.captures, captures_by_player, reward.survival, reward.survival, reward.total
			]
			return {
				"ended": true,
				"won": true,
				"title": "VITORIA TATICA!",
				"details": details
			}
	return {"ended": false, "won": false, "title": "", "details": ""}

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
