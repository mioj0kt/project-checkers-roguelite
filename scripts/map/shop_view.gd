class_name ShopView
extends Control

const MAP_SCENE_PATH = "res://map_view.tscn"

var hud_bar: HUDBar
var inventory_ui: InventoryUI
var rule_tooltip: RuleCardTooltip
var card_tooltip: ActionCardTooltip

var laws_for_sale: Array[RuleCard] = []
var cards_for_sale: Array[ActionCard] = []

var laws_container: HBoxContainer
var cards_container: HBoxContainer
var reroll_btn: Button
var remove_card_btn: Button

var card_reroll_cost: int = 2
var remove_card_cost: int = 3

# Modal de Remoção de Carta
var remove_modal_layer: CanvasLayer
var remove_grid: HBoxContainer

func _ready() -> void:
	_generate_laws_stock()
	_reroll_cards_stock()
	_setup_ui()

func _generate_laws_stock() -> void:
	laws_for_sale.clear()
	var owned_rule_ids: Array[String] = []
	if RunManager != null:
		for r in RunManager.active_rules:
			owned_rule_ids.append(r.id)

	laws_for_sale = LootTables.get_random_rules(3, owned_rule_ids)

func _reroll_cards_stock() -> void:
	cards_for_sale = LootTables.get_random_action_cards(3)

func _setup_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "ShopUILayer"
	canvas.layer = 70
	add_child(canvas)

	# Tooltips dedicados
	rule_tooltip = RuleCardTooltip.new()
	add_child(rule_tooltip)

	card_tooltip = ActionCardTooltip.new()
	add_child(card_tooltip)

	hud_bar = HUDBar.new()
	canvas.add_child(hud_bar)
	hud_bar.open_laws_requested.connect(_toggle_inventory)

	inventory_ui = InventoryUI.new()
	canvas.add_child(inventory_ui)
	inventory_ui.setup()

	# Container principal com Centralização Absoluta
	var center_box = VBoxContainer.new()
	center_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_box.offset_left = 60.0
	center_box.offset_right = -60.0
	center_box.offset_top = 26.0
	center_box.offset_bottom = -20.0
	center_box.add_theme_constant_override("separation", 16)
	center_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	canvas.add_child(center_box)

	# Cabeçalho Principal
	var header = Label.new()
	header.text = "MERCADO DO TABULEIRO"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 42)
	header.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	header.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 1.0))
	header.add_theme_constant_override("outline_size", 10)
	center_box.add_child(header)

	# -------------------------------------------------------------
	# SEÇÃO 1: LEIS PERMANENTES
	# -------------------------------------------------------------
	var laws_title = Label.new()
	laws_title.text = "― LEIS PERMANENTES ―"
	laws_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	laws_title.add_theme_font_size_override("font_size", 24)
	laws_title.add_theme_color_override("font_color", Color(0.5, 0.82, 1.0))
	center_box.add_child(laws_title)

	laws_container = HBoxContainer.new()
	laws_container.alignment = BoxContainer.ALIGNMENT_CENTER
	laws_container.add_theme_constant_override("separation", 36)
	center_box.add_child(laws_container)
	_render_laws_stock()

	# -------------------------------------------------------------
	# SEÇÃO 2: CARTAS TÁTICAS + BOTÕES REROLL E REMOVER
	# -------------------------------------------------------------
	var cards_header_hbox = HBoxContainer.new()
	cards_header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_header_hbox.add_theme_constant_override("separation", 24)
	center_box.add_child(cards_header_hbox)

	var cards_title = Label.new()
	cards_title.text = "― CARTAS DE AÇÃO (DECK) ―"
	cards_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cards_title.add_theme_font_size_override("font_size", 24)
	cards_title.add_theme_color_override("font_color", Color(1.0, 0.65, 0.35))
	cards_header_hbox.add_child(cards_title)

	reroll_btn = Button.new()
	reroll_btn.custom_minimum_size = Vector2(190, 40)
	reroll_btn.add_theme_font_size_override("font_size", 18)
	reroll_btn.pressed.connect(_on_reroll_cards_pressed)
	cards_header_hbox.add_child(reroll_btn)

	remove_card_btn = Button.new()
	remove_card_btn.custom_minimum_size = Vector2(230, 40)
	remove_card_btn.add_theme_font_size_override("font_size", 18)
	remove_card_btn.pressed.connect(_on_remove_card_clicked)
	cards_header_hbox.add_child(remove_card_btn)

	_update_header_buttons_state()

	cards_container = HBoxContainer.new()
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 32)
	center_box.add_child(cards_container)
	_render_cards_stock()

	# Rodapé: Botão de saída
	var footer_box = HBoxContainer.new()
	footer_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center_box.add_child(footer_box)

	var leave_btn = Button.new()
	leave_btn.text = "CONTINUAR VIAGEM"
	leave_btn.custom_minimum_size = Vector2(280, 52)
	leave_btn.add_theme_font_size_override("font_size", 22)
	leave_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.12, 0.16, 0.22), Color(0.4, 0.7, 0.9)))
	leave_btn.add_theme_stylebox_override("hover", PixelUI.make_bevel_card(Color(0.18, 0.24, 0.34), Color(0.6, 0.9, 1.0)))
	leave_btn.pressed.connect(_on_leave_pressed)
	footer_box.add_child(leave_btn)

	_build_remove_modal_ui()

func _render_laws_stock() -> void:
	for child in laws_container.get_children():
		child.queue_free()

	for i in range(laws_for_sale.size()):
		var law = laws_for_sale[i]
		var law_widget = _create_law_item_ui(law, i)
		laws_container.add_child(law_widget)

func _create_law_item_ui(law: RuleCard, index: int) -> Control:
	var wrapper = VBoxContainer.new()
	wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
	wrapper.add_theme_constant_override("separation", 8)

	var card_visual = RuleCardVisual.new(law, rule_tooltip, false)
	wrapper.add_child(card_visual)

	var current_gold = RunManager.gold if RunManager != null else 0
	var can_afford = current_gold >= law.cost
	var has_room = RunManager != null and RunManager.active_rules.size() < 6

	var buy_btn = Button.new()
	buy_btn.custom_minimum_size = Vector2(RuleCardVisual.CARD_SIZE, 42)
	buy_btn.text = "%d OURO" % law.cost if has_room else "LOTADO (6/6)"
	buy_btn.disabled = (not can_afford) or (not has_room)
	buy_btn.add_theme_font_size_override("font_size", 18)

	if can_afford and has_room:
		buy_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.12, 0.22, 0.16), Color(0.3, 0.9, 0.4)))
		buy_btn.add_theme_stylebox_override("hover", PixelUI.make_bevel_card(Color(0.18, 0.30, 0.22), Color(0.5, 1.0, 0.6)))
		buy_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.5))
	else:
		buy_btn.add_theme_stylebox_override("disabled", PixelUI.make_bevel_card(Color(0.1, 0.1, 0.12), Color(0.3, 0.3, 0.35)))
		buy_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))

	buy_btn.pressed.connect(_on_buy_law_pressed.bind(index))
	wrapper.add_child(buy_btn)

	card_visual.play_flip_reveal(0.1 + (index * 0.12))
	return wrapper

func _render_cards_stock() -> void:
	for child in cards_container.get_children():
		child.queue_free()

	for i in range(cards_for_sale.size()):
		var card = cards_for_sale[i]
		var card_widget = _create_action_card_shop_item_ui(card, i)
		cards_container.add_child(card_widget)

func _create_action_card_shop_item_ui(card: ActionCard, index: int) -> Control:
	var wrapper = VBoxContainer.new()
	wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
	wrapper.add_theme_constant_override("separation", 8)

	# Card visual com tamanho vertical proporcional (150x220)
	var card_visual = ActionCardVisual.new(card, true)
	card_visual.mouse_filter = Control.MOUSE_FILTER_STOP
	wrapper.add_child(card_visual)

	# Hover conectado ao ActionCardTooltip
	card_visual.mouse_entered.connect(func():
		if card_tooltip:
			var tip_pos = card_visual.global_position + Vector2(ActionCardVisual.CARD_WIDTH / 2.0, 0.0)
			card_tooltip.show_tooltip(card, tip_pos)
	)
	card_visual.mouse_exited.connect(func():
		if card_tooltip:
			card_tooltip.hide_tooltip()
	)

	var current_gold = RunManager.gold if RunManager != null else 0
	var can_afford = current_gold >= card.cost_gold

	var buy_btn = Button.new()
	buy_btn.custom_minimum_size = Vector2(ActionCardVisual.CARD_WIDTH, 42)
	buy_btn.text = "%d OURO" % card.cost_gold
	buy_btn.disabled = not can_afford
	buy_btn.add_theme_font_size_override("font_size", 18)

	if can_afford:
		buy_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.12, 0.22, 0.16), Color(0.3, 0.9, 0.4)))
		buy_btn.add_theme_stylebox_override("hover", PixelUI.make_bevel_card(Color(0.18, 0.3, 0.22), Color(0.5, 1.0, 0.6)))
		buy_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.5))
	else:
		buy_btn.add_theme_stylebox_override("disabled", PixelUI.make_bevel_card(Color(0.1, 0.1, 0.12), Color(0.3, 0.3, 0.35)))
		buy_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))

	buy_btn.pressed.connect(_on_buy_action_card_pressed.bind(index))
	wrapper.add_child(buy_btn)

	card_visual.play_flip_reveal(0.1 + (index * 0.12))
	return wrapper

func _update_header_buttons_state() -> void:
	var current_gold = RunManager.gold if RunManager != null else 0

	# 1. Reroll
	if reroll_btn != null:
		var can_reroll = current_gold >= card_reroll_cost
		reroll_btn.text = "REROLL: %d OURO" % card_reroll_cost
		reroll_btn.disabled = not can_reroll
		if can_reroll:
			reroll_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.2, 0.14, 0.08), Color(1.0, 0.65, 0.2)))
			reroll_btn.add_theme_stylebox_override("hover", PixelUI.make_bevel_card(Color(0.28, 0.18, 0.1), Color(1.0, 0.8, 0.35)))
			reroll_btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4))
		else:
			reroll_btn.add_theme_stylebox_override("disabled", PixelUI.make_bevel_card(Color(0.1, 0.1, 0.12), Color(0.3, 0.3, 0.35)))
			reroll_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))

	# 2. Remover Carta
	if remove_card_btn != null:
		var has_cards = RunManager != null and not RunManager.player_deck.is_empty()
		var can_remove = current_gold >= remove_card_cost and has_cards
		remove_card_btn.text = "REMOVER: %d OURO" % remove_card_cost
		remove_card_btn.disabled = not can_remove
		if can_remove:
			remove_card_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.22, 0.08, 0.10), Color(0.95, 0.3, 0.35)))
			remove_card_btn.add_theme_stylebox_override("hover", PixelUI.make_bevel_card(Color(0.32, 0.12, 0.15), Color(1.0, 0.45, 0.5)))
			remove_card_btn.add_theme_color_override("font_color", Color(1.0, 0.8, 0.8))
		else:
			remove_card_btn.add_theme_stylebox_override("disabled", PixelUI.make_bevel_card(Color(0.1, 0.1, 0.12), Color(0.3, 0.3, 0.35)))
			remove_card_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))

func _on_reroll_cards_pressed() -> void:
	if RunManager != null and RunManager.gold >= card_reroll_cost:
		RunManager.gold -= card_reroll_cost
		card_reroll_cost += 1
		_reroll_cards_stock()
		_refresh_store_state()

func _on_buy_law_pressed(index: int) -> void:
	if index < 0 or index >= laws_for_sale.size():
		return

	var law = laws_for_sale[index]
	if RunManager != null and RunManager.gold >= law.cost:
		RunManager.gold -= law.cost
		RunManager.add_rule(law)
		laws_for_sale.remove_at(index)
		_refresh_store_state()

func _on_buy_action_card_pressed(index: int) -> void:
	if index < 0 or index >= cards_for_sale.size():
		return

	var card = cards_for_sale[index]
	if RunManager != null and RunManager.gold >= card.cost_gold:
		RunManager.gold -= card.cost_gold
		RunManager.player_deck.append(card)
		cards_for_sale.remove_at(index)
		_refresh_store_state()

func _refresh_store_state() -> void:
	if card_tooltip:
		card_tooltip.hide_tooltip()
	if rule_tooltip:
		rule_tooltip.hide_tooltip()

	if hud_bar:
		hud_bar.update_gold()
		hud_bar.refresh_deck()

	_update_header_buttons_state()
	_render_laws_stock()
	_render_cards_stock()

# =============================================================
# MODAL DE REMOÇÃO DE CARTA (PURGA DE DECK)
# =============================================================
func _build_remove_modal_ui() -> void:
	remove_modal_layer = CanvasLayer.new()
	remove_modal_layer.layer = 130
	remove_modal_layer.visible = false
	add_child(remove_modal_layer)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.08, 0.90)
	remove_modal_layer.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	remove_modal_layer.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(1100, 600)
	panel.add_theme_stylebox_override("panel", PixelUI.make_pixel_panel(Color(0.08, 0.1, 0.15, 0.98), Color(0.95, 0.35, 0.4), 24))
	center.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	margin.add_child(vb)

	var title = Label.new()
	title.text = "REMOVER UMA CARTA DO DECK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 1.0))
	title.add_theme_constant_override("outline_size", 8)
	vb.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Selecione a carta que deseja destruir definitivamente do seu baralho:"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.85, 0.92))
	vb.add_child(subtitle)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)

	var scroll_center = CenterContainer.new()
	scroll_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(scroll_center)

	remove_grid = HBoxContainer.new()
	remove_grid.alignment = BoxContainer.ALIGNMENT_CENTER
	remove_grid.add_theme_constant_override("separation", 24)
	scroll_center.add_child(remove_grid)

	var cancel_btn = Button.new()
	cancel_btn.text = "CANCELAR"
	cancel_btn.custom_minimum_size = Vector2(220, 46)
	cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_btn.add_theme_font_size_override("font_size", 20)
	cancel_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.14, 0.16, 0.20), Color(0.4, 0.45, 0.55)))
	cancel_btn.pressed.connect(func():
		remove_modal_layer.visible = false
		if card_tooltip:
			card_tooltip.hide_tooltip()
	)
	vb.add_child(cancel_btn)

func _on_remove_card_clicked() -> void:
	if RunManager == null or RunManager.gold < remove_card_cost:
		return

	for child in remove_grid.get_children():
		child.queue_free()

	for i in range(RunManager.player_deck.size()):
		var card = RunManager.player_deck[i]
		var item = _create_remove_card_slot(card, i)
		remove_grid.add_child(item)

	remove_modal_layer.visible = true

func _create_remove_card_slot(card: ActionCard, deck_idx: int) -> Control:
	var wrapper = VBoxContainer.new()
	wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
	wrapper.add_theme_constant_override("separation", 10)

	var card_visual = ActionCardVisual.new(card, true)
	card_visual.mouse_filter = Control.MOUSE_FILTER_STOP
	wrapper.add_child(card_visual)

	card_visual.mouse_entered.connect(func():
		if card_tooltip:
			var tip_pos = card_visual.global_position + Vector2(ActionCardVisual.CARD_WIDTH / 2.0, 0.0)
			card_tooltip.show_tooltip(card, tip_pos)
	)
	card_visual.mouse_exited.connect(func():
		if card_tooltip:
			card_tooltip.hide_tooltip()
	)

	var destroy_btn = Button.new()
	destroy_btn.text = "DESTRUIR"
	destroy_btn.custom_minimum_size = Vector2(ActionCardVisual.CARD_WIDTH, 40)
	destroy_btn.add_theme_font_size_override("font_size", 17)
	destroy_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.24, 0.08, 0.10), Color(0.95, 0.25, 0.3)))
	destroy_btn.add_theme_stylebox_override("hover", PixelUI.make_bevel_card(Color(0.36, 0.10, 0.12), Color(1.0, 0.4, 0.45)))
	destroy_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.9))

	destroy_btn.pressed.connect(func():
		if card_tooltip:
			card_tooltip.hide_tooltip()
		RunManager.gold -= remove_card_cost
		remove_card_cost += 2 # Escala de custo para remoções subsequentes
		RunManager.player_deck.remove_at(deck_idx)
		remove_modal_layer.visible = false
		_refresh_store_state()
	)
	wrapper.add_child(destroy_btn)

	return wrapper

func _toggle_inventory() -> void:
	if inventory_ui:
		inventory_ui.toggle_visibility()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			_toggle_inventory()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			if remove_modal_layer and remove_modal_layer.visible:
				remove_modal_layer.visible = false
				if card_tooltip:
					card_tooltip.hide_tooltip()
				get_viewport().set_input_as_handled()
			elif inventory_ui and inventory_ui.visible:
				inventory_ui.visible = false
				get_viewport().set_input_as_handled()

func _on_leave_pressed() -> void:
	get_tree().call_deferred("change_scene_to_file", MAP_SCENE_PATH)
