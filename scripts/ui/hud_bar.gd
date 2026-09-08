class_name HUDBar
extends CanvasLayer

signal open_laws_requested()

var gold_label: Label
var rule_tooltip: RuleCardTooltip
var side_container: VBoxContainer
var slot_buttons: Array[Button] = []

# Pilhas Visuais integradas
var deck_mgr_ref: CardDeckManager
var draw_pile_widget: Control
var discard_pile_widget: Control
var draw_deck_stack: Control
var discard_deck_stack: Control

func _ready() -> void:
	layer = 80
	_build_side_panel()

	if RunManager != null and not RunManager.rules_updated.is_connected(refresh_deck):
		RunManager.rules_updated.connect(refresh_deck)

func setup_deck_manager(deck_mgr: CardDeckManager) -> void:
	deck_mgr_ref = deck_mgr
	deck_mgr_ref.hand_updated.connect(update_pile_visual_stacks)
	deck_mgr_ref.card_played.connect(_on_card_played_animation)
	update_pile_visual_stacks()

func _build_side_panel() -> void:
	rule_tooltip = RuleCardTooltip.new()
	add_child(rule_tooltip)

	var root_ctrl = Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_ctrl)

	var panel_w: float = 240.0

	side_container = VBoxContainer.new()
	side_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side_container.add_theme_constant_override("separation", 14)

	# Ancorado no meio-esquerdo da tela
	side_container.anchor_left = 0.0
	side_container.anchor_right = 0.0
	side_container.anchor_top = 0.5
	side_container.anchor_bottom = 0.5
	side_container.offset_left = 40.0
	side_container.offset_right = 40.0 + panel_w
	side_container.grow_horizontal = Control.GROW_DIRECTION_END
	side_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	root_ctrl.add_child(side_container)

	# -------------------------------------------------------------------
	# 1. TOPO: Botão Grimório (TAB)
	# -------------------------------------------------------------------
	var laws_btn = Button.new()
	laws_btn.text = "LEIS (TAB)"
	laws_btn.custom_minimum_size = Vector2(panel_w, 50)
	laws_btn.add_theme_font_size_override("font_size", 22)
	laws_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.12, 0.18, 0.28), Color(0.35, 0.7, 1.0)))
	laws_btn.add_theme_stylebox_override("hover", PixelUI.make_bevel_card(Color(0.18, 0.26, 0.38), Color(0.55, 0.85, 1.0)))
	laws_btn.pressed.connect(func(): open_laws_requested.emit())
	side_container.add_child(laws_btn)

	# -------------------------------------------------------------------
	# 2. SLOTS 3x2 DE LEIS (Absorvido do RuleDeckHUD)
	# -------------------------------------------------------------------
	var deck_panel = PanelContainer.new()
	deck_panel.custom_minimum_size = Vector2(panel_w, 290)
	deck_panel.add_theme_stylebox_override("panel", PixelUI.make_pixel_panel(Color(0.06, 0.08, 0.12, 0.95), Color(0.3, 0.6, 0.9), 18))
	side_container.add_child(deck_panel)

	var deck_margin = MarginContainer.new()
	deck_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	deck_margin.add_theme_constant_override("margin_left", 12)
	deck_margin.add_theme_constant_override("margin_right", 12)
	deck_margin.add_theme_constant_override("margin_top", 12)
	deck_margin.add_theme_constant_override("margin_bottom", 12)
	deck_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_panel.add_child(deck_margin)

	var grid_center = CenterContainer.new()
	grid_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_margin.add_child(grid_center)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid_center.add_child(grid)

	slot_buttons.clear()
	for i in range(6):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.focus_mode = Control.FOCUS_NONE
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		btn.mouse_entered.connect(_on_rule_slot_hovered.bind(i))
		btn.mouse_exited.connect(_on_rule_slot_unhovered)
		grid.add_child(btn)
		slot_buttons.append(btn)

	refresh_deck()

	# -------------------------------------------------------------------
	# 3. PAINEL DE OURO
	# -------------------------------------------------------------------
	var gold_panel = PanelContainer.new()
	gold_panel.custom_minimum_size = Vector2(panel_w, 54)
	gold_panel.add_theme_stylebox_override("panel", PixelUI.make_pixel_panel(Color(0.08, 0.10, 0.14, 0.95), Color(0.95, 0.75, 0.2), 16))
	side_container.add_child(gold_panel)

	var gold_margin = MarginContainer.new()
	gold_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	gold_margin.add_theme_constant_override("margin_left", 14)
	gold_margin.add_theme_constant_override("margin_right", 14)
	gold_margin.add_theme_constant_override("margin_top", 6)
	gold_margin.add_theme_constant_override("margin_bottom", 6)
	gold_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gold_panel.add_child(gold_margin)

	var gold_hbox = HBoxContainer.new()
	gold_hbox.add_theme_constant_override("separation", 12)
	gold_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	gold_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gold_margin.add_child(gold_hbox)

	var coin_icon = PixelUI.make_coin_icon(28.0)
	gold_hbox.add_child(coin_icon)

	gold_label = Label.new()
	gold_label.add_theme_font_size_override("font_size", 26)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.35))
	gold_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 1.0))
	gold_label.add_theme_constant_override("outline_size", 6)
	gold_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gold_hbox.add_child(gold_label)
	update_gold()

	# -------------------------------------------------------------------
	# 4. PILHAS VISUAIS (COMPRA E DESCARTE) - Abaixo do Ouro sem colisão
	# -------------------------------------------------------------------
	var piles_hbox = HBoxContainer.new()
	piles_hbox.custom_minimum_size = Vector2(panel_w, 140)
	piles_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	piles_hbox.add_theme_constant_override("separation", 16)
	piles_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side_container.add_child(piles_hbox)

	draw_pile_widget = _create_pile_display()
	piles_hbox.add_child(draw_pile_widget)
	draw_deck_stack = draw_pile_widget.get_node("StackContainer")

	discard_pile_widget = _create_pile_display()
	piles_hbox.add_child(discard_pile_widget)
	discard_deck_stack = discard_pile_widget.get_node("StackContainer")

func _create_pile_display() -> Control:
	var root = Control.new()
	root.custom_minimum_size = Vector2(105, 140)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var stack_container = Control.new()
	stack_container.name = "StackContainer"
	stack_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	stack_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(stack_container)

	return root

func update_pile_visual_stacks() -> void:
	if deck_mgr_ref == null:
		return

	# -----------------------------------------------------------------
	# 1. PILHA DE COMPRA (Draw Pile)
	# -----------------------------------------------------------------
	for c in draw_deck_stack.get_children():
		c.queue_free()

	var draw_count = deck_mgr_ref.get_draw_count()
	var draw_cards_visible = mini(5, draw_count)
	
	# Desenhamos da base até o topo (o topo é adicionado por último, ficando na frente)
	for i in range(draw_cards_visible):
		# Pega das cartas mais abaixo até chegar na do topo
		var card_idx = (draw_count - draw_cards_visible) + i
		var card_ref: ActionCard = deck_mgr_ref.draw_pile[card_idx] if card_idx < deck_mgr_ref.draw_pile.size() else null
		
		# i representa a altura física (cartas superiores sobem levemente no eixo Y)
		var card_back = _create_mini_card_back(card_ref, i * -3.0)
		draw_deck_stack.add_child(card_back)

	# -----------------------------------------------------------------
	# 2. PILHA DE DESCARTE (Discard Pile - LIFO)
	# -----------------------------------------------------------------
	for c in discard_deck_stack.get_children():
		c.queue_free()

	var discard_count = deck_mgr_ref.get_discard_count()
	var discard_cards_visible = mini(5, discard_count)
	
	# A última carta descartada (discard_pile.back()) deve ser o topo da pilha
	for i in range(discard_cards_visible):
		# Começa nas cartas descartadas anteriormente e termina na mais recente
		var card_idx = (discard_count - discard_cards_visible) + i
		var card_ref: ActionCard = deck_mgr_ref.discard_pile[card_idx] if card_idx < deck_mgr_ref.discard_pile.size() else null
		
		# A última adicionada terá o maior z-index visual e ficará no topo da pilha
		var card_back = _create_mini_card_back(card_ref, i * -3.0)
		discard_deck_stack.add_child(card_back)

func _create_mini_card_back(card: ActionCard, y_offset: float) -> Control:
	var visual = ActionCardVisual.new(card, false)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.scale = Vector2(0.60, 0.60)
	visual.position = Vector2(5.0, 10.0 + y_offset)
	return visual

func get_draw_pile_global_pos() -> Vector2:
	if draw_pile_widget:
		return draw_pile_widget.global_position + Vector2(10.0, 10.0)
	return Vector2.ZERO

func get_discard_pile_global_pos() -> Vector2:
	if discard_pile_widget:
		return discard_pile_widget.global_position + Vector2(10.0, 10.0)
	return Vector2.ZERO

func _on_card_played_animation(card: ActionCard) -> void:
	var fly_card = ActionCardVisual.new(card, true)
	add_child(fly_card)
	fly_card.global_position = get_viewport().get_mouse_position() - (Vector2(ActionCardVisual.CARD_WIDTH, ActionCardVisual.CARD_HEIGHT) / 2.0)

	var target_pos = get_discard_pile_global_pos()
	var tween = create_tween().set_parallel(true)
	tween.tween_property(fly_card, "global_position", target_pos, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(fly_card, "scale", Vector2(0.60, 0.60), 0.35)
	tween.tween_property(fly_card, "modulate:a", 0.6, 0.35)

	await tween.finished
	fly_card.queue_free()
	update_pile_visual_stacks()

func refresh_deck() -> void:
	var active_rules = RunManager.active_rules if RunManager != null else []

	for i in range(6):
		if i >= slot_buttons.size():
			continue
		var btn = slot_buttons[i]
		if i < active_rules.size():
			var rule: RuleCard = active_rules[i]
			var cat_color = RuleCard.get_category_color(rule.category)
			var sprite_path = "res://assets/sprites/rules/front_%s.png" % rule.id

			if ResourceLoader.exists(sprite_path):
				btn.icon = load(sprite_path)
				btn.text = ""
			else:
				btn.icon = null
				btn.text = rule.name.substr(0, 2).to_upper()
				btn.add_theme_font_size_override("font_size", 24)
				btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))

			btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.10, 0.12, 0.18, 0.98), cat_color))
			btn.add_theme_stylebox_override("hover", PixelUI.make_bevel_card(Color(0.16, 0.20, 0.30, 0.98), cat_color.lightened(0.35)))
		else:
			btn.icon = null
			btn.text = "%d" % (i + 1)
			btn.add_theme_font_size_override("font_size", 20)
			btn.add_theme_color_override("font_color", Color(0.35, 0.40, 0.50))
			btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.06, 0.08, 0.11, 0.7), Color(0.22, 0.26, 0.35, 0.45)))
			btn.add_theme_stylebox_override("hover", PixelUI.make_bevel_card(Color(0.08, 0.10, 0.14, 0.8), Color(0.30, 0.35, 0.45, 0.6)))

func update_gold() -> void:
	var g = RunManager.gold if RunManager != null else 0
	if gold_label:
		gold_label.text = "%d" % g

func _on_rule_slot_hovered(idx: int) -> void:
	if rule_tooltip == null:
		return
	var active_rules = RunManager.active_rules if RunManager != null else []
	if idx < active_rules.size():
		var btn = slot_buttons[idx]
		var screen_pos = btn.global_position + Vector2(btn.size.x + 18.0, 0.0)
		rule_tooltip.show_tooltip(active_rules[idx], screen_pos)

func _on_rule_slot_unhovered() -> void:
	if rule_tooltip != null:
		rule_tooltip.hide_tooltip()
