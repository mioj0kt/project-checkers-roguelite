class_name DuelBoss
extends DuelHard

# --- Chefão #1: O SAPO ---
var hazard_tiles: Array = []
const FLIES_PER_TURN: int = 3
const TURNS_BETWEEN_FLIES: int = 3 # Configurado para 3 turnos

var _turns_since_last_bite: int = 0
var should_trigger_devour: bool = false
var should_spawn_new_flies: bool = false
var pending_devour_tiles: Array = []

func setup(p_board: Board, p_human_team: int, p_ai_team: int, p_sudden_death_mgr: SuddenDeathManager) -> void:
	super.setup(p_board, p_human_team, p_ai_team, p_sudden_death_mgr)
	hazard_tiles = []
	_turns_since_last_bite = 0
	should_trigger_devour = false
	should_spawn_new_flies = false
	pending_devour_tiles.clear()

func _roll_modifiers() -> void:
	hard_modifiers.clear()
	var boss_compatible_mods = [
		"ENEMY_KINGS",
		"EXTRA_PIECES",
		"THEMED_ARMY"
	]
	boss_compatible_mods.shuffle()

	var count = randi_range(1, 2)
	for i in range(count):
		hard_modifiers.append(boss_compatible_mods[i])

	if hard_modifiers.has("THEMED_ARMY"):
		var themes = ["cactus", "spring", "fire", "flying_king", "tank", "ghost", "web", "midas"]
		themed_piece_type = themes.pick_random()

func apply_board_modifiers() -> void:
	super.apply_board_modifiers()
	_roll_fly_tiles()
	should_spawn_new_flies = true # Libera o pouso inicial no começo da partida

func get_banner_text() -> String:
	return "CHEFAO: O SAPO DEVORADOR\nA cada 3 turnos, o sapo estica sua lingua nas casas com moscas!\nElimine todo o exercito inimigo para vencer."

func uses_sudden_death() -> bool:
	return false

func requires_full_elimination() -> bool:
	return true

# Chamado ao final de cada jogada (Jogador ou IA)
func on_turn_end(_board: Board) -> void:
	_turns_since_last_bite += 1

	# Quando atinge o limite de turnos, engatilha o ataque e o novo sorteio
	if _turns_since_last_bite >= TURNS_BETWEEN_FLIES:
		should_trigger_devour = true
		pending_devour_tiles = hazard_tiles.duplicate()
		_roll_fly_tiles()
		should_spawn_new_flies = true
		_turns_since_last_bite = 0

func _roll_fly_tiles() -> void:
	hazard_tiles.clear()

	var candidates: Array = []
	for r in range(board.rows):
		for c in range(board.cols):
			if (r + c) % 2 == 1:
				candidates.append(Vector2i(c, r))

	candidates.shuffle()
	var count = min(FLIES_PER_TURN, candidates.size())
	for i in range(count):
		hazard_tiles.append(candidates[i])

func check_custom_victory() -> Dictionary:
	var ai_pieces_remaining = 0
	for r in range(board.rows):
		for c in range(board.cols):
			var p: BoardPiece = board.grid[r][c]
			if p != Board.EMPTY and p.owner_team == ai_team:
				ai_pieces_remaining += 1

	if ai_pieces_remaining == 0:
		var reward = calculate_reward_gold()
		var details = "+ %d Ouro (Vitoria no Chefe)\n+ %d Ouro (%d Capturas)\n+ %d Ouro (%d Sobreviventes)\n\nTotal: +%d Ouro" % [
			reward.base + 5, reward.captures, captures_by_player, reward.survival, reward.survival, reward.total + 5
		]
		return {
			"ended": true,
			"won": true,
			"title": "CHEFAO DERROTADO!",
			"details": details
		}

	return {"ended": false, "won": false, "title": "", "details": ""}
