class_name InventoryUI
extends CanvasLayer

var modal_panel: PanelContainer
var grid_container: GridContainer
var count_label: Label
var empty_label: Label
var tooltip: RuleCardTooltip

func _ready() -> void:
	layer = 95
	visible = false

func setup() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg_overlay = ColorRect.new()
	bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_overlay.color = Color(0.02, 0.03, 0.05, 0.84)
	add_child(bg_overlay)

	# Tooltip dedicado para o inventário
	tooltip = RuleCardTooltip.new()
	add_child(tooltip)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	modal_panel = PanelContainer.new()
	modal_panel.custom_minimum_size = Vector2(1140, 720)
	modal_panel.add_theme_stylebox_override("panel", PixelUI.make_pixel_panel(Color(0.08, 0.09, 0.13, 0.98), Color(0.28, 0.65, 1.0), 28))
	center.add_child(modal_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	modal_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	# Cabeçalho
	var header_hbox = HBoxContainer.new()
	vbox.add_child(header_hbox)

	var title_lbl = Label.new()
	title_lbl.text = "GRIMÓRIO DE LEIS ATIVAS"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 40)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	title_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 1.0))
	title_lbl.add_theme_constant_override("outline_size", 10)
	header_hbox.add_child(title_lbl)

	count_label = Label.new()
	count_label.add_theme_font_size_override("font_size", 26)
	count_label.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	header_hbox.add_child(count_label)

	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 3)
	divider.color = Color(0.25, 0.3, 0.42, 0.85)
	vbox.add_child(divider)

	# Área Central com Rolagem
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var scroll_center = CenterContainer.new()
	scroll_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(scroll_center)

	grid_container = GridContainer.new()
	grid_container.columns = 3
	grid_container.add_theme_constant_override("h_separation", 48)
	grid_container.add_theme_constant_override("v_separation", 32)
	scroll_center.add_child(grid_container)

	empty_label = Label.new()
	empty_label.text = "Nenhuma Lei ativa no momento.\nObtenha novas Leis vencendo Duelos Fortes ou no Mercado."
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	empty_label.add_theme_font_size_override("font_size", 24)
	empty_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	vbox.add_child(empty_label)

	# Rodapé
	var footer_hbox = HBoxContainer.new()
	vbox.add_child(footer_hbox)

	var tip_lbl = Label.new()
	tip_lbl.text = "Passe o cursor sobre uma Lei para ler seus efeitos • [TAB] ou [ESC] para fechar"
	tip_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tip_lbl.add_theme_font_size_override("font_size", 20)
	tip_lbl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.78))
	footer_hbox.add_child(tip_lbl)

	var close_btn = Button.new()
	close_btn.text = "FECHAR"
	close_btn.custom_minimum_size = Vector2(160, 48)
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.2, 0.1, 0.12), Color(0.9, 0.25, 0.3)))
	close_btn.pressed.connect(func():
		if tooltip:
			tooltip.hide_tooltip()
		visible = false
	)
	footer_hbox.add_child(close_btn)

func toggle_visibility() -> void:
	visible = not visible
	if visible:
		refresh_laws()
	else:
		if tooltip:
			tooltip.hide_tooltip()

func refresh_laws() -> void:
	if tooltip:
		tooltip.hide_tooltip()

	for c in grid_container.get_children():
		c.queue_free()

	var rules = RunManager.active_rules if RunManager != null else []
	count_label.text = "LEIS: %d / 6" % rules.size()

	if rules.is_empty():
		empty_label.visible = true
		grid_container.visible = false
		return

	empty_label.visible = false
	grid_container.visible = true

	for rule in rules:
		grid_container.add_child(_create_law_slot(rule))

func _create_law_slot(rule: RuleCard) -> Control:
	var wrapper = VBoxContainer.new()
	wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
	wrapper.add_theme_constant_override("separation", 10)

	# Carta quadrada com sprite frontal exibido e hover conectado ao tooltip
	var card_visual = RuleCardVisual.new(rule, tooltip, true)
	wrapper.add_child(card_visual)

	# Botão para revogar/descartar lei do grimório
	var revoke_btn = Button.new()
	revoke_btn.text = "REVOGAR"
	revoke_btn.custom_minimum_size = Vector2(RuleCardVisual.CARD_SIZE, 38)
	revoke_btn.add_theme_font_size_override("font_size", 16)
	revoke_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.18, 0.08, 0.1), Color(0.85, 0.2, 0.25)))
	revoke_btn.add_theme_stylebox_override("hover", PixelUI.make_bevel_card(Color(0.26, 0.10, 0.14), Color(1.0, 0.35, 0.4)))
	revoke_btn.pressed.connect(func():
		if RunManager != null:
			RunManager.remove_rule(rule.id)
			refresh_laws()
	)
	wrapper.add_child(revoke_btn)

	return wrapper
