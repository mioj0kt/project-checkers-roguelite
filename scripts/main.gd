extends Node2D

const MAP_SCENE_PATH = "res://map_view.tscn"

var cell_size: float = 64.0
var board_offset: Vector2 = Vector2.ZERO
var board: Board
var current_duel: DuelBase

var selected_tile: Vector2i = Vector2i(-1, -1)
var valid_moves_for_selected: Array = []
var current_turn: int = Board.WHITE
var is_ai_thinking: bool = false
var is_starting_match: bool = true
var is_game_over: bool = false
var multi_jump_tile: Vector2i = Vector2i(-1, -1)

var human_team: int = Board.WHITE
var ai_team: int = Board.BLACK

# Visual e Animações
var piece_spawn_scales: Dictionary = {}
var animating_coronation_tile: Vector2i = Vector2i(-1, -1)
var moving_piece_tile: Vector2i = Vector2i(-1, -1)
var selection_pulse: float = 1.0
var pulse_tween: Tween

# Módulos Visuais
var coin_flip_view: CoinFlipView
var king_animation_view: KingAnimationView
var piece_movement_view: PieceMovementAnimationView
var frog_animation_view: FrogBossAnimationView
var piece_shatter_view: PieceShatterView
var sudden_death_mgr: SuddenDeathManager
var rule_banner_view: RuleTriggerBannerView

# Sistema de Cartas Ativas (Mão e Deck)
var card_deck_mgr: CardDeckManager
var card_hand_ui: CardHandUI
var selected_action_card: ActionCard = null
var selected_action_card_idx: int = -1

# Variáveis das Novas Cartas de Ação
var extra_turns_pending: int = 0
var temporary_retreat_piece_pos: Vector2i = Vector2i(-1, -1)
var show_enemy_threats: bool = false
var lost_piece_last_enemy_turn: bool = false

# Interface (UI)
var game_over_modal: GameOverModal
var rule_reward_modal: RuleRewardModal
var action_card_reward_modal: ActionCardRewardModal
var inventory_ui: InventoryUI
var modifier_banner: Label
var hud_bar: HUDBar

func _ready() -> void:
	var active_size = RunManager.current_board_size if RunManager != null else Vector2i(8, 8)
	var node_type = RunManager.current_node_type if RunManager != null else 1
	var is_hard_or_boss = (node_type == MapNode.NodeType.DueloForte or node_type == MapNode.NodeType.Chefe)

	if node_type == MapNode.NodeType.Chefe:
		current_duel = DuelBoss.new()
	elif node_type == MapNode.NodeType.DueloForte:
		current_duel = DuelHard.new()
	else:
		current_duel = DuelStandard.new()

	var b_rows = active_size.x
	var b_cols = active_size.y

	var max_dim = max(b_rows, b_cols)
	if max_dim >= 12:
		cell_size = 64.0
	elif max_dim >= 10:
		cell_size = 74.0
	elif max_dim <= 6:
		cell_size = 104.0
	else:
		cell_size = 88.0

	var viewport_size = get_viewport_rect().size
	var total_width = b_cols * cell_size
	var total_height = b_rows * cell_size

	var center_x = (viewport_size.x - total_width) / 2.0
	var available_y = viewport_size.y - 240.0
	var center_y = clampf((available_y - total_height) / 2.0 + 10.0, 50.0, available_y - total_height)

	board_offset = Vector2(center_x, center_y)

	board = Board.new(b_rows, b_cols)
	board.set_theme_for_duel(is_hard_or_boss)

	var pipeline = RulePipeline.new()
	if RunManager != null:
		for card in RunManager.active_rules:
			pipeline.add_rule(card)

	if node_type == MapNode.NodeType.DueloForte:
		pipeline.add_rule(RuleIronCrown.new())

	board.set_rule_pipeline(pipeline)
	board.piece_destroyed.connect(_on_board_piece_destroyed)

	_setup_modules(total_width, max_dim)
	_setup_ui()
	_setup_action_cards()
	_start_selection_pulse_loop()
	_start_match_flow()

func _setup_modules(total_width: float, max_dim: int) -> void:
	coin_flip_view = CoinFlipView.new()
	add_child(coin_flip_view)
	coin_flip_view.flip_completed.connect(_on_coin_flip_completed)

	king_animation_view = KingAnimationView.new()
	add_child(king_animation_view)

	piece_movement_view = PieceMovementAnimationView.new()
	add_child(piece_movement_view)

	frog_animation_view = FrogBossAnimationView.new()
	add_child(frog_animation_view)
	frog_animation_view.configure(board_offset, cell_size)

	piece_shatter_view = PieceShatterView.new()
	add_child(piece_shatter_view)

	sudden_death_mgr = SuddenDeathManager.new()
	add_child(sudden_death_mgr)
	sudden_death_mgr.configure(board_offset, total_width, max_dim)
	sudden_death_mgr.match_finished_by_points.connect(_on_sudden_death_ended)

	rule_banner_view = RuleTriggerBannerView.new()
	add_child(rule_banner_view)

func _setup_ui() -> void:
	var ui_layer = CanvasLayer.new()
	ui_layer.name = "MainUILayer"
	add_child(ui_layer)

	hud_bar = HUDBar.new()
	ui_layer.add_child(hud_bar)
	hud_bar.open_laws_requested.connect(toggle_inventory)

	modifier_banner = Label.new()
	modifier_banner.position = Vector2(board_offset.x, max(14.0, board_offset.y - 44.0))
	modifier_banner.custom_minimum_size = Vector2(board.cols * cell_size, 34.0)
	modifier_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modifier_banner.add_theme_font_size_override("font_size", 24)
	modifier_banner.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	modifier_banner.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 1.0))
	modifier_banner.add_theme_constant_override("outline_size", 6)
	ui_layer.add_child(modifier_banner)

	inventory_ui = InventoryUI.new()
	ui_layer.add_child(inventory_ui)
	inventory_ui.setup()

	game_over_modal = GameOverModal.new()
	game_over_modal.action_confirmed.connect(_on_game_over_action)
	ui_layer.add_child(game_over_modal)

	rule_reward_modal = RuleRewardModal.new()
	rule_reward_modal.reward_completed.connect(_on_rule_reward_draft_finished)
	ui_layer.add_child(rule_reward_modal)

	action_card_reward_modal = ActionCardRewardModal.new()
	action_card_reward_modal.card_chosen.connect(func(_c): get_tree().call_deferred("change_scene_to_file", MAP_SCENE_PATH))
	action_card_reward_modal.skipped.connect(func(): get_tree().call_deferred("change_scene_to_file", MAP_SCENE_PATH))
	ui_layer.add_child(action_card_reward_modal)

func _setup_action_cards() -> void:
	card_deck_mgr = CardDeckManager.new()
	
	if RunManager != null and RunManager.player_deck.is_empty():
		RunManager.start_new_run()

	var starting_deck = RunManager.player_deck if RunManager != null else []
	card_deck_mgr.setup_duel(starting_deck)

	# 1. Entrega o gerenciador de deck para o HUDBar exibir as pilhas no painel lateral
	if hud_bar != null:
		hud_bar.setup_deck_manager(card_deck_mgr)

	card_hand_ui = CardHandUI.new()
	add_child(card_hand_ui)
	# 2. Conecta o card_hand_ui passando o deck_mgr e a referência do hud_bar
	card_hand_ui.setup(card_deck_mgr, hud_bar)

	card_hand_ui.card_clicked_for_target.connect(_on_card_selected_from_hand)
	card_hand_ui.card_drag_started.connect(_on_card_drag_started)
	card_hand_ui.card_drag_released.connect(_on_card_drag_released)
	card_hand_ui.card_selection_cancelled.connect(_on_card_selection_cancelled)

func _on_card_drag_started(card: ActionCard, idx: int) -> void:
	if current_turn != human_team or is_ai_thinking:
		card_hand_ui.cancel_selection(false)
		return

	var context = {"main": self, "deck_mgr": card_deck_mgr}
	if not card.can_play(board, human_team, context):
		card_hand_ui.cancel_selection(false)
		return

	selected_action_card = card
	selected_action_card_idx = idx
	selected_tile = Vector2i(-1, -1)
	valid_moves_for_selected = []
	queue_redraw()

func _on_card_drag_released(card: ActionCard, _idx: int, screen_pos: Vector2) -> void:
	if selected_action_card == null:
		return

	var grid_pos = Vector2i((screen_pos - board_offset) / cell_size)
	var context = {"main": self, "deck_mgr": card_deck_mgr}

	if board.is_valid_pos(grid_pos.y, grid_pos.x) and card.is_valid_target(board, grid_pos, human_team, context):
		_execute_selected_card(grid_pos)
	else:
		_on_card_selection_cancelled()

func _on_card_selected_from_hand(card: ActionCard, idx: int) -> void:
	if current_turn != human_team or is_ai_thinking:
		card_hand_ui.cancel_selection(false)
		return

	var context = {"main": self, "deck_mgr": card_deck_mgr}
	if not card.can_play(board, human_team, context):
		card_hand_ui.cancel_selection(false)
		return

	selected_action_card = card
	selected_action_card_idx = idx
	selected_tile = Vector2i(-1, -1)
	valid_moves_for_selected = []
	queue_redraw()

	if card.target_type == ActionCard.TargetType.NONE:
		_execute_selected_card(Vector2i.ZERO)

func _on_card_selection_cancelled() -> void:
	selected_action_card = null
	selected_action_card_idx = -1
	if card_hand_ui and card_hand_ui.selected_card_idx != -1:
		card_hand_ui.cancel_selection(false)
	queue_redraw()

func _execute_selected_card(pos: Vector2i) -> void:
	if selected_action_card == null:
		return

	var context = {
		"main": self,
		"deck_mgr": card_deck_mgr
	}

	selected_action_card.execute(board, pos, human_team, context)

	# Descarta a carta da mão e a envia permanentemente para o descarte deste duelo
	if card_deck_mgr != null and selected_action_card_idx >= 0:
		card_deck_mgr.play_card_at(selected_action_card_idx)

	_on_card_selection_cancelled()
	_update_gold_display()
	queue_redraw()

func _update_gold_display() -> void:
	if hud_bar != null:
		hud_bar.update_gold()

func _start_match_flow() -> void:
	is_starting_match = true
	is_game_over = false
	multi_jump_tile = Vector2i(-1, -1)
	extra_turns_pending = 0
	temporary_retreat_piece_pos = Vector2i(-1, -1)
	show_enemy_threats = false
	lost_piece_last_enemy_turn = false
	_on_card_selection_cancelled()
	sudden_death_mgr.reset()
	game_over_modal.visible = false
	_update_gold_display()

	var coin_center = board_offset + Vector2((board.cols * cell_size) / 2.0, (board.rows * cell_size) / 2.0)
	coin_flip_view.play_toss(coin_center, cell_size)

func _on_coin_flip_completed(player_won_white: bool) -> void:
	human_team = Board.WHITE if player_won_white else Board.BLACK
	ai_team = Board.BLACK if player_won_white else Board.WHITE

	board.setup_match(human_team, ai_team)

	current_duel.setup(board, human_team, ai_team, sudden_death_mgr)
	current_duel.apply_board_modifiers()
	modifier_banner.text = current_duel.get_banner_text()

	if current_duel is DuelBoss:
		var boss_duel = current_duel as DuelBoss
		boss_duel.should_spawn_new_flies = false
		frog_animation_view.spawn_new_flies(boss_duel.hazard_tiles)

	piece_spawn_scales.clear()
	var spawn_tween = create_tween().set_parallel(true)
	var delay = 0.0

	for r in range(board.rows):
		for c in range(board.cols):
			var pos = Vector2i(c, r)
			if board.grid[r][c] != Board.EMPTY:
				piece_spawn_scales[pos] = 0.0
				spawn_tween.tween_method(func(v): piece_spawn_scales[pos] = v; queue_redraw(), 0.0, 1.0, 0.35)\
					.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				delay += 0.02

	await spawn_tween.finished
	is_starting_match = false

	_on_battle_started()
	queue_redraw()

func _on_battle_started() -> void:
	current_turn = Board.WHITE
	queue_redraw()
	if ai_team == Board.WHITE:
		play_ai_turn()

func _on_board_piece_destroyed(grid_pos: Vector2i, destroyed_piece: BoardPiece) -> void:
	var piece_center = board_offset + Vector2(grid_pos.x * cell_size + cell_size / 2.0, grid_pos.y * cell_size + cell_size / 2.0)
	piece_shatter_view.shatter_piece(piece_center, destroyed_piece, cell_size)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if _handle_debug_keys(event.keycode):
			return
		if event.keycode == KEY_TAB:
			toggle_inventory()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_ESCAPE:
			if selected_action_card != null:
				_on_card_selection_cancelled()
				return
			if inventory_ui and inventory_ui.visible:
				inventory_ui.visible = false
				return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if selected_action_card != null:
			_on_card_selection_cancelled()
			return

	if is_starting_match and coin_flip_view and coin_flip_view.is_animating:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			coin_flip_view.skip_spin()
			return

	if is_game_over or is_starting_match or (inventory_ui and inventory_ui.visible):
		return

	if is_ai_thinking or current_turn != human_team or (king_animation_view and king_animation_view.is_animating) or (frog_animation_view and frog_animation_view.is_attacking) or (piece_movement_view and piece_movement_view.is_animating):
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var grid_pos = Vector2i((event.position - board_offset) / cell_size)
		if board.is_valid_pos(grid_pos.y, grid_pos.x):
			handle_cell_click(grid_pos)

func handle_cell_click(pos: Vector2i) -> void:
	# 1. Se uma Carta de Ação estiver aguardando um alvo no tabuleiro
	if selected_action_card != null:
		var context = {"main": self, "deck_mgr": card_deck_mgr}
		if selected_action_card.is_valid_target(board, pos, human_team, context):
			_execute_selected_card(pos)
		return

	# 2. Execução de Movimento de Peça Comum ou Captura
	for m in valid_moves_for_selected:
		if m["to"] == pos:
			var from_pos: Vector2i = m["from"]
			var moving_piece: BoardPiece = board.grid[from_pos.y][from_pos.x]
			var was_capture: bool = m["is_capture"]

			moving_piece_tile = from_pos
			selected_tile = Vector2i(-1, -1)
			valid_moves_for_selected = []
			queue_redraw()

			var from_center = board_offset + Vector2(from_pos.x * cell_size + cell_size / 2.0, from_pos.y * cell_size + cell_size / 2.0)
			var to_center = board_offset + Vector2(pos.x * cell_size + cell_size / 2.0, pos.y * cell_size + cell_size / 2.0)

			await piece_movement_view.play_move_jump(from_center, to_center, moving_piece, cell_size, was_capture)
			moving_piece_tile = Vector2i(-1, -1)

			if board.rule_pipeline != null:
				if not moving_piece.is_king and pos.y > from_pos.y and board.rule_pipeline.has_rule("reverse_movement"):
					rule_banner_view.pop_rule_trigger(to_center, "REVERSO!", Color(0.3, 0.75, 1.0))
				elif not was_capture and abs(pos.y - from_pos.y) == 2 and board.rule_pipeline.has_rule("ally_hop"):
					rule_banner_view.pop_rule_trigger(to_center, "SALTO CAMARADA!", Color(0.4, 0.9, 0.5))

			if was_capture:
				var cap_pos = m["captured"]
				var captured_p: BoardPiece = board.grid[cap_pos.y][cap_pos.x]
				current_duel.on_piece_captured(captured_p)

			if current_duel is DuelBoss:
				frog_animation_view.hop_fly_at(m["from"])
				frog_animation_view.hop_fly_at(m["to"])

			var promoted = board.make_move(m)
			current_duel.on_turn_end(board)

			if was_capture and hud_bar != null:
				hud_bar.update_gold()

			queue_redraw()

			if promoted:
				var piece: BoardPiece = board.grid[pos.y][pos.x]
				if piece != Board.EMPTY:
					var center = board_offset + Vector2(pos.x * cell_size + cell_size / 2.0, pos.y * cell_size + cell_size / 2.0)
					if board.rule_pipeline != null and board.rule_pipeline.has_rule("early_promotion") and pos.y > 0:
						rule_banner_view.pop_rule_trigger(center, "PROMOCAO RELAMPAGO!", Color(1.0, 0.85, 0.25))

					animating_coronation_tile = pos
					queue_redraw()
					await king_animation_view.play_coronation(center, cell_size, piece)
					animating_coronation_tile = Vector2i(-1, -1)
					queue_redraw()

			# Multissalto em cadeia
			if was_capture and not promoted:
				var follow_up_captures = board.get_piece_captures(pos.y, pos.x)
				if not follow_up_captures.is_empty():
					multi_jump_tile = pos
					selected_tile = pos
					valid_moves_for_selected = follow_up_captures
					rule_banner_view.pop_rule_trigger(to_center, "+COMBO!", Color(1.0, 0.4, 0.2))
					queue_redraw()
					return

			multi_jump_tile = Vector2i(-1, -1)

			# Regra de Segundo Movimento
			var second_move_rule: RuleSecondMove = null
			if board.rule_pipeline != null:
				for r in board.rule_pipeline.active_rules:
					if r is RuleSecondMove:
						second_move_rule = r
						break

			if not was_capture and second_move_rule != null and not second_move_rule.has_used_extra_step:
				second_move_rule.has_used_extra_step = true
				rule_banner_view.pop_rule_trigger(to_center, "PASSO EXTRA!", Color(0.4, 0.9, 0.5))
				queue_redraw()
				return

			await _process_boss_turn_events()
			end_turn()
			return

	if multi_jump_tile != Vector2i(-1, -1):
		return

	# 3. Seleção de Peça no Tabuleiro
	var piece: BoardPiece = board.grid[pos.y][pos.x]
	if piece != Board.EMPTY and piece.owner_team == human_team:
		selected_tile = pos
		var moves = board.get_all_valid_moves(human_team).filter(func(m): return m["from"] == pos)

		# Injeção do passo da Carta 'Recuar' se estiver ativa
		if temporary_retreat_piece_pos == pos and not piece.is_king:
			var back_dirs = [Vector2i(-1, 1), Vector2i(1, 1)]
			for bd in back_dirs:
				var nr = pos.y + bd.y
				var nc = pos.x + bd.x
				if board.is_valid_pos(nr, nc) and board.grid[nr][nc] == Board.EMPTY and not board.scorched_tiles.has(Vector2i(nc, nr)):
					moves.append({
						"from": pos,
						"to": Vector2i(nc, nr),
						"is_capture": false,
						"captured": Vector2i(-1, -1)
					})

		valid_moves_for_selected = moves
		queue_redraw()

func play_ai_turn() -> void:
	if is_game_over:
		return

	if frog_animation_view and (frog_animation_view.is_attacking or frog_animation_view.is_spawning_flies):
		await get_tree().create_timer(0.2).timeout
		if frog_animation_view.is_attacking:
			await frog_animation_view.attack_sequence_finished
		if frog_animation_view.is_spawning_flies:
			await frog_animation_view.flies_spawn_finished

	is_ai_thinking = true
	lost_piece_last_enemy_turn = false
	await get_tree().create_timer(0.3).timeout
	await get_tree().process_frame

	var search_depth = 3 if max(board.rows, board.cols) >= 10 else 4
	var ai_move = CheckersAI.get_best_move(board, search_depth, ai_team)
	
	while ai_move.size() > 0:
		var from_pos = ai_move["from"]
		var target_pos = ai_move["to"]
		var moving_piece: BoardPiece = board.grid[from_pos.y][from_pos.x]
		var was_capture: bool = ai_move.get("is_capture", false)

		moving_piece_tile = from_pos
		queue_redraw()

		var from_center = board_offset + Vector2(from_pos.x * cell_size + cell_size / 2.0, from_pos.y * cell_size + cell_size / 2.0)
		var to_center = board_offset + Vector2(target_pos.x * cell_size + cell_size / 2.0, target_pos.y * cell_size + cell_size / 2.0)

		await piece_movement_view.play_move_jump(from_center, to_center, moving_piece, cell_size, was_capture)
		moving_piece_tile = Vector2i(-1, -1)

		if was_capture:
			lost_piece_last_enemy_turn = true
			var cap_pos = ai_move["captured"]
			var captured_p: BoardPiece = board.grid[cap_pos.y][cap_pos.x]
			current_duel.on_piece_captured(captured_p)

		if current_duel is DuelBoss:
			frog_animation_view.hop_fly_at(ai_move["from"])
			frog_animation_view.hop_fly_at(ai_move["to"])

		var promoted = board.make_move(ai_move)
		current_duel.on_turn_end(board)

		if promoted:
			var piece: BoardPiece = board.grid[target_pos.y][target_pos.x]
			if piece != Board.EMPTY:
				var center = board_offset + Vector2(target_pos.x * cell_size + cell_size / 2.0, target_pos.y * cell_size + cell_size / 2.0)
				animating_coronation_tile = target_pos
				queue_redraw()
				await king_animation_view.play_coronation(center, cell_size, piece)
				animating_coronation_tile = Vector2i(-1, -1)
				queue_redraw()

		if was_capture and not promoted:
			var follow_ups = board.get_piece_captures(target_pos.y, target_pos.x)
			if not follow_ups.is_empty():
				await get_tree().create_timer(0.25).timeout
				ai_move = follow_ups[0]
				continue

		break

	await _process_boss_turn_events()
	is_ai_thinking = false

	if not _check_game_over():
		current_turn = human_team

		# Compra 1 carta respeitando o limite máximo de 5 da mão
		if card_deck_mgr != null:
			card_deck_mgr.on_turn_started()

		# Reseta modificadores de turno
		temporary_retreat_piece_pos = Vector2i(-1, -1)
		show_enemy_threats = false

		if board.rule_pipeline != null:
			board.rule_pipeline.emit_event(&"turn_started", {}, board)

		queue_redraw()

func _process_boss_turn_events() -> void:
	if not (current_duel is DuelBoss):
		return

	var boss_duel = current_duel as DuelBoss
	if boss_duel.should_trigger_devour:
		boss_duel.should_trigger_devour = false
		await frog_animation_view.play_tongue_attack(board, boss_duel.pending_devour_tiles)

		if boss_duel.should_spawn_new_flies:
			boss_duel.should_spawn_new_flies = false
			await frog_animation_view.spawn_new_flies(boss_duel.hazard_tiles)
	elif boss_duel.should_spawn_new_flies:
		boss_duel.should_spawn_new_flies = false
		await frog_animation_view.spawn_new_flies(boss_duel.hazard_tiles)

	queue_redraw()

func end_turn() -> void:
	if _check_game_over():
		return

	# Carta de Ação: Segundo Turno ativo
	if extra_turns_pending > 0:
		extra_turns_pending -= 1
		rule_banner_view.pop_rule_trigger(
			board_offset + Vector2(board.cols * cell_size / 2.0, board.rows * cell_size / 2.0),
			"TURNO EXTRA!",
			Color(1.0, 0.85, 0.2)
		)
		if card_deck_mgr != null:
			card_deck_mgr.on_turn_started()
		queue_redraw()
		return

	current_turn = ai_team
	queue_redraw()
	play_ai_turn()

func _trigger_game_over(won: bool, rewards: Dictionary = {}, custom_title: String = "") -> void:
	is_game_over = true
	selected_tile = Vector2i(-1, -1)
	valid_moves_for_selected = []
	_on_card_selection_cancelled()
	_update_gold_display()
	queue_redraw()
	game_over_modal.show_game_over(won, rewards, custom_title)

func _check_game_over() -> bool:
	var custom_res = current_duel.check_custom_victory()
	if custom_res.ended:
		var reward = current_duel.calculate_reward_gold() if custom_res.won else {}
		_trigger_game_over(custom_res.won, reward, custom_res.title)
		return true

	if current_duel.uses_sudden_death() and sudden_death_mgr.process_turn_end(board, human_team, ai_team):
		return true

	if board.get_all_valid_moves(ai_team).is_empty() and not current_duel.requires_full_elimination():
		var reward = current_duel.calculate_reward_gold()
		_trigger_game_over(true, reward, "VITORIA NO DUELO!")
		return true
	elif board.get_all_valid_moves(human_team).is_empty():
		_trigger_game_over(false)
		return true

	return false

func _on_sudden_death_ended(won: bool, _base_msg: String) -> void:
	if won:
		var reward = current_duel.calculate_reward_gold()
		_trigger_game_over(true, reward, "VITORIA NO DUELO!")
	else:
		_trigger_game_over(false)

func _on_game_over_action(won: bool) -> void:
	if won:
		game_over_modal.visible = false
		var node_type = RunManager.current_node_type if RunManager != null else MapNode.NodeType.Duelo

		if node_type == MapNode.NodeType.DueloForte:
			rule_reward_modal.open_reward_draft()
		else:
			action_card_reward_modal.prompt_reward()
	else:
		if RunManager != null:
			RunManager.start_new_run()
		get_tree().call_deferred("change_scene_to_file", MAP_SCENE_PATH)

func _on_rule_reward_draft_finished() -> void:
	get_tree().call_deferred("change_scene_to_file", MAP_SCENE_PATH)

func toggle_inventory() -> void:
	if inventory_ui:
		inventory_ui.toggle_visibility()

func _start_selection_pulse_loop() -> void:
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_method(func(val): selection_pulse = val; queue_redraw(), 1.0, 1.2, 0.4).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_method(func(val): selection_pulse = val; queue_redraw(), 1.2, 1.0, 0.4).set_trans(Tween.TRANS_SINE)

func _draw() -> void:
	for r in range(board.rows):
		for c in range(board.cols):
			var rect = Rect2(board_offset.x + c * cell_size, board_offset.y + r * cell_size, cell_size, cell_size)
			var base_color = board.light_tile_color if (r + c) % 2 == 0 else board.dark_tile_color
			draw_rect(rect, base_color)
			draw_rect(rect, board.grid_border_color, false, 1.0)

	for pos in board.scorched_tiles.keys():
		var tile_rect = Rect2(board_offset.x + pos.x * cell_size, board_offset.y + pos.y * cell_size, cell_size, cell_size)
		draw_rect(tile_rect, Color(1.0, 0.3, 0.05, 0.5))
		PixelRenderer.draw_pixel_corners(self, tile_rect, Color(1.0, 0.75, 0.1, 0.95), 8.0, 2.5)

	if current_duel is DuelBoss:
		for pos in current_duel.hazard_tiles:
			var hazard_rect = Rect2(board_offset.x + pos.x * cell_size, board_offset.y + pos.y * cell_size, cell_size, cell_size)
			draw_rect(hazard_rect, Color(0.85, 0.1, 0.2, 0.35))
			PixelRenderer.draw_pixel_corners(self, hazard_rect, Color(1.0, 0.2, 0.3, 0.85), 8.0, 2.0)

	if selected_tile != Vector2i(-1, -1):
		var selected_rect = Rect2(board_offset.x + selected_tile.x * cell_size, board_offset.y + selected_tile.y * cell_size, cell_size, cell_size)
		PixelRenderer.draw_pixel_selected_tile(self, selected_rect, selection_pulse)

	for m in valid_moves_for_selected:
		var target_rect = Rect2(board_offset.x + m["to"].x * cell_size, board_offset.y + m["to"].y * cell_size, cell_size, cell_size)
		PixelRenderer.draw_pixel_move_target(self, target_rect, m["is_capture"], selection_pulse)

	if show_enemy_threats:
		var enemy_moves = board.get_all_valid_moves(ai_team)
		for em in enemy_moves:
			var threat_rect = Rect2(board_offset.x + em["to"].x * cell_size, board_offset.y + em["to"].y * cell_size, cell_size, cell_size)
			var threat_col = Color(1.0, 0.2, 0.2, 0.4) if em["is_capture"] else Color(1.0, 0.8, 0.2, 0.25)
			draw_rect(threat_rect, threat_col)
			PixelRenderer.draw_pixel_corners(self, threat_rect, Color(1.0, 0.2, 0.2, 0.9), 6.0, 2.0)

	if selected_action_card != null:
		var context = {"main": self, "deck_mgr": card_deck_mgr}
		for r in range(board.rows):
			for c in range(board.cols):
				var pos = Vector2i(c, r)
				if selected_action_card.is_valid_target(board, pos, human_team, context):
					var tile_rect = Rect2(board_offset.x + c * cell_size, board_offset.y + r * cell_size, cell_size, cell_size)
					draw_rect(tile_rect, Color(0.2, 0.8, 1.0, 0.25 * selection_pulse))
					PixelRenderer.draw_pixel_corners(self, tile_rect, Color(0.3, 0.9, 1.0, 0.95), 8.0, 2.0)

	for r in range(board.rows):
		for c in range(board.cols):
			var pos = Vector2i(c, r)
			var piece_obj: BoardPiece = board.grid[r][c]

			if pos == animating_coronation_tile or pos == moving_piece_tile:
				continue

			if piece_obj != Board.EMPTY:
				var center = board_offset + Vector2(c * cell_size + cell_size / 2.0, r * cell_size + cell_size / 2.0)
				var scale_factor = piece_spawn_scales.get(pos, 1.0)
				PixelRenderer.draw_piece(self, piece_obj, center, cell_size, scale_factor)

# ==========================================
# DEBUG E TOGGLES DE LEIS
# ==========================================
func _handle_debug_keys(keycode: int) -> bool:
	if is_starting_match or is_game_over:
		return false

	match keycode:
		KEY_W:
			var reward = current_duel.calculate_reward_gold()
			_trigger_game_over(true, reward, "VITORIA NO DUELO!")
			return true

		KEY_E:
			_trigger_game_over(false)
			return true

		KEY_Q:
			if sudden_death_mgr != null and current_duel.uses_sudden_death():
				sudden_death_mgr.start_immediately()
			return true

		KEY_R:
			if RunManager != null:
				RunManager.start_new_run()
			get_tree().call_deferred("change_scene_to_file", MAP_SCENE_PATH)
			return true

		KEY_1:
			if board.rule_pipeline.has_rule("reverse_movement"):
				board.rule_pipeline.remove_rule("reverse_movement")
				RunManager.remove_rule("reverse_movement")
			else:
				var r = RuleReverseMovement.new()
				board.rule_pipeline.add_rule(r)
				RunManager.add_rule(r)
			if hud_bar != null:
				hud_bar.refresh_deck()
			valid_moves_for_selected = []
			queue_redraw()
			return true

		KEY_2:
			if board.rule_pipeline.has_rule("optional_capture"):
				board.rule_pipeline.remove_rule("optional_capture")
				RunManager.remove_rule("optional_capture")
			else:
				var r = RuleOptionalCapture.new()
				board.rule_pipeline.add_rule(r)
				RunManager.add_rule(r)
			if hud_bar != null:
				hud_bar.refresh_deck()
			valid_moves_for_selected = []
			queue_redraw()
			return true

		KEY_3:
			if board.rule_pipeline.has_rule("early_promotion"):
				board.rule_pipeline.remove_rule("early_promotion")
				RunManager.remove_rule("early_promotion")
			else:
				var r = RuleEarlyPromotion.new()
				board.rule_pipeline.add_rule(r)
				RunManager.add_rule(r)
			if hud_bar != null:
				hud_bar.refresh_deck()
			valid_moves_for_selected = []
			queue_redraw()
			return true

		KEY_4:
			if board.rule_pipeline.has_rule("carnage"):
				board.rule_pipeline.remove_rule("carnage")
				RunManager.remove_rule("carnage")
			else:
				var r = RuleCarnage.new()
				board.rule_pipeline.add_rule(r)
				RunManager.add_rule(r)
			if hud_bar != null:
				hud_bar.refresh_deck()
			valid_moves_for_selected = []
			queue_redraw()
			return true

		KEY_5:
			if board.rule_pipeline.has_rule("revenge"):
				board.rule_pipeline.remove_rule("revenge")
				RunManager.remove_rule("revenge")
			else:
				var r = RuleRevenge.new()
				board.rule_pipeline.add_rule(r)
				RunManager.add_rule(r)
			if hud_bar != null:
				hud_bar.refresh_deck()
			valid_moves_for_selected = []
			queue_redraw()
			return true

		KEY_6:
			if board.rule_pipeline.has_rule("ally_hop"):
				board.rule_pipeline.remove_rule("ally_hop")
				RunManager.remove_rule("ally_hop")
			else:
				var r = RuleAllyHop.new()
				board.rule_pipeline.add_rule(r)
				RunManager.add_rule(r)
			if hud_bar != null:
				hud_bar.refresh_deck()
			valid_moves_for_selected = []
			queue_redraw()
			return true

	return false
