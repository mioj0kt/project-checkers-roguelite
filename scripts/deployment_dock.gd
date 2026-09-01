class_name DeploymentDock
extends Control

signal battle_started()
signal board_modified()

var inventory: InventoryManager
var board: Board
var human_team: int = Board.WHITE
var cell_size: float = 64.0
var board_offset: Vector2 = Vector2.ZERO

var panel: PanelContainer
var pieces_container: HBoxContainer
var ready_btn: Button

var is_active: bool = false
var is_dragging: bool = false
var dragged_piece_data: PieceData = null
var drag_from_board_pos: Vector2i = Vector2i(-1, -1)
var drag_current_mouse_pos: Vector2 = Vector2.ZERO

var pending_dock_piece: PieceData = null
var dock_press_start_pos: Vector2 = Vector2.ZERO
var selected_dock_piece: PieceData = null
const DRAG_THRESHOLD: float = 8.0

signal piece_inspect_requested(piece_data: PieceData, screen_pos: Vector2)
signal piece_inspect_dismissed()

func _ready() -> void:
	visible = false
	_build_ui()
	_update_layout()
	get_tree().root.size_changed.connect(_update_layout)

func configure(p_inventory: InventoryManager, p_board: Board, p_human_team: int, p_cell_size: float, p_board_offset: Vector2) -> void:
	inventory = p_inventory
	board = p_board
	human_team = p_human_team
	cell_size = p_cell_size
	board_offset = p_board_offset

func start_preparation() -> void:
	is_active = true
	visible = true
	is_dragging = false
	dragged_piece_data = null
	selected_dock_piece = null
	pending_dock_piece = null
	refresh_dock()
	queue_redraw()

func finish_preparation() -> void:
	is_active = false
	visible = false
	selected_dock_piece = null
	pending_dock_piece = null
	is_dragging = false
	dragged_piece_data = null
	queue_redraw()
	battle_started.emit()

func _update_layout() -> void:
	var vp_size = get_viewport_rect().size
	size = Vector2(vp_size.x, 140)
	position = Vector2(0, vp_size.y - 140)
	if panel:
		panel.custom_minimum_size = Vector2(clamp(vp_size.x * 0.88, 620, 960), 125)
		panel.position = Vector2((vp_size.x - panel.custom_minimum_size.x) / 2.0, 6)

func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", PixelUI.make_pixel_panel(Color(0.09, 0.1, 0.14, 0.98), Color(0.3, 0.65, 1.0), 12))
	add_child(panel)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(hbox)

	var title_box = VBoxContainer.new()
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(title_box)

	var lbl = Label.new()
	lbl.text = "PREPARACAO"
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	title_box.add_child(lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "Clique ou arraste"
	sub_lbl.add_theme_font_size_override("font_size", 20)
	sub_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	title_box.add_child(sub_lbl)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hbox.add_child(scroll)

	pieces_container = HBoxContainer.new()
	pieces_container.add_theme_constant_override("separation", 12)
	scroll.add_child(pieces_container)

	ready_btn = Button.new()
	ready_btn.text = "INICIAR BATALHA"
	ready_btn.custom_minimum_size = Vector2(190, 56)
	ready_btn.add_theme_font_size_override("font_size", 24)
	ready_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ready_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.12, 0.22, 0.35), Color(0.3, 0.8, 1.0)))
	ready_btn.add_theme_stylebox_override("hover", PixelUI.make_bevel_card(Color(0.16, 0.3, 0.48), Color(0.5, 0.9, 1.0)))
	ready_btn.add_theme_stylebox_override("pressed", PixelUI.make_bevel_card(Color(0.08, 0.16, 0.25), Color(0.2, 0.6, 0.8), true))
	ready_btn.pressed.connect(finish_preparation)
	hbox.add_child(ready_btn)

func refresh_dock() -> void:
	if not pieces_container:
		return

	for child in pieces_container.get_children():
		child.queue_free()

	var pieces = inventory.get_all_pieces() if inventory != null else []
	var grouped: Dictionary = {}
	for p in pieces:
		var p_id = p.id
		if not grouped.has(p_id):
			grouped[p_id] = {"data": p, "count": 0}
		grouped[p_id]["count"] += 1

	if grouped.is_empty():
		selected_dock_piece = null
		var empty_lbl = Label.new()
		empty_lbl.text = "Todas as suas pecas ja estao em campo!"
		empty_lbl.add_theme_font_size_override("font_size", 20)
		empty_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
		empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pieces_container.add_child(empty_lbl)
		return

	# Ordena por raridade decrescente
	var sorted_groups: Array = grouped.values()
	sorted_groups.sort_custom(func(a, b):
		var piece_a: PieceData = a["data"]
		var piece_b: PieceData = b["data"]
		if piece_a.rarity != piece_b.rarity:
			return piece_a.rarity > piece_b.rarity
		return piece_a.name < piece_b.name
	)

	for group in sorted_groups:
		var p_id = group["data"].id
		var is_selected = (selected_dock_piece != null and selected_dock_piece.id == p_id)
		var card = _create_dock_card(group["data"], group["count"], is_selected)
		pieces_container.add_child(card)

func _create_dock_card(piece: PieceData, count: int, is_selected: bool) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(94, 110)

	var r_color = piece.get_rarity_color()
	var border = Color(0.3, 0.95, 1.0) if is_selected else r_color
	var bg = Color(0.2, 0.24, 0.32, 0.98) if is_selected else Color(0.14, 0.15, 0.21, 0.96)
	
	card.add_theme_stylebox_override("panel", PixelUI.make_bevel_card(bg, border, is_selected))

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 3)
	card.add_child(vbox)

	# Exibe o sprite correspondente ao time do jogador (human_team)
	var tex = PixelRenderer.get_piece_texture(piece, human_team)
	if tex != null:
		var preview = TextureRect.new()
		preview.custom_minimum_size = Vector2(40, 40)
		preview.texture = tex
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		vbox.add_child(preview)
	else:
		var fallback = Panel.new()
		fallback.custom_minimum_size = Vector2(40, 40)
		var fb_style = StyleBoxFlat.new()
		fb_style.bg_color = piece.get_display_color()
		fb_style.border_color = Color.BLACK
		fb_style.set_border_width_all(2)
		fallback.add_theme_stylebox_override("panel", fb_style)
		
		var fb_lbl = Label.new()
		fb_lbl.text = piece.name.left(1).to_upper()
		fb_lbl.size = Vector2(40, 40)
		fb_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fb_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fb_lbl.add_theme_font_size_override("font_size", 22)
		fallback.add_child(fb_lbl)
		vbox.add_child(fallback)

	var name_lbl = Label.new()
	name_lbl.text = piece.name if "name" in piece and piece.name != "" else piece.id.capitalize()
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", piece.get_display_color())
	vbox.add_child(name_lbl)

	var count_lbl = Label.new()
	count_lbl.text = "x%d" % count
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.add_theme_font_size_override("font_size", 20)
	count_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(count_lbl)

	card.mouse_entered.connect(func(): piece_inspect_requested.emit(piece, card.get_global_mouse_position()))
	card.mouse_exited.connect(func(): piece_inspect_dismissed.emit())

	card.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton:
			if ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
				pending_dock_piece = piece
				dock_press_start_pos = ev.global_position
			elif ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
				piece_inspect_requested.emit(piece, ev.global_position)
	)

	return card

func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventMouseMotion:
		if pending_dock_piece != null and not is_dragging:
			if event.position.distance_to(dock_press_start_pos) > DRAG_THRESHOLD:
				var removed = inventory.remove_piece_by_id(pending_dock_piece.id)
				if removed != null:
					is_dragging = true
					dragged_piece_data = removed
					drag_from_board_pos = Vector2i(-1, -1)
					drag_current_mouse_pos = event.position
					selected_dock_piece = null
					pending_dock_piece = null
					refresh_dock()
					board_modified.emit()

		if is_dragging:
			drag_current_mouse_pos = event.position
			queue_redraw()
			return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_handle_board_press(event.position)
		else:
			if pending_dock_piece != null and not is_dragging:
				_toggle_dock_selection(pending_dock_piece)
				pending_dock_piece = null

			if is_dragging:
				_handle_board_drop(event.position)

func _toggle_dock_selection(piece: PieceData) -> void:
	if selected_dock_piece and selected_dock_piece.id == piece.id:
		selected_dock_piece = null
	else:
		selected_dock_piece = piece
	refresh_dock()
	board_modified.emit()

func _handle_board_press(screen_pos: Vector2) -> void:
	var grid_pos = Vector2i((screen_pos - board_offset) / cell_size)
	if not board.is_player_deployment_tile(grid_pos.y, grid_pos.x):
		return

	if selected_dock_piece != null:
		var removed = inventory.remove_piece_by_id(selected_dock_piece.id)
		if removed != null:
			var target_piece: BoardPiece = board.grid[grid_pos.y][grid_pos.x]
			if target_piece != Board.EMPTY:
				inventory.add_piece_to_inventory(target_piece.data)
			board.grid[grid_pos.y][grid_pos.x] = BoardPiece.new(human_team, removed)

			if inventory.get_piece_count_by_id(selected_dock_piece.id) == 0:
				selected_dock_piece = null

			refresh_dock()
			board_modified.emit()
		return

	var piece: BoardPiece = board.grid[grid_pos.y][grid_pos.x]
	if piece != Board.EMPTY and piece.owner_team == human_team:
		is_dragging = true
		dragged_piece_data = piece.data
		drag_from_board_pos = grid_pos
		drag_current_mouse_pos = screen_pos
		board_modified.emit()
		queue_redraw()

func _handle_board_drop(screen_pos: Vector2) -> void:
	if not is_dragging:
		return

	var target_grid = Vector2i((screen_pos - board_offset) / cell_size)

	if board.is_player_deployment_tile(target_grid.y, target_grid.x):
		var target_piece: BoardPiece = board.grid[target_grid.y][target_grid.x]

		if drag_from_board_pos != Vector2i(-1, -1):
			var source_piece: BoardPiece = board.grid[drag_from_board_pos.y][drag_from_board_pos.x]
			board.grid[drag_from_board_pos.y][drag_from_board_pos.x] = target_piece
			board.grid[target_grid.y][target_grid.x] = source_piece
		else:
			if target_piece != Board.EMPTY:
				inventory.add_piece_to_inventory(target_piece.data)
			board.grid[target_grid.y][target_grid.x] = BoardPiece.new(human_team, dragged_piece_data)
	else:
		if drag_from_board_pos != Vector2i(-1, -1):
			var pieces_on_board = 0
			for r in range(board.rows):
				for c in range(board.cols):
					var p: BoardPiece = board.grid[r][c]
					if p != Board.EMPTY and p.owner_team == human_team:
						pieces_on_board += 1

			if pieces_on_board > 1:
				inventory.add_piece_to_inventory(dragged_piece_data)
				board.grid[drag_from_board_pos.y][drag_from_board_pos.x] = Board.EMPTY
		else:
			inventory.add_piece_to_inventory(dragged_piece_data)

	is_dragging = false
	dragged_piece_data = null
	drag_from_board_pos = Vector2i(-1, -1)

	refresh_dock()
	board_modified.emit()
	queue_redraw()

func _draw() -> void:
	if is_dragging and dragged_piece_data != null:
		var local_mouse = get_local_mouse_position()
		var dummy_piece = BoardPiece.new(human_team, dragged_piece_data)
		PixelRenderer.draw_piece(self, dummy_piece, local_mouse, cell_size, 1.1)

		var preview_rect = Rect2(
			local_mouse.x - cell_size * 0.4,
			local_mouse.y - cell_size * 0.4,
			cell_size * 0.8,
			cell_size * 0.8
		)
		PixelRenderer.draw_pixel_corners(self, preview_rect, Color(0.3, 0.9, 1.0, 0.85), 6.0, 2.0)
