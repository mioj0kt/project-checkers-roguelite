class_name Board
extends RefCounted

signal piece_destroyed(world_grid_pos: Vector2i, destroyed_piece: BoardPiece)

const EMPTY = null
const WHITE = 1
const BLACK = -1

var rows: int = 8
var cols: int = 8
var board_size: int:
	get: return max(rows, cols)

var grid: Array = []
var scorched_tiles: Dictionary = {}

var human_team_color: int = WHITE
var ai_team_color: int = BLACK

# --- Cores e Paletas ---
var light_tile_color: Color = Color(0.85, 0.74, 0.58)
var dark_tile_color: Color = Color(0.38, 0.26, 0.18)
var grid_border_color: Color = Color(0.1, 0.08, 0.06, 0.4)

const STANDARD_PALETTES = [
	{
		"name": "Madeira Classica",
		"light": Color(0.85, 0.74, 0.58),
		"dark": Color(0.38, 0.26, 0.18),
		"grid": Color(0.1, 0.08, 0.06, 0.4)
	},
	{
		"name": "Marmore & Ardosia",
		"light": Color(0.86, 0.88, 0.9),
		"dark": Color(0.24, 0.26, 0.32),
		"grid": Color(0.08, 0.09, 0.12, 0.45)
	},
	{
		"name": "Templo Noturno",
		"light": Color(0.65, 0.78, 0.88),
		"dark": Color(0.14, 0.22, 0.32),
		"grid": Color(0.05, 0.08, 0.14, 0.5)
	},
	{
		"name": "Masmorra Musgosa",
		"light": Color(0.72, 0.78, 0.65),
		"dark": Color(0.2, 0.28, 0.2),
		"grid": Color(0.06, 0.12, 0.06, 0.45)
	}
]

const HARD_PALETTE = {
	"name": "Infernal Vulcânico",
	"light": Color(0.68, 0.16, 0.2),
	"dark": Color(0.12, 0.03, 0.05),
	"grid": Color(0.03, 0.01, 0.02, 0.7)
}

func _init(p_rows: int = 8, p_cols: int = -1):
	rows = p_rows
	cols = p_cols if p_cols > 0 else p_rows
	_init_empty_grid()

func set_theme_for_duel(is_hard_duel: bool) -> void:
	var chosen = HARD_PALETTE if is_hard_duel else STANDARD_PALETTES.pick_random()
	light_tile_color = chosen["light"]
	dark_tile_color = chosen["dark"]
	grid_border_color = chosen["grid"]

func _init_empty_grid() -> void:
	grid = []
	for r in range(rows):
		var row = []
		for c in range(cols):
			row.append(EMPTY)
		grid.append(row)

func get_max_deployment_rows() -> int:
	return max(1, int(rows * 0.38))

func is_player_deployment_tile(r: int, c: int) -> bool:
	if not is_valid_pos(r, c) or (r + c) % 2 == 0:
		return false
	var max_rows = get_max_deployment_rows()
	return r >= (rows - max_rows) and r < rows

func setup_match(player_team: int, ai_team: int, match_inventory: InventoryManager = null) -> void:
	_init_empty_grid()
	scorched_tiles = {}
	human_team_color = player_team
	ai_team_color = ai_team

	var max_rows = get_max_deployment_rows()
	var capacity_per_side = max_rows * int(ceil(cols / 2.0))

	var player_total_count = match_inventory.get_all_pieces().size() if match_inventory != null else capacity_per_side
	var player_count = clamp(player_total_count, 1, capacity_per_side)

	var ai_count_target = randi_range(player_count - 2, player_count + 2)
	var ai_count = clamp(ai_count_target, 1, capacity_per_side)

	var ai_placed = 0
	for r in range(max_rows):
		for c in range(cols):
			if (r + c) % 2 == 1 and ai_placed < ai_count:
				var ai_p_data = PieceData.new()
				ai_p_data.is_king = false
				grid[r][c] = BoardPiece.new(ai_team, ai_p_data)
				ai_placed += 1

	var player_placed = 0
	for r in range(rows - 1, rows - 1 - max_rows, -1):
		for c in range(cols):
			if (r + c) % 2 == 1 and player_placed < player_count:
				var piece_data: PieceData = null
				if match_inventory != null and not match_inventory.pieces.is_empty():
					piece_data = match_inventory.pieces.pop_front()
				else:
					piece_data = PieceData.new()

				piece_data.is_king = false
				grid[r][c] = BoardPiece.new(player_team, piece_data)
				player_placed += 1

func duplicate_board() -> Board:
	var new_b = Board.new(self.rows, self.cols)
	new_b.human_team_color = self.human_team_color
	new_b.ai_team_color = self.ai_team_color
	new_b.light_tile_color = self.light_tile_color
	new_b.dark_tile_color = self.dark_tile_color
	new_b.grid_border_color = self.grid_border_color
	new_b.scorched_tiles = self.scorched_tiles.duplicate()
	new_b.grid = []
	for r in range(rows):
		var row = []
		for c in range(cols):
			var piece: BoardPiece = self.grid[r][c]
			if piece != EMPTY:
				row.append(piece.clone())
			else:
				row.append(EMPTY)
		new_b.grid.append(row)
	return new_b

func get_all_valid_moves(player: int) -> Array:
	var moves = []
	var captures = []

	for r in range(rows):
		for c in range(cols):
			var piece_obj: BoardPiece = grid[r][c]
			if piece_obj != EMPTY and piece_obj.owner_team == player:
				var piece_moves = get_piece_moves(r, c)
				for m in piece_moves:
					if m["is_capture"]:
						captures.append(m)
					else:
						moves.append(m)

	if captures.size() > 0:
		return captures
	return moves

func get_piece_moves(r: int, c: int) -> Array:
	var moves = []
	var piece_obj: BoardPiece = grid[r][c]
	if piece_obj == EMPTY:
		return moves

	if piece_obj.data.freeze_turns > 0:
		return moves

	var custom_moves = piece_obj.data.get_custom_moves(self, r, c, piece_obj.owner_team)
	if custom_moves != null:
		return custom_moves

	var is_king = piece_obj.data.is_king
	var step_dist = piece_obj.data.get_step_distance() if not is_king else 1
	var moves_up = piece_obj.owner_team == human_team_color
	var directions: Array[Vector2i] = piece_obj.data.get_move_directions(moves_up)

	for d in directions:
		var possible_steps = [step_dist]
		if step_dist > 1 and not is_king:
			if (moves_up and r == 1) or (not moves_up and r == rows - 2):
				possible_steps.append(1)

		for dist in possible_steps:
			var nr = r + (d.y * dist)
			var nc = c + (d.x * dist)

			if is_valid_pos(nr, nc) and grid[nr][nc] == EMPTY and not scorched_tiles.has(Vector2i(nc, nr)):
				moves.append({
					"from": Vector2i(c, r),
					"to": Vector2i(nc, nr),
					"is_capture": false,
					"captured": Vector2i(-1, -1)
				})

		var cap_r = r + d.y
		var cap_c = c + d.x
		var landing_r = r + (d.y * 2)
		var landing_c = c + (d.x * 2)

		if is_valid_pos(landing_r, landing_c) and grid[landing_r][landing_c] == EMPTY and not scorched_tiles.has(Vector2i(landing_c, landing_r)):
			var target: BoardPiece = grid[cap_r][cap_c]
			if target != EMPTY and target.owner_team != piece_obj.owner_team:
				moves.append({
					"from": Vector2i(c, r),
					"to": Vector2i(landing_c, landing_r),
					"is_capture": true,
					"captured": Vector2i(cap_c, cap_r)
				})

	return moves

func make_move(move: Dictionary) -> bool:
	if move.is_empty() or not move.has("from") or not move.has("to"):
		return false

	var from_c = move["from"].x
	var from_r = move["from"].y
	var to_c = move["to"].x
	var to_r = move["to"].y

	var piece_obj: BoardPiece = grid[from_r][from_c]
	if piece_obj == EMPTY:
		return false

	grid[from_r][from_c] = EMPTY
	grid[to_r][to_c] = piece_obj

	piece_obj.data.on_after_move(self, Vector2i(from_c, from_r), Vector2i(to_c, to_r))

	if move["is_capture"]:
		var cap_c = move["captured"].x
		var cap_r = move["captured"].y
		var captured_piece: BoardPiece = grid[cap_r][cap_c]

		if piece_obj.data is PieceMidas:
			piece_obj.data.add_bounty_kill()

		if captured_piece and captured_piece.data:
			var was_destroyed = captured_piece.data.take_damage(self, Vector2i(cap_c, cap_r))
			if was_destroyed:
				piece_destroyed.emit(Vector2i(cap_c, cap_r), captured_piece)

			captured_piece.data.on_captured(self, Vector2i(to_c, to_r), Vector2i(cap_c, cap_r))

	var promoted = false
	if not piece_obj.data.is_king:
		if piece_obj.owner_team == human_team_color and to_r <= 0:
			piece_obj.data.is_king = true
			promoted = true
		elif piece_obj.owner_team == ai_team_color and to_r >= rows - 1:
			piece_obj.data.is_king = true
			promoted = true

	_tick_scorched_tiles()
	_tick_frozen_pieces(piece_obj.owner_team)
	return promoted

func _tick_frozen_pieces(team_that_moved: int) -> void:
	for r in range(rows):
		for c in range(cols):
			var p: BoardPiece = grid[r][c]
			if p != EMPTY and p.owner_team == team_that_moved and p.data.freeze_turns > 0:
				p.data.freeze_turns -= 1

func _tick_scorched_tiles() -> void:
	var expired: Array = []
	for pos in scorched_tiles.keys():
		scorched_tiles[pos] -= 1
		if scorched_tiles[pos] <= 0:
			expired.append(pos)
	for pos in expired:
		scorched_tiles.erase(pos)

func is_valid_pos(r: int, c: int) -> bool:
	return r >= 0 and r < rows and c >= 0 and c < cols

func evaluate_for_team(target_team: int) -> float:
	var score: float = 0.0
	for r in range(rows):
		for c in range(cols):
			var piece_obj: BoardPiece = grid[r][c]
			if piece_obj == EMPTY:
				continue
			var value = 30.0 if piece_obj.data.is_king else 10.0
			if piece_obj.owner_team == human_team_color:
				value += ((rows - 1) - r) * 0.5
			else:
				value += r * 0.5
			if c == 0 or c == cols - 1:
				value += 1.0
			if piece_obj.owner_team == target_team:
				score += value
			else:
				score -= value
	return score
