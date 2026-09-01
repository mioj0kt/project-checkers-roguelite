class_name PieceGhost
extends PieceData

func _init() -> void:
	id = "ghost"
	name = "Espectro"
	rarity = Rarity.RARE
	texture_white_path = "res://assets/pieces/ghost-white.png"
	texture_black_path = "res://assets/pieces/ghost-black.png"     
	texture_white_king_path = "res://assets/pieces/ghost-white-king.png"
	texture_black_king_path = "res://assets/pieces/ghost-black-king.png"
	description = "Intangível! Pode andar atravessando peças aliadas sem ser bloqueada, mas só captura peças inimigas normalmente."
	color_override = Color(0.7, 0.45, 0.95, 0.85)

func get_custom_moves(board: RefCounted, r: int, c: int, owner_team: int) -> Variant:
	var moves = []
	var moves_up = (owner_team == board.human_team_color)
	var directions = get_move_directions(moves_up)

	for d in directions:
		# 1. Passo normal de 1 casa
		var nr = r + d.y
		var nc = c + d.x

		if board.is_valid_pos(nr, nc) and not board.scorched_tiles.has(Vector2i(nc, nr)):
			var occ: BoardPiece = board.grid[nr][nc]
			if occ == null:
				moves.append({
					"from": Vector2i(c, r),
					"to": Vector2i(nc, nr),
					"is_capture": false,
					"captured": Vector2i(-1, -1)
				})
			elif occ.owner_team == owner_team:
				# 2. Atravessa peça aliada (Faseamento Fantasma)
				var pass_r = r + (d.y * 2)
				var pass_c = c + (d.x * 2)
				if board.is_valid_pos(pass_r, pass_c) and board.grid[pass_r][pass_c] == null and not board.scorched_tiles.has(Vector2i(pass_c, pass_r)):
					moves.append({
						"from": Vector2i(c, r),
						"to": Vector2i(pass_c, pass_r),
						"is_capture": false,
						"captured": Vector2i(-1, -1)
					})

		# 3. Captura tradicional de peças inimigas
		var cap_r = r + d.y
		var cap_c = c + d.x
		var land_r = r + (d.y * 2)
		var land_c = c + (d.x * 2)

		if board.is_valid_pos(land_r, land_c) and board.grid[land_r][land_c] == null and not board.scorched_tiles.has(Vector2i(land_c, land_r)):
			var target: BoardPiece = board.grid[cap_r][cap_c]
			if target != null and target.owner_team != owner_team:
				moves.append({
					"from": Vector2i(c, r),
					"to": Vector2i(land_c, land_r),
					"is_capture": true,
					"captured": Vector2i(cap_c, cap_r)
				})

	return moves
