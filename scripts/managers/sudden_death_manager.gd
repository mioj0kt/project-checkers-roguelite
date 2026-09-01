class_name SuddenDeathManager
extends Node2D

signal sudden_death_triggered()
signal match_finished_by_points(won: bool, message: String)

var max_turns: int = 10
var is_active: bool = false
var turns_left: int = 6
var board_offset: Vector2 = Vector2.ZERO
var total_width: float = 0.0
var initial_kings_count: int = 0

func reset() -> void:
	is_active = false
	turns_left = max_turns
	initial_kings_count = 0
	queue_redraw()

func configure(p_board_offset: Vector2, p_total_width: float, max_dim: int = 8) -> void:
	board_offset = p_board_offset
	total_width = p_total_width
	max_turns = max(4, max_dim + 2)
	turns_left = max_turns

func start_immediately() -> void:
	is_active = true
	turns_left = max_turns
	sudden_death_triggered.emit()
	queue_redraw()

func set_initial_kings_baseline(board: Board) -> void:
	initial_kings_count = _count_total_kings(board)

func _count_total_kings(board: Board) -> int:
	var kings = 0
	for r in range(board.rows):
		for c in range(board.cols):
			var p: BoardPiece = board.grid[r][c]
			if p != Board.EMPTY and p.data and p.data.is_king:
				kings += 1
	return kings

func check_conditions(board: Board, human_team: int, ai_team: int) -> void:
	if is_active:
		return

	var human_count = 0
	var ai_count = 0
	var current_kings = 0

	for r in range(board.rows):
		for c in range(board.cols):
			var piece: BoardPiece = board.grid[r][c]
			if piece != Board.EMPTY:
				if piece.owner_team == human_team:
					human_count += 1
				elif piece.owner_team == ai_team:
					ai_count += 1
				if piece.data and piece.data.is_king:
					current_kings += 1

	var new_king_promoted = current_kings > initial_kings_count

	if human_count == 1 or ai_count == 1 or new_king_promoted:
		is_active = true
		turns_left = max_turns
		sudden_death_triggered.emit()
		queue_redraw()

func process_turn_end(board: Board, human_team: int, ai_team: int) -> bool:
	check_conditions(board, human_team, ai_team)

	if not is_active:
		return false

	turns_left -= 1
	queue_redraw()

	if turns_left <= 0:
		_resolve_points(board, human_team, ai_team)
		return true

	return false

func _resolve_points(board: Board, human_team: int, ai_team: int) -> void:
	var human_score = 0
	var ai_score = 0

	for r in range(board.rows):
		for c in range(board.cols):
			var piece: BoardPiece = board.grid[r][c]
			if piece != Board.EMPTY:
				var val = 3 if (piece.data and piece.data.is_king) else 1
				if piece.owner_team == human_team:
					human_score += val
				elif piece.owner_team == ai_team:
					ai_score += val

	var won = human_score >= ai_score
	var title = "MORTE SUBITA ENCERRADA!\n"
	var msg = title + ("VITORIA POR PONTOS (%d x %d)" if won else "DERROTA POR PONTOS (%d x %d)") % [human_score, ai_score]
	
	match_finished_by_points.emit(won, msg)

func _draw() -> void:
	if is_active:
		var banner_h = 52.0
		var banner_rect = Rect2(board_offset.x, board_offset.y - banner_h - 12, total_width, banner_h)
		
		# 1. Fundo Preto Avermelhado
		draw_rect(banner_rect, Color(0.08, 0.02, 0.03, 0.96))
		
		# 2. Sombra e Borda Chanfrada Vermelha
		var shadow_rect = Rect2(banner_rect.position + Vector2(2, 3), banner_rect.size)
		draw_rect(shadow_rect, Color(0, 0, 0, 0.4), false, 2.0)
		draw_rect(banner_rect, Color(0.9, 0.15, 0.2, 0.95), false, 2.5)

		# 3. Cantoneiras Pixeladas de Alerta
		PixelRenderer.draw_pixel_corners(self, banner_rect, Color(1.0, 0.4, 0.45, 1.0), 10.0, 2.5)

		# 4. Texto em Caixa Alta com Fonte Ampliada
		var font = ThemeDB.fallback_font
		var msg = "MORTE SUBITA: %d TURNOS RESTANTES" % turns_left
		var text_pos = Vector2(banner_rect.position.x, banner_rect.position.y + 34)

		# Contorno / Sombra do texto desenhado via draw_string
		draw_string(font, text_pos + Vector2(2, 2), msg, HORIZONTAL_ALIGNMENT_CENTER, banner_rect.size.x, 26, Color(0.05, 0.05, 0.05, 1.0))
		draw_string(font, text_pos, msg, HORIZONTAL_ALIGNMENT_CENTER, banner_rect.size.x, 26, Color(1.0, 0.35, 0.35, 1.0))
