class_name BoardPiece
extends RefCounted

var owner_team: int = Board.WHITE
var data: PieceData

func _init(p_owner: int = Board.WHITE, p_data: PieceData = null) -> void:
	owner_team = p_owner
	data = p_data if p_data != null else PieceData.new()

func clone() -> BoardPiece:
	var copy_data = data.clone() if data != null else PieceData.new()
	return BoardPiece.new(owner_team, copy_data)
	
