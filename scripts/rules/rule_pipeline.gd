class_name RulePipeline
extends RefCounted

const MAX_ACTIVE_RULES: int = 6

var active_rules: Array[RuleCard] = []

func add_rule(rule: RuleCard) -> bool:
	if rule == null:
		return false
	if active_rules.size() >= MAX_ACTIVE_RULES:
		return false
	
	for existing in active_rules:
		if existing.id in rule.incompatible_with or rule.id in existing.incompatible_with:
			return false

	active_rules.append(rule)
	_sort_rules()
	return true

func remove_rule(rule_id: String) -> void:
	for i in range(active_rules.size() - 1, -1, -1):
		if active_rules[i].id == rule_id:
			active_rules.remove_at(i)
			break
	_sort_rules()

func clear_rules() -> void:
	active_rules.clear()

func has_rule(rule_id: String) -> bool:
	for r in active_rules:
		if r.id == rule_id:
			return true
	return false

func _sort_rules() -> void:
	active_rules.sort_custom(func(a: RuleCard, b: RuleCard):
		return a.priority < b.priority
	)

# =========================================================
# MÉTODOS DE CONSULTA DO TABULEIRO (PIPELINE RUNNERS)
# =========================================================

func filter_move_directions(piece: BoardPiece, dirs: Array[Vector2i], human_team: int, board: RefCounted) -> Array[Vector2i]:
	var current_dirs: Array[Vector2i] = dirs.duplicate()
	for rule in active_rules:
		if rule.applies_to_team(piece.owner_team, human_team):
			var result = rule.modify_move_directions(piece, current_dirs, human_team, board)
			current_dirs = Array(result, TYPE_VECTOR2I, "", null)
	return current_dirs

func can_capture_backwards(piece: BoardPiece, human_team: int) -> bool:
	for rule in active_rules:
		if rule.applies_to_team(piece.owner_team, human_team):
			if rule.id == "backward_capture" or rule.id == "reverse_movement":
				return true
	return false

func can_hop_allies(piece: BoardPiece, human_team: int) -> bool:
	for rule in active_rules:
		if rule.applies_to_team(piece.owner_team, human_team):
			if rule.id == "ally_hop":
				return true
	return false

func filter_step_distance(piece: BoardPiece, base_distance: int, human_team: int, board: RefCounted) -> int:
	var dist = base_distance
	for rule in active_rules:
		if rule.applies_to_team(piece.owner_team, human_team):
			dist = rule.modify_step_distance(piece, dist, board)
	return dist

func is_capture_mandatory(team: int, human_team: int) -> bool:
	var mandatory = true
	for rule in active_rules:
		if rule.applies_to_team(team, human_team):
			mandatory = rule.evaluate_mandatory_capture(team, mandatory)
	return mandatory

func should_promote_to_king(piece: BoardPiece, to_pos: Vector2i, human_team: int, board: RefCounted) -> bool:
	for rule in active_rules:
		if rule.applies_to_team(piece.owner_team, human_team):
			if rule.check_custom_promotion(piece, to_pos, board):
				return true
	return false

func emit_event(event_name: StringName, context: Dictionary, board: RefCounted) -> void:
	for rule in active_rules:
		rule.on_game_event(event_name, context, board)
