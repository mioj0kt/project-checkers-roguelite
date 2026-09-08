class_name RuleCard
extends RefCounted

enum Category {
	MOVEMENT,
	CAPTURE,
	PROMOTION,
	TURN,
	BOARD,
	COMBO
}

enum Scope {
	PLAYER_ONLY,
	AI_ONLY,
	BOTH
}

enum Rarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var category: Category = Category.MOVEMENT
@export var scope: Scope = Scope.PLAYER_ONLY
@export var rarity: Rarity = Rarity.COMMON
@export var priority: int = 10
@export var cost: int = 5
@export var incompatible_with: Array[String] = []

func applies_to_team(piece_team: int, human_team: int) -> bool:
	match scope:
		Scope.PLAYER_ONLY:
			return piece_team == human_team
		Scope.AI_ONLY:
			return piece_team != human_team
		Scope.BOTH:
			return true
	return false

func modify_move_directions(_piece: BoardPiece, current_dirs: Array[Vector2i], _human_team: int, _board: RefCounted) -> Array[Vector2i]:
	return current_dirs

func modify_step_distance(_piece: BoardPiece, base_distance: int, _board: RefCounted) -> int:
	return base_distance

func evaluate_mandatory_capture(_team: int, default_mandatory: bool) -> bool:
	return default_mandatory

func check_custom_promotion(_piece: BoardPiece, _to_pos: Vector2i, _board: RefCounted) -> bool:
	return false

func on_game_event(_event_name: StringName, _context: Dictionary, _board: RefCounted) -> void:
	pass

static func get_category_color(cat: int) -> Color:
	match cat:
		Category.MOVEMENT:  return Color(0.25, 0.60, 1.0)
		Category.CAPTURE:   return Color(0.95, 0.25, 0.25)
		Category.PROMOTION: return Color(1.00, 0.82, 0.20)
		Category.TURN:      return Color(0.70, 0.35, 0.95)
		Category.BOARD:     return Color(0.25, 0.85, 0.45)
		_:                  return Color(1.00, 0.55, 0.15)

static func get_category_name(cat: int) -> String:
	match cat:
		Category.MOVEMENT:  return "MOVIMENTO"
		Category.CAPTURE:   return "CAPTURA"
		Category.PROMOTION: return "PROMOÇÃO"
		Category.TURN:      return "TURNO"
		Category.BOARD:     return "TABULEIRO"
		_:                  return "COMBO"

static func get_rarity_weight(r: Rarity) -> int:
	match r:
		Rarity.COMMON:    return 60
		Rarity.RARE:      return 28
		Rarity.EPIC:      return 10
		Rarity.LEGENDARY: return 2
	return 50

static func get_rarity_name(r: Rarity) -> String:
	match r:
		Rarity.COMMON:    return "COMUM"
		Rarity.RARE:      return "RARA"
		Rarity.EPIC:      return "ÉPICA"
		Rarity.LEGENDARY: return "LENDÁRIA"
	return "COMUM"
