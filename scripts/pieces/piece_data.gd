class_name PieceData
extends Resource

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	LEGENDARY,
	KING
}

@export var id: String = "standard"
@export var name: String = "Comum"
@export var description: String = "Move-se 1 casa para frente na diagonal. Captura saltando sobre peças inimigas."
@export var rarity: Rarity = Rarity.COMMON

@export var texture_white_path: String = "res://assets/pieces/white.png"      
@export var texture_black_path: String = "res://assets/pieces/black.png"     

@export var texture_white_king_path: String = "res://assets/pieces/white-king.png"
@export var texture_black_king_path: String = "res://assets/pieces/black-king.png"

@export var color_override: Color = Color.TRANSPARENT
@export var is_king: bool = false
@export var freeze_turns: int = 0

func clone() -> PieceData:
	var copy = self.duplicate(true) as PieceData
	copy.is_king = self.is_king
	copy.freeze_turns = self.freeze_turns
	copy.rarity = self.rarity
	copy.texture_white_path = self.texture_white_path
	copy.texture_black_path = self.texture_black_path
	copy.texture_white_king_path = self.texture_white_king_path
	copy.texture_black_king_path = self.texture_black_king_path
	return copy

func get_texture_for_team(owner_team: int) -> String:
	if owner_team == Board.WHITE:
		if is_king and texture_white_king_path != "":
			return texture_white_king_path
		return texture_white_path
	elif owner_team == Board.BLACK:
		if is_king and texture_black_king_path != "":
			return texture_black_king_path
		return texture_black_path
	return ""

func get_rarity_name() -> String:
	if rarity == Rarity.KING:
		return "Dama"
	match rarity:
		Rarity.COMMON: return "Comum"
		Rarity.UNCOMMON: return "Incomum"
		Rarity.RARE: return "Rara"
		Rarity.LEGENDARY: return "Lendária"
		_: return "Comum"

func get_rarity_color() -> Color:
	if rarity == Rarity.KING:
		return Color(1.0, 0.0, 0.0, 1.0)
	match rarity:
		Rarity.COMMON: return Color(0.68, 0.72, 0.78)
		Rarity.UNCOMMON: return Color(0.28, 0.65, 1.0) 
		Rarity.RARE: return Color(0.78, 0.35, 0.95)
		Rarity.LEGENDARY: return Color(1.0, 0.84, 0.0) 
		_: return Color.WHITE

func get_display_color() -> Color:
	if freeze_turns > 0:
		return Color(0.3, 0.85, 0.55)
	if color_override != Color.TRANSPARENT:
		return color_override
	return get_rarity_color()

func get_description() -> String:
	var desc = description
	if is_king:
		desc += "\n[Dama]: Move-se e captura em todas as direções diagonais."
	if freeze_turns > 0:
		desc += "\n\n[PRESO NA TEIA]: Esta peça foi emboscada e está completamente paralisada! Não pode andar ou capturar.\n⏳ Rounds restantes: %d" % freeze_turns
	return desc
	
func take_damage(board: RefCounted, my_pos: Vector2i) -> bool:
	if can_survive_capture():
		return false # Sobreviveu, não deve ser destruída
	
	# Se não sobreviveu, remove da grade do tabuleiro
	board.grid[my_pos.y][my_pos.x] = null
	return true # Foi destruída

func get_move_directions(move_up: bool) -> Array[Vector2i]:
	if is_king:
		return [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]
	var y = -1 if move_up else 1
	return [Vector2i(-1, y), Vector2i(1, y)]

func get_step_distance() -> int:
	return 1

func on_captured(_board: RefCounted, _capturer_pos: Vector2i, _my_pos: Vector2i) -> void:
	pass

func can_survive_capture() -> bool:
	return false

func get_custom_moves(_board: RefCounted, _r: int, _c: int, _owner_team: int) -> Variant:
	return null

func on_after_move(_board: RefCounted, _from_pos: Vector2i, _to_pos: Vector2i) -> void:
	pass
