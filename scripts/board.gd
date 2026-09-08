class_name Board
extends RefCounted

signal piece_destroyed(grid_pos: Vector2i, piece: BoardPiece)

const EMPTY: BoardPiece = null
const WHITE: int = 1
const BLACK: int = 2

var rows: int = 8
var cols: int = 8
var grid: Array = []

var human_team_color: int = WHITE
var ai_team_color: int = BLACK
var rule_pipeline: RulePipeline = null

var scorched_tiles: Dictionary = {}

var light_tile_color: Color = Color(0.92, 0.92, 0.94)
var dark_tile_color: Color = Color(0.18, 0.20, 0.26)
var grid_border_color: Color = Color(0.12, 0.14, 0.18, 0.4)

func _init(p_rows: int = 8, p_cols: int = 8) -> void:
	rows = p_rows
	cols = p_cols
	grid = []
	for r in range(rows):
		var row_arr = []
		for c in range(cols):
			row_arr.append(EMPTY)
		grid.append(row_arr)

func set_rule_pipeline(pipeline: RulePipeline) -> void:
	rule_pipeline = pipeline

func set_theme_for_duel(is_hard_or_boss: bool) -> void:
	if is_hard_or_boss:
		light_tile_color = Color(0.24, 0.16, 0.18)
		dark_tile_color = Color(0.12, 0.08, 0.09)
		grid_border_color = Color(0.35, 0.10, 0.12, 0.6)
	else:
		light_tile_color = Color(0.90, 0.91, 0.94)
		dark_tile_color = Color(0.16, 0.18, 0.24)
		grid_border_color = Color(0.08, 0.10, 0.14, 0.4)

func clear_board() -> void:
	for r in range(rows):
		for c in range(cols):
			grid[r][c] = EMPTY
	scorched_tiles.clear()

func get_max_deployment_rows() -> int:
	var total_rows = rows
	if total_rows <= 6:
		return 1
	elif total_rows <= 8:
		return 3
	elif total_rows <= 10:
		return 4
	return 5

func setup_match(human_team: int, ai_team: int) -> void:
	clear_board()
	human_team_color = human_team
	ai_team_color = ai_team
	
	var max_rows = get_max_deployment_rows()
	
	for r in range(max_rows):
		for c in range(cols):
			if (r + c) % 2 == 1:
				grid[r][c] = BoardPiece.new(ai_team, false)

	var player_start_row = rows - max_rows
	for r in range(player_start_row, rows):
		for c in range(cols):
			if (r + c) % 2 == 1:
				grid[r][c] = BoardPiece.new(human_team, false)

func is_valid_pos(r: int, c: int) -> bool:
	return r >= 0 and r < rows and c >= 0 and c < cols

func is_center_tile(r: int, c: int) -> bool:
	var mid_r = rows / 2
	var mid_c = cols / 2
	return (r == mid_r or r == mid_r - 1) and (c == mid_c or c == mid_c - 1)

func get_all_valid_moves(team: int) -> Array:
	var moves: Array = []
	var captures: Array = []

	for r in range(rows):
		for c in range(cols):
			var piece: BoardPiece = grid[r][c]
			if piece != EMPTY and piece.owner_team == team:
				var piece_captures = get_piece_captures(r, c)
				if not piece_captures.is_empty():
					captures.append_array(piece_captures)
				else:
					moves.append_array(get_piece_moves(r, c))

	var capture_mandatory = true
	if rule_pipeline != null:
		capture_mandatory = rule_pipeline.is_capture_mandatory(team, human_team_color)

	if capture_mandatory and not captures.is_empty():
		return captures

	return captures + moves

func get_piece_captures(r: int, c: int) -> Array:
	var captures: Array = []
	var piece_obj: BoardPiece = grid[r][c]
	if piece_obj == EMPTY:
		return captures

	var is_king: bool = piece_obj.is_king
	var moves_up: bool = (piece_obj.owner_team == human_team_color)

	var capture_dirs: Array[Vector2i] = []
	var can_capture_backwards = is_king

	if rule_pipeline != null and rule_pipeline.can_capture_backwards(piece_obj, human_team_color):
		can_capture_backwards = true

	if can_capture_backwards:
		capture_dirs.append_array([Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)])
	else:
		if moves_up:
			capture_dirs.append_array([Vector2i(-1, -1), Vector2i(1, -1)])
		else:
			capture_dirs.append_array([Vector2i(-1, 1), Vector2i(1, 1)])

	var can_hop_allies: bool = (rule_pipeline != null and rule_pipeline.can_hop_allies(piece_obj, human_team_color))
	var has_power_center = rule_pipeline != null and rule_pipeline.has_rule("power_center")
	var has_iron_crown = rule_pipeline != null and rule_pipeline.has_rule("iron_crown")

	for d in capture_dirs:
		var cap_r: int = r + d.y
		var cap_c: int = c + d.x
		var landing_r: int = r + (d.y * 2)
		var landing_c: int = c + (d.x * 2)

		if is_valid_pos(landing_r, landing_c) and grid[landing_r][landing_c] == EMPTY and not scorched_tiles.has(Vector2i(landing_c, landing_r)):
			var target: BoardPiece = grid[cap_r][cap_c]
			if target != EMPTY:
				if target.owner_team != piece_obj.owner_team:
					# Validação RulePowerCenter: Alvo aliado no centro imune a peças inimigas comuns
					if has_power_center and target.owner_team == human_team_color and is_center_tile(cap_r, cap_c) and not is_king:
						continue

					# Validação RuleIronCrown: Damas inimigas imunes a peças não-damas
					if has_iron_crown and target.owner_team != human_team_color and target.is_king and not is_king:
						continue

					captures.append({
						"from": Vector2i(c, r),
						"to": Vector2i(landing_c, landing_r),
						"is_capture": true,
						"captured": Vector2i(cap_c, cap_r)
					})
				elif can_hop_allies:
					captures.append({
						"from": Vector2i(c, r),
						"to": Vector2i(landing_c, landing_r),
						"is_capture": false,
						"captured": Vector2i(-1, -1)
					})

	return captures

func get_piece_moves(r: int, c: int) -> Array:
	var moves: Array = []
	var piece_obj: BoardPiece = grid[r][c]
	if piece_obj == EMPTY:
		return moves

	var is_king: bool = piece_obj.is_king
	var moves_up: bool = (piece_obj.owner_team == human_team_color)

	var directions: Array[Vector2i] = []
	if is_king:
		directions.append_array([Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)])
	else:
		if moves_up:
			directions.append_array([Vector2i(-1, -1), Vector2i(1, -1)])
		else:
			directions.append_array([Vector2i(-1, 1), Vector2i(1, 1)])

	if rule_pipeline != null:
		var filtered = rule_pipeline.filter_move_directions(piece_obj, directions, human_team_color, self)
		directions = Array(filtered, TYPE_VECTOR2I, "", null)

	var step_dist: int = 1
	if rule_pipeline != null:
		step_dist = rule_pipeline.filter_step_distance(piece_obj, step_dist, human_team_color, self)

	for d in directions:
		var nr: int = r + (d.y * step_dist)
		var nc: int = c + (d.x * step_dist)

		if is_valid_pos(nr, nc) and grid[nr][nc] == EMPTY and not scorched_tiles.has(Vector2i(nc, nr)):
			moves.append({
				"from": Vector2i(c, r),
				"to": Vector2i(nc, nr),
				"is_capture": false,
				"captured": Vector2i(-1, -1)
			})

	return moves

func make_move(move_dict: Dictionary) -> bool:
	var from_pos: Vector2i = move_dict["from"]
	var to_pos: Vector2i = move_dict["to"]
	var is_cap: bool = move_dict.get("is_capture", false)

	var piece: BoardPiece = grid[from_pos.y][from_pos.x]
	grid[from_pos.y][from_pos.x] = EMPTY
	grid[to_pos.y][to_pos.x] = piece

	if is_cap:
		var cap_pos: Vector2i = move_dict["captured"]
		var cap_piece: BoardPiece = grid[cap_pos.y][cap_pos.x]
		grid[cap_pos.y][cap_pos.x] = EMPTY
		piece_destroyed.emit(cap_pos, cap_piece)

		if rule_pipeline != null:
			# Dispara evento de captura
			rule_pipeline.emit_event(&"piece_captured", {
				"attacker": piece,
				"victim": cap_piece,
				"attacker_pos": to_pos,
				"victim_pos": cap_pos
			}, self)
			# Dispara evento de peça perdida
			rule_pipeline.emit_event(&"piece_lost", {
				"piece": cap_piece,
				"pos": cap_pos
			}, self)
	else:
		if rule_pipeline != null:
			rule_pipeline.emit_event(&"step_moved", {
				"piece": piece,
				"from": from_pos,
				"to": to_pos
			}, self)

	var promoted = false
	if not piece.is_king:
		var target_promotion_row = 0 if (piece.owner_team == human_team_color) else (rows - 1)
		var reached_end = (to_pos.y == target_promotion_row)
		var custom_promo = false

		if rule_pipeline != null:
			custom_promo = rule_pipeline.should_promote_to_king(piece, to_pos, human_team_color, self)

		if reached_end or custom_promo:
			piece.is_king = true
			promoted = true
			if rule_pipeline != null:
				rule_pipeline.emit_event(&"on_promotion", {
					"piece": piece,
					"pos": to_pos
				}, self)

	return promoted

func evaluate_for_team(team: int) -> int:
	var score = 0
	var enemy_team = BLACK if team == WHITE else WHITE

	for r in range(rows):
		for c in range(cols):
			var p: BoardPiece = grid[r][c]
			if p != EMPTY:
				var val = 50 if p.is_king else 10
				if p.owner_team == team:
					score += val
				elif p.owner_team == enemy_team:
					score -= val

	return score

func clone() -> Board:
	var new_b = Board.new(rows, cols)
	new_b.human_team_color = human_team_color
	new_b.ai_team_color = ai_team_color
	new_b.rule_pipeline = rule_pipeline
	new_b.scorched_tiles = scorched_tiles.duplicate()

	for r in range(rows):
		for c in range(cols):
			var p: BoardPiece = grid[r][c]
			if p != EMPTY:
				new_b.grid[r][c] = p.clone()

	return new_b
