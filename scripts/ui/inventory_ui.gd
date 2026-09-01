class_name InventoryUI
extends Control

signal piece_inspect_requested(piece_data: PieceData, screen_pos: Vector2)
signal piece_inspect_dismissed()

var inventory: InventoryManager
var panel: PanelContainer
var grid_container: GridContainer
var empty_label: Label

func _ready() -> void:
	visible = false
	z_index = 50
	if not panel:
		_build_ui()
	_update_layout()
	get_tree().root.size_changed.connect(_update_layout)

func setup(p_inventory: InventoryManager) -> void:
	inventory = p_inventory
	if not panel:
		_build_ui()
	refresh_ui()

func toggle_visibility() -> void:
	visible = not visible
	if visible:
		# Sempre que abrir, traz para a frente e atualiza a lista
		move_to_front()
		refresh_ui()
	else:
		piece_inspect_dismissed.emit()

func _update_layout() -> void:
	var vp_size = get_viewport_rect().size
	size = vp_size
	if panel:
		panel.custom_minimum_size = Vector2(clamp(vp_size.x * 0.85, 560, 840), clamp(vp_size.y * 0.8, 420, 640))
		panel.position = (vp_size - panel.custom_minimum_size) / 2.0

func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg = ColorRect.new()
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.color = Color(0, 0, 0, 0.75)
	bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bg.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			visible = false
			piece_inspect_dismissed.emit()
	)
	add_child(bg)

	panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", PixelUI.make_pixel_panel(Color(0.1, 0.11, 0.16, 0.98), Color(0.3, 0.6, 1.0), 20))
	add_child(panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.mouse_filter = Control.MOUSE_FILTER_STOP
	main_vbox.add_theme_constant_override("separation", 14)
	panel.add_child(main_vbox)

	var top_bar = HBoxContainer.new()
	top_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	main_vbox.add_child(top_bar)

	var title_lbl = Label.new()
	title_lbl.text = "MOCHILA DE PECAS"
	title_lbl.add_theme_font_size_override("font_size", 32)
	title_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title_lbl)

	var close_btn = Button.new()
	close_btn.text = " X "
	close_btn.custom_minimum_size = Vector2(42, 42)
	close_btn.add_theme_font_size_override("font_size", 26)
	close_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.2, 0.1, 0.12), Color(0.8, 0.25, 0.25)))
	close_btn.pressed.connect(func(): visible = false; piece_inspect_dismissed.emit())
	top_bar.add_child(close_btn)

	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 3)
	divider.color = Color(0.25, 0.28, 0.38, 0.9)
	main_vbox.add_child(divider)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)

	var content_box = VBoxContainer.new()
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(content_box)

	empty_label = Label.new()
	empty_label.text = "Nenhuma peca sobressalente no inventario!\n(Todas as suas pecas podem estar posicionadas no tabuleiro)"
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.add_theme_font_size_override("font_size", 22)
	empty_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	empty_label.visible = false
	empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_box.add_child(empty_label)

	grid_container = GridContainer.new()
	grid_container.columns = 5
	grid_container.add_theme_constant_override("h_separation", 16)
	grid_container.add_theme_constant_override("v_separation", 16)
	content_box.add_child(grid_container)

func refresh_ui() -> void:
	if not grid_container:
		return

	for child in grid_container.get_children():
		child.queue_free()

	if inventory == null and ResourceLoader.exists("res://scripts/run_manager.gd"):
		inventory = RunManager.inventory

	var pieces = inventory.get_all_pieces() if inventory != null else []
	
	if pieces.is_empty():
		empty_label.visible = true
		grid_container.visible = false
		return

	empty_label.visible = false
	grid_container.visible = true

	# 1. Agrupa as peças por id
	var grouped: Dictionary = {}
	for p in pieces:
		if p == null:
			continue
		var p_id = p.id
		if not grouped.has(p_id):
			grouped[p_id] = {"data": p, "count": 0}
		grouped[p_id]["count"] += 1

	# 2. Converte para array e ordena pela Raridade (Decrescente: Lendária -> Rara -> Incomum -> Comum)
	var sorted_groups: Array = grouped.values()
	sorted_groups.sort_custom(func(a, b):
		var piece_a: PieceData = a["data"]
		var piece_b: PieceData = b["data"]
		
		# Se a raridade for diferente, ordena da maior para a menor
		if piece_a.rarity != piece_b.rarity:
			return piece_a.rarity > piece_b.rarity
		
		# Se for a mesma raridade, desempata alfabeticamente pelo nome
		return piece_a.name < piece_b.name
	)

	# 3. Cria os cards já na ordem correta
	for group in sorted_groups:
		var card = _create_piece_card(group["data"], group["count"])
		grid_container.add_child(card)

func _create_piece_card(piece: PieceData, count: int) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(120, 140)

	var r_color = piece.get_rarity_color()
	card.add_theme_stylebox_override("panel", PixelUI.make_bevel_card(Color(0.14, 0.15, 0.21, 0.96), r_color))

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	var tex = PixelRenderer.get_piece_texture(piece, Board.WHITE)
	if tex != null:
		var preview = TextureRect.new()
		preview.custom_minimum_size = Vector2(52, 52)
		preview.texture = tex
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		vbox.add_child(preview)
	else:
		var fallback = Panel.new()
		fallback.custom_minimum_size = Vector2(52, 52)
		var fb_style = StyleBoxFlat.new()
		fb_style.bg_color = piece.get_display_color()
		fb_style.border_color = Color.BLACK
		fb_style.set_border_width_all(3)
		fallback.add_theme_stylebox_override("panel", fb_style)
		
		var fb_lbl = Label.new()
		fb_lbl.text = piece.name.left(1).to_upper()
		fb_lbl.size = Vector2(52, 52)
		fb_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fb_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fb_lbl.add_theme_font_size_override("font_size", 28)
		fallback.add_child(fb_lbl)
		vbox.add_child(fallback)

	var name_lbl = Label.new()
	name_lbl.text = piece.name if piece.name != "" else piece.id.capitalize()
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", piece.get_display_color())
	vbox.add_child(name_lbl)

	var count_lbl = Label.new()
	count_lbl.text = "x%d" % count
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.add_theme_font_size_override("font_size", 22)
	count_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(count_lbl)

	card.mouse_entered.connect(func(): piece_inspect_requested.emit(piece, card.get_global_mouse_position()))
	card.mouse_exited.connect(func(): piece_inspect_dismissed.emit())

	card.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
			piece_inspect_requested.emit(piece, ev.global_position)
	)

	return card
