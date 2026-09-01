class_name PieceFlyingKing
extends PieceData

func _init() -> void:
	id = "flying_king"
	name = "Dama Voadora"
	rarity = Rarity.LEGENDARY
	texture_white_path = "res://assets/pieces/flying-white.png"
	texture_black_path = "res://assets/pieces/flying-black.png"     
	texture_white_king_path = "res://assets/pieces/flying-white-king.png"
	texture_black_king_path = "res://assets/pieces/flying-black-king.png"
	description = "Ao ser promovida a Dama, ganha voo sem limite de casas em qualquer diagonal livre e captura a longas distâncias."
	color_override = Color(0.2, 0.4, 0.9)

func get_custom_moves(board: RefCounted, r: int, c: int, owner_team: int) -> Variant:
	if not is_king:
		return null

	var moves = []
	var directions = [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]

	for d in directions:
		var dist = 1

		# 1. Anda livremente enquanto a casa estiver vazia
		while true:
			var nr = r + d.y * dist
			var nc = c + d.x * dist

			if not board.is_valid_pos(nr, nc):
				break

			# Fogo bloqueia a passagem inteira
			if board.scorched_tiles.has(Vector2i(nc, nr)):
				break

			var occupant: BoardPiece = board.grid[nr][nc]

			if occupant == null:
				moves.append({
					"from": Vector2i(c, r),
					"to": Vector2i(nc, nr),
					"is_capture": false,
					"captured": Vector2i(-1, -1)
				})
				dist += 1
				continue

			# 2. Peça aliada bloqueia a diagonal
			if occupant.owner_team == owner_team:
				break

			# 3. Peça inimiga: procura casas vazias para pouso logo depois dela
			var land_dist = dist + 1
			while true:
				var lr = r + d.y * land_dist
				var lc = c + d.x * land_dist

				if not board.is_valid_pos(lr, lc):
					break
				if board.grid[lr][lc] != null:
					break
				if board.scorched_tiles.has(Vector2i(lc, lr)):
					break

				moves.append({
					"from": Vector2i(c, r),
					"to": Vector2i(lc, lr),
					"is_capture": true,
					"captured": Vector2i(nc, nr)
				})
				land_dist += 1

			break # Só salta 1 peça por diagonal

	return moves
