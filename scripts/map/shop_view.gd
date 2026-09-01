class_name ShopView
extends Control

const MAP_SCENE_PATH = "res://map_view.tscn"

var shop_mgr: ShopManager = ShopManager.new()

var gold_label: Label
var reroll_btn: Button
var pieces_container: HBoxContainer
var packs_container: HBoxContainer
var tooltip_view: PieceTooltip
var inventory_ui: InventoryUI

# Modal de Abertura de Pacotes (Booster Modal)
var pack_modal: PanelContainer
var pack_cards_container: HBoxContainer
var pack_modal_title: Label

var current_shop_pieces: Array[PieceData] = []
var current_packs: Array[Dictionary] = []

func _ready() -> void:
	# Força o Control raiz a preencher toda a janela
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size

	_build_ui()
	_update_layout()
	get_tree().root.size_changed.connect(_update_layout)

	shop_mgr.reset_reroll_cost()
	_refresh_shop_stock()
	_update_gold_display()

func _update_layout() -> void:
	var vp_size = get_viewport_rect().size
	size = vp_size

	if pack_modal and pack_modal.visible:
		pack_modal.custom_minimum_size = Vector2(clamp(vp_size.x * 0.75, 600, 780), 340)
		pack_modal.position = (vp_size - pack_modal.custom_minimum_size) / 2.0

func _build_ui() -> void:
	# Fundo da Loja (Preenche toda a tela)
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.09, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Container Centralizado com margens confortáveis
	var center_box = CenterContainer.new()
	center_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center_box)

	var main_vbox = VBoxContainer.new()
	main_vbox.custom_minimum_size = Vector2(920, 560)
	main_vbox.add_theme_constant_override("separation", 18)
	center_box.add_child(main_vbox)

	# --- TOP BAR (LOJA, OURO, MOCHILA, SAIR) ---
	var top_bar = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 20)
	main_vbox.add_child(top_bar)

	var shop_title = Label.new()
	shop_title.text = "MERCADO NEGRO"
	shop_title.add_theme_font_size_override("font_size", 36)
	shop_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	shop_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(shop_title)

	gold_label = Label.new()
	gold_label.add_theme_font_size_override("font_size", 28)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	top_bar.add_child(gold_label)

	var inv_btn = Button.new()
	inv_btn.text = "MOCHILA (I)"
	inv_btn.custom_minimum_size = Vector2(140, 44)
	inv_btn.add_theme_font_size_override("font_size", 20)
	inv_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.14, 0.18, 0.26), Color(0.3, 0.6, 1.0)))
	inv_btn.pressed.connect(func(): inventory_ui.toggle_visibility())
	top_bar.add_child(inv_btn)

	var leave_btn = Button.new()
	leave_btn.text = "IR PARA O MAPA ->"
	leave_btn.custom_minimum_size = Vector2(180, 44)
	leave_btn.add_theme_font_size_override("font_size", 20)
	leave_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.2, 0.12, 0.14), Color(0.85, 0.3, 0.35)))
	leave_btn.pressed.connect(_on_leave_shop)
	top_bar.add_child(leave_btn)

	# Linha divisória
	var top_div = ColorRect.new()
	top_div.custom_minimum_size = Vector2(0, 3)
	top_div.color = Color(0.25, 0.28, 0.38, 0.9)
	main_vbox.add_child(top_div)

	# --- CORPO DA LOJA ---
	var content_hbox = HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 24)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_hbox)

	# Coluna Esquerda: Vitrine de Peças e Pacotes
	var showcase_vbox = VBoxContainer.new()
	showcase_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	showcase_vbox.add_theme_constant_override("separation", 18)
	content_hbox.add_child(showcase_vbox)

	# Seção 1: Peças Avulsas
	var pieces_panel = PanelContainer.new()
	pieces_panel.add_theme_stylebox_override("panel", PixelUI.make_pixel_panel(Color(0.09, 0.1, 0.15, 0.95), Color(0.3, 0.5, 0.8), 16))
	showcase_vbox.add_child(pieces_panel)

	var pieces_vbox = VBoxContainer.new()
	pieces_vbox.add_theme_constant_override("separation", 12)
	pieces_panel.add_child(pieces_vbox)

	var pieces_lbl = Label.new()
	pieces_lbl.text = "PECAS DISPONIVEIS"
	pieces_lbl.add_theme_font_size_override("font_size", 24)
	pieces_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	pieces_vbox.add_child(pieces_lbl)

	pieces_container = HBoxContainer.new()
	pieces_container.add_theme_constant_override("separation", 16)
	pieces_vbox.add_child(pieces_container)

	# Seção 2: Pacotes Booster
	var packs_panel = PanelContainer.new()
	packs_panel.add_theme_stylebox_override("panel", PixelUI.make_pixel_panel(Color(0.1, 0.09, 0.14, 0.95), Color(0.7, 0.4, 0.9), 16))
	showcase_vbox.add_child(packs_panel)

	var packs_vbox = VBoxContainer.new()
	packs_vbox.add_theme_constant_override("separation", 12)
	packs_panel.add_child(packs_vbox)

	var packs_lbl = Label.new()
	packs_lbl.text = "PACOTES BOOSTER (ESCOLHA 1 DE 3)"
	packs_lbl.add_theme_font_size_override("font_size", 24)
	packs_lbl.add_theme_color_override("font_color", Color(0.85, 0.5, 1.0))
	packs_vbox.add_child(packs_lbl)

	packs_container = HBoxContainer.new()
	packs_container.add_theme_constant_override("separation", 16)
	packs_vbox.add_child(packs_container)

	# Coluna Direita: Painel de Reroll
	var actions_panel = PanelContainer.new()
	actions_panel.custom_minimum_size = Vector2(230, 0)
	actions_panel.add_theme_stylebox_override("panel", PixelUI.make_pixel_panel(Color(0.12, 0.11, 0.14, 0.98), Color(0.6, 0.55, 0.4), 16))
	content_hbox.add_child(actions_panel)

	var actions_vbox = VBoxContainer.new()
	actions_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	actions_vbox.add_theme_constant_override("separation", 16)
	actions_panel.add_child(actions_vbox)

	reroll_btn = Button.new()
	reroll_btn.custom_minimum_size = Vector2(190, 68)
	reroll_btn.add_theme_font_size_override("font_size", 22)
	reroll_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.2, 0.18, 0.1), Color(1.0, 0.85, 0.3)))
	reroll_btn.pressed.connect(_on_reroll_pressed)
	actions_vbox.add_child(reroll_btn)

	var reroll_desc = Label.new()
	reroll_desc.text = "Substitui todas as pecas por novas ofertas."
	reroll_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reroll_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reroll_desc.add_theme_font_size_override("font_size", 16)
	reroll_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	actions_vbox.add_child(reroll_desc)

	# --- MODAL DE ABERTURA DE PACOTE ---
	_build_pack_opening_modal()

	# Mochila e Tooltip
	inventory_ui = InventoryUI.new()
	inventory_ui.z_index = 50
	add_child(inventory_ui)
	if RunManager != null and RunManager.inventory != null:
		inventory_ui.setup(RunManager.inventory)

	tooltip_view = PieceTooltip.new()
	tooltip_view.z_index = 100
	add_child(tooltip_view)

	inventory_ui.piece_inspect_requested.connect(func(p, pos): tooltip_view.show_for_piece(p, pos))
	inventory_ui.piece_inspect_dismissed.connect(func(): tooltip_view.hide_tooltip())

func _build_pack_opening_modal() -> void:
	pack_modal = PanelContainer.new()
	pack_modal.visible = false
	pack_modal.z_index = 60
	pack_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	pack_modal.add_theme_stylebox_override("panel", PixelUI.make_pixel_panel(Color(0.08, 0.08, 0.12, 0.98), Color(0.9, 0.7, 0.2), 24))
	add_child(pack_modal)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	pack_modal.add_child(vbox)

	pack_modal_title = Label.new()
	pack_modal_title.text = "ABERTURA DE PACOTE - ESCOLHA 1 PECA"
	pack_modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pack_modal_title.add_theme_font_size_override("font_size", 28)
	pack_modal_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(pack_modal_title)

	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 3)
	divider.color = Color(0.3, 0.35, 0.45, 0.9)
	vbox.add_child(divider)

	pack_cards_container = HBoxContainer.new()
	pack_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	pack_cards_container.add_theme_constant_override("separation", 24)
	vbox.add_child(pack_cards_container)

func _update_gold_display() -> void:
	var g = RunManager.gold if RunManager != null else 0
	gold_label.text = "OURO: %d" % g
	reroll_btn.text = "REROLL\n(%d Ouro)" % shop_mgr.current_reroll_cost
	reroll_btn.disabled = (g < shop_mgr.current_reroll_cost)

func _refresh_shop_stock() -> void:
	current_shop_pieces.clear()
	for child in pieces_container.get_children():
		child.queue_free()

	for i in range(3):
		var piece = shop_mgr.generate_random_piece()
		current_shop_pieces.append(piece)
		var card = _create_piece_buy_card(piece)
		pieces_container.add_child(card)

	if current_packs.is_empty():
		current_packs = shop_mgr.generate_booster_packs()

	for child in packs_container.get_children():
		child.queue_free()

	for pack_data in current_packs:
		var pack_card = _create_pack_buy_card(pack_data)
		packs_container.add_child(pack_card)

	_update_gold_display()

func _create_piece_buy_card(piece: PieceData) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(140, 180)
	var price = shop_mgr.get_piece_price(piece)

	var r_color = piece.get_rarity_color()
	card.add_theme_stylebox_override("panel", PixelUI.make_bevel_card(Color(0.12, 0.14, 0.19, 0.96), r_color))

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	var tex = PixelRenderer.get_piece_texture(piece, Board.WHITE)
	if tex != null:
		var preview = TextureRect.new()
		preview.custom_minimum_size = Vector2(48, 48)
		preview.texture = tex
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		vbox.add_child(preview)

	var name_lbl = Label.new()
	name_lbl.text = piece.name if piece.name != "" else piece.id.capitalize()
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", piece.get_display_color())
	vbox.add_child(name_lbl)

	var rarity_lbl = Label.new()
	rarity_lbl.text = "[%s]" % piece.get_rarity_name().to_upper()
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_lbl.add_theme_font_size_override("font_size", 16)
	rarity_lbl.add_theme_color_override("font_color", r_color)
	vbox.add_child(rarity_lbl)

	var buy_btn = Button.new()
	buy_btn.text = "%d OURO" % price
	buy_btn.custom_minimum_size = Vector2(100, 36)
	buy_btn.add_theme_font_size_override("font_size", 18)
	buy_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.15, 0.25, 0.18), Color(0.4, 0.9, 0.45)))
	buy_btn.pressed.connect(func(): _buy_piece(piece, price, card))
	vbox.add_child(buy_btn)

	card.mouse_entered.connect(func(): tooltip_view.show_for_piece(piece, card.get_global_mouse_position()))
	card.mouse_exited.connect(func(): tooltip_view.hide_tooltip())

	return card

func _create_pack_buy_card(pack: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(170, 160)
	card.add_theme_stylebox_override("panel", PixelUI.make_bevel_card(Color(0.15, 0.12, 0.22, 0.96), Color(0.8, 0.45, 1.0)))

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	var name_lbl = Label.new()
	name_lbl.text = pack["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = pack["desc"]
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	vbox.add_child(desc_lbl)

	var buy_btn = Button.new()
	buy_btn.text = "%d OURO" % pack["price"]
	buy_btn.custom_minimum_size = Vector2(120, 36)
	buy_btn.add_theme_font_size_override("font_size", 18)
	buy_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.2, 0.15, 0.3), Color(0.8, 0.45, 1.0)))
	buy_btn.pressed.connect(func(): _buy_booster_pack(pack, card))
	vbox.add_child(buy_btn)

	return card

func _buy_piece(piece: PieceData, price: int, card_node: Control) -> void:
	if RunManager == null or not RunManager.spend_gold(price):
		return

	RunManager.inventory.add_piece_to_inventory(piece)
	current_shop_pieces.erase(piece)
	card_node.queue_free()
	tooltip_view.hide_tooltip()
	_update_gold_display()
	if inventory_ui.visible:
		inventory_ui.refresh_ui()

func _buy_booster_pack(pack: Dictionary, card_node: Control) -> void:
	if RunManager == null or not RunManager.spend_gold(pack["price"]):
		return

	current_packs.erase(pack)
	card_node.queue_free()
	_update_gold_display()
	_open_pack_modal(pack["min_rarity"])

func _open_pack_modal(min_rarity: PieceData.Rarity) -> void:
	for child in pack_cards_container.get_children():
		child.queue_free()

	var options: Array[PieceData] = []
	for i in range(3):
		options.append(shop_mgr.generate_random_piece(min_rarity))

	for piece in options:
		var card = _create_pack_choice_card(piece)
		pack_cards_container.add_child(card)

	var vp_size = get_viewport_rect().size
	pack_modal.custom_minimum_size = Vector2(clamp(vp_size.x * 0.75, 600, 780), 340)
	pack_modal.position = (vp_size - pack_modal.custom_minimum_size) / 2.0
	pack_modal.visible = true

func _create_pack_choice_card(piece: PieceData) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(150, 200)

	var r_color = piece.get_rarity_color()
	card.add_theme_stylebox_override("panel", PixelUI.make_bevel_card(Color(0.12, 0.14, 0.2, 0.98), r_color))

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	var tex = PixelRenderer.get_piece_texture(piece, Board.WHITE)
	if tex != null:
		var preview = TextureRect.new()
		preview.custom_minimum_size = Vector2(56, 56)
		preview.texture = tex
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		vbox.add_child(preview)

	var name_lbl = Label.new()
	name_lbl.text = piece.name if piece.name != "" else piece.id.capitalize()
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", piece.get_display_color())
	vbox.add_child(name_lbl)

	var rarity_lbl = Label.new()
	rarity_lbl.text = "[%s]" % piece.get_rarity_name().to_upper()
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_lbl.add_theme_font_size_override("font_size", 18)
	rarity_lbl.add_theme_color_override("font_color", r_color)
	vbox.add_child(rarity_lbl)

	var choose_btn = Button.new()
	choose_btn.text = "ESCOLHER"
	choose_btn.custom_minimum_size = Vector2(110, 40)
	choose_btn.add_theme_font_size_override("font_size", 18)
	choose_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.15, 0.3, 0.2), Color(0.3, 0.9, 0.5)))
	choose_btn.pressed.connect(func(): _choose_pack_piece(piece))
	vbox.add_child(choose_btn)

	card.mouse_entered.connect(func(): tooltip_view.show_for_piece(piece, card.get_global_mouse_position()))
	card.mouse_exited.connect(func(): tooltip_view.hide_tooltip())

	return card

func _choose_pack_piece(piece: PieceData) -> void:
	if RunManager != null and RunManager.inventory != null:
		RunManager.inventory.add_piece_to_inventory(piece)

	pack_modal.visible = false
	tooltip_view.hide_tooltip()
	if inventory_ui.visible:
		inventory_ui.refresh_ui()

func _on_reroll_pressed() -> void:
	if RunManager == null or not RunManager.spend_gold(shop_mgr.current_reroll_cost):
		return

	shop_mgr.increase_reroll_cost()
	_refresh_shop_stock()

func _on_leave_shop() -> void:
	get_tree().change_scene_to_file(MAP_SCENE_PATH)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			inventory_ui.toggle_visibility()
		elif event.keycode == KEY_ESCAPE:
			if pack_modal.visible:
				pass
			elif inventory_ui.visible:
				inventory_ui.visible = false
				tooltip_view.hide_tooltip()
