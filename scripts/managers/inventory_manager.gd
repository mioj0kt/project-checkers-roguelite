class_name InventoryManager
extends RefCounted

var pieces: Array[PieceData] = []

func add_piece_to_inventory(piece: PieceData) -> void:
	pieces.append(piece)

func remove_piece_by_id(piece_id: String) -> PieceData:
	for i in range(pieces.size()):
		if pieces[i].id == piece_id:
			var removed = pieces[i]
			pieces.remove_at(i)
			return removed
	return null

func remove_piece(piece: PieceData) -> bool:
	var idx = pieces.find(piece)
	if idx != -1:
		pieces.remove_at(idx)
		return true
	return false

func get_all_pieces() -> Array[PieceData]:
	return pieces

func get_piece_count_by_id(piece_id: String) -> int:
	var count = 0
	for p in pieces:
		if p.id == piece_id:
			count += 1
	return count
