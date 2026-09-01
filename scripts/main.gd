extends Node2D

const MAP_SCENE_PATH = "res://map_view.tscn"

var cell_size: float = 64.0
var board_offset: Vector2 = Vector2.ZERO
var board: Board
var match_inventory: InventoryManager
var current_duel: DuelBase

var selected_tile: Vector2i = Vector2i(-1, -1)
var valid_moves_for_selected: Array = []
var current_turn: int = Board.WHITE
var is_ai_thinking: bool = false
var is_starting_match: bool = true
var is_game_over: bool = false

var human_team: int = Board.WHITE
var ai_team: int = Board.BLACK

# Tooltip e Hover Timer
var tooltip_view: PieceTooltip
var hover_tile: Vector2i = Vector2i(-1, -1)
var hover_timer: float = 0.0
const HOVER_DELAY: float = 0.5

# Efeitos Visuais
var piece_spawn_scales: Dictionary = {}
var animating_coronation_tile: Vector2i = Vector2i(-1, -1)
var moving_piece_tile: Vector2i = Vector2i(-1, -1) # Oculta a peça que está pulando
var selection_pulse: float = 1.0
var pulse_tween: Tween

# Módulos
var coin_flip_view: CoinFlipView
var king_animation_view: KingAnimationView
var piece_movement_view: PieceMovementAnimationView
var frog_animation_view: FrogBossAnimationView
var piece_shatter_view: PieceShatterView
var sudden_death_mgr: SuddenDeathManager
var game_over_modal: GameOverModal
var inventory_ui: InventoryUI
var deployment_dock: DeploymentDock
var gold_label: Label
var modifier_banner: Label

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

	match_inventory = InventoryManager.new()
	if RunManager != null and RunManager.inventory != null:
		for p in RunManager.inventory.get_all_pieces():
			match_inventory.add_piece_to_inventory(p.clone())
	else:
		for i in range(10):
			match_inventory.add_piece_to_inventory(PieceData.new())

	var max_dim = max(b_rows, b_cols)
	if max_dim >= 10:
		cell_size = 54.0
	elif max_dim <= 6:
		cell_size = 78.0
	else:
		cell_size = 64.0

	var viewport_size = get_viewport_rect().size
	var total_width = b_cols * cell_size
	var total_height = b_rows * cell_size
	board_offset = Vector2((viewport_size.x - total_width) / 2.0, max(28.0, (viewport_size.y - total_height - 60) / 2.0))

	board = Board.new(b_rows, b_cols)
	board.set_theme_for_duel(is_hard_or_boss)
	board.piece_destroyed.connect(_on_board_piece_destroyed)

	_setup_modules(total_width, max_dim)
	_setup_ui()
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

func _setup_ui() -> void:
	var ui_layer = CanvasLayer.new()
	ui_layer.name = "MainUILayer"
	add_child(ui_layer)

	inventory_ui = InventoryUI.new()
	ui_layer.add_child(inventory_ui)
	inventory_ui.setup(RunManager.inventory if RunManager != null and RunManager.inventory != null else match_inventory)

	inventory_ui.piece_inspect_requested.connect(func(p, pos): tooltip_view.show_for_piece(p, pos, human_team))
	inventory_ui.piece_inspect_dismissed.connect(func(): tooltip_view.hide_tooltip())

	var open_inv_btn = Button.new()
	open_inv_btn.text = "MOCHILA (I)"
	open_inv_btn.position = Vector2(board_offset.x + board.cols * cell_size + 24, board_offset.y + 10)
	open_inv_btn.pressed.connect(toggle_inventory)
	ui_layer.add_child(open_inv_btn)

	gold_label = Label.new()
	gold_label.position = Vector2(board_offset.x + board.cols * cell_size + 24, board_offset.y + 55)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_update_gold_display()
	ui_layer.add_child(gold_label)

	modifier_banner = Label.new()
	modifier_banner.position = Vector2(24, 18)
	modifier_banner.add_theme_font_size_override("font_size", 24)
	modifier_banner.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	modifier_banner.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 1.0))
	modifier_banner.add_theme_constant_override("outline_size", 6)
	ui_layer.add_child(modifier_banner)

	deployment_dock = DeploymentDock.new()
	deployment_dock.battle_started.connect(_on_battle_started)
	deployment_dock.board_modified.connect(func(): queue_redraw())
	deployment_dock.piece_inspect_requested.connect(func(p, pos): tooltip_view.show_for_piece(p, pos, human_team))
	deployment_dock.piece_inspect_dismissed.connect(func(): tooltip_view.hide_tooltip())
	ui_layer.add_child(deployment_dock)

	game_over_modal = GameOverModal.new()
	game_over_modal.action_confirmed.connect(_on_game_over_action)
	ui_layer.add_child(game_over_modal)

	tooltip_view = PieceTooltip.new()
	ui_layer.add_child(tooltip_view)

func _process(delta: float) -> void:
	if is_game_over or is_starting_match:
		return

	if inventory_ui and inventory_ui.visible:
		_reset_hover()
		return

	var mouse_pos = get_global_mouse_position()
	var grid_pos = Vector2i((mouse_pos - board_offset) / cell_size)

	if board.is_valid_pos(grid_pos.y, grid_pos.x):
		var piece: BoardPiece = board.grid[grid_pos.y][grid_pos.x]
		if piece != Board.EMPTY:
			if grid_pos == hover_tile:
				hover_timer += delta
				if hover_timer >= HOVER_DELAY and not tooltip_view.visible:
					tooltip_view.show_for_piece(piece.data, mouse_pos, piece.owner_team)
			else:
				hover_tile = grid_pos
				hover_timer = 0.0
				tooltip_view.hide_tooltip()
		else:
			_reset_hover()
	else:
		_reset_hover()

func _reset_hover() -> void:
	hover_tile = Vector2i(-1, -1)
	hover_timer = 0.0
	if tooltip_view and tooltip_view.visible and not deployment_dock.is_active:
		tooltip_view.hide_tooltip()

func _update_gold_display() -> void:
	var current_gold = RunManager.gold if RunManager != null else 0
	gold_label.text = "OURO: %d" % current_gold

func _start_match_flow() -> void:
	is_starting_match = true
	is_game_over = false
	sudden_death_mgr.reset()
	game_over_modal.visible = false
	tooltip_view.hide_tooltip()
	_update_gold_display()

	var coin_center = board_offset + Vector2((board.cols * cell_size) / 2.0, (board.rows * cell_size) / 2.0)
	coin_flip_view.play_toss(coin_center, cell_size)

func _on_coin_flip_completed(player_won_white: bool) -> void:
	human_team = Board.WHITE if player_won_white else Board.BLACK
	ai_team = Board.BLACK if player_won_white else Board.WHITE

	board.setup_match(human_team, ai_team, match_inventory)

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

	deployment_dock.configure(match_inventory, board, human_team, cell_size, board_offset)
	deployment_dock.start_preparation()
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
		if event.keycode == KEY_I:
			toggle_inventory()
			return
		elif event.keycode == KEY_ESCAPE and inventory_ui and inventory_ui.visible:
			inventory_ui.visible = false
			if tooltip_view:
				tooltip_view.hide_tooltip()
			return

	if is_starting_match and coin_flip_view and coin_flip_view.is_animating:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			coin_flip_view.skip_spin()
			return

	if is_game_over or is_starting_match or (inventory_ui and inventory_ui.visible):
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var grid_pos = Vector2i((event.position - board_offset) / cell_size)
		if board.is_valid_pos(grid_pos.y, grid_pos.x):
			var piece: BoardPiece = board.grid[grid_pos.y][grid_pos.x]
			if piece != Board.EMPTY:
				tooltip_view.show_for_piece(piece.data, event.position, piece.owner_team)
				return

	if deployment_dock.is_active or is_ai_thinking or current_turn != human_team or (king_animation_view and king_animation_view.is_animating) or (frog_animation_view and frog_animation_view.is_attacking) or (piece_movement_view and piece_movement_view.is_animating):
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		tooltip_view.hide_tooltip()
		var grid_pos = Vector2i((event.position - board_offset) / cell_size)
		if board.is_valid_pos(grid_pos.y, grid_pos.x):
			handle_cell_click(grid_pos)

func handle_cell_click(pos: Vector2i) -> void:
	for m in valid_moves_for_selected:
		if m["to"] == pos:
			var from_pos: Vector2i = m["from"]
			var moving_piece: BoardPiece = board.grid[from_pos.y][from_pos.x]

			# 1. Animação de Salto da Peça
			moving_piece_tile = from_pos
			selected_tile = Vector2i(-1, -1)
			valid_moves_for_selected = []
			queue_redraw()

			var from_center = board_offset + Vector2(from_pos.x * cell_size + cell_size / 2.0, from_pos.y * cell_size + cell_size / 2.0)
			var to_center = board_offset + Vector2(pos.x * cell_size + cell_size / 2.0, pos.y * cell_size + cell_size / 2.0)

			await piece_movement_view.play_move_jump(from_center, to_center, moving_piece, cell_size, m["is_capture"])
			moving_piece_tile = Vector2i(-1, -1)

			# 2. Execução da Lógica no Tabuleiro
			if m["is_capture"]:
				var cap_pos = m["captured"]
				var captured_p: BoardPiece = board.grid[cap_pos.y][cap_pos.x]
				current_duel.on_piece_captured(captured_p)

			if current_duel is DuelBoss:
				frog_animation_view.hop_fly_at(m["from"])
				frog_animation_view.hop_fly_at(m["to"])

			var promoted = board.make_move(m)
			current_duel.on_turn_end(board)
			queue_redraw()

			if promoted:
				var piece: BoardPiece = board.grid[pos.y][pos.x]
				if piece != Board.EMPTY:
					var center = board_offset + Vector2(pos.x * cell_size + cell_size / 2.0, pos.y * cell_size + cell_size / 2.0)
					animating_coronation_tile = pos
					queue_redraw()
					await king_animation_view.play_coronation(center, cell_size, piece.data, piece.owner_team)
					animating_coronation_tile = Vector2i(-1, -1)
					queue_redraw()

			await _process_boss_turn_events()
			end_turn()
			return

	var piece: BoardPiece = board.grid[pos.y][pos.x]
	if piece != Board.EMPTY and piece.owner_team == human_team:
		selected_tile = pos
		valid_moves_for_selected = board.get_all_valid_moves(human_team).filter(func(m): return m["from"] == pos)
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
	await get_tree().create_timer(0.3).timeout
	await get_tree().process_frame

	var search_depth = 3 if max(board.rows, board.cols) >= 10 else 4
	var ai_move = CheckersAI.get_best_move(board, search_depth, ai_team)
	if ai_move.size() > 0:
		var from_pos = ai_move["from"]
		var target_pos = ai_move["to"]
		var moving_piece: BoardPiece = board.grid[from_pos.y][from_pos.x]

		moving_piece_tile = from_pos
		queue_redraw()

		var from_center = board_offset + Vector2(from_pos.x * cell_size + cell_size / 2.0, from_pos.y * cell_size + cell_size / 2.0)
		var to_center = board_offset + Vector2(target_pos.x * cell_size + cell_size / 2.0, target_pos.y * cell_size + cell_size / 2.0)

		await piece_movement_view.play_move_jump(from_center, to_center, moving_piece, cell_size, ai_move.get("is_capture", false))
		moving_piece_tile = Vector2i(-1, -1)

		if ai_move.get("is_capture", false):
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
				await king_animation_view.play_coronation(center, cell_size, piece.data, piece.owner_team)
				animating_coronation_tile = Vector2i(-1, -1)
				queue_redraw()

	await _process_boss_turn_events()

	is_ai_thinking = false

	if not _check_game_over():
		current_turn = human_team
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

	current_turn = ai_team if current_turn == human_team else human_team
	queue_redraw()
	if current_turn == ai_team:
		play_ai_turn()

func _trigger_game_over(won: bool, rewards: Dictionary = {}, custom_title: String = "") -> void:
	is_game_over = true
	selected_tile = Vector2i(-1, -1)
	valid_moves_for_selected = []
	if tooltip_view:
		tooltip_view.hide_tooltip()
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
	if RunManager != null and RunManager.inventory != null:
		for p in RunManager.inventory.get_all_pieces():
			p.is_king = false

	if not won and RunManager != null:
		RunManager.start_new_run()

	get_tree().call_deferred("change_scene_to_file", MAP_SCENE_PATH)

func toggle_inventory() -> void:
	if inventory_ui:
		inventory_ui.visible = not inventory_ui.visible
		if tooltip_view:
			tooltip_view.hide_tooltip()
		if inventory_ui.visible:
			inventory_ui.refresh_ui()

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

			if deployment_dock and deployment_dock.is_active and board.is_player_deployment_tile(r, c):
				var has_selected = (deployment_dock.selected_dock_piece != null)
				var zone_color = Color(0.2, 0.8, 1.0, 0.28 if has_selected else 0.14)
				draw_rect(rect, zone_color)
				PixelRenderer.draw_pixel_corners(self, rect, Color(0.3, 0.9, 1.0, 0.9 if has_selected else 0.5), 6.0, 2.0)

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

	for r in range(board.rows):
		for c in range(board.cols):
			var pos = Vector2i(c, r)
			var piece_obj: BoardPiece = board.grid[r][c]

			if deployment_dock and deployment_dock.is_dragging and deployment_dock.drag_from_board_pos == pos:
				continue

			if pos == animating_coronation_tile or pos == moving_piece_tile:
				continue

			if piece_obj != Board.EMPTY:
				var center = board_offset + Vector2(c * cell_size + cell_size / 2.0, r * cell_size + cell_size / 2.0)
				var scale_factor = piece_spawn_scales.get(pos, 1.0)
				var piece_rect = Rect2(board_offset.x + c * cell_size, board_offset.y + r * cell_size, cell_size, cell_size)

				if piece_obj.data != null and piece_obj.data.id == "commander":
					PixelRenderer.draw_commander_pixel_aura(self, center, cell_size * 0.38, selection_pulse)

				PixelRenderer.draw_piece(self, piece_obj, center, cell_size, scale_factor)

				if piece_obj.data and piece_obj.data.freeze_turns > 0:
					PixelRenderer.draw_pixel_corners(self, piece_rect, Color(0.4, 0.9, 0.6, 0.8), 7.0, 2.0)

# ==========================================
# FUNÇÃO DE DEBUG
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

	return false
