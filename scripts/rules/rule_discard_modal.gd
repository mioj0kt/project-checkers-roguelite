class_name RuleDiscardModal
extends CanvasLayer

signal rule_replaced(discarded_rule: RuleCard, new_rule: RuleCard)
signal replacement_canceled()

var panel: PanelContainer
var current_rules_container: HBoxContainer
var incoming_card_container: CenterContainer
var cancel_btn: Button
var tooltip_ref: RuleCardTooltip

var pending_new_rule: RuleCard = null

func _ready() -> void:
	layer = 125
	visible = false
	_build_ui()

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.03, 0.05, 0.92)
	add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(860, 460)
	panel.add_theme_stylebox_override("panel", PixelUI.make_pixel_panel(Color(0.08, 0.09, 0.13, 0.98), Color(0.9, 0.35, 0.35), 24))
	center.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = "LIMITE DE LEIS ATINGIDO (6/6)"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	vbox.add_child(title_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "Escolha uma Lei existente para REVOGAR e abrir espaco para a nova Lei:"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 15)
	sub_lbl.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
	vbox.add_child(sub_lbl)

	current_rules_container = HBoxContainer.new()
	current_rules_container.alignment = BoxContainer.ALIGNMENT_CENTER
	current_rules_container.add_theme_constant_override("separation", 12)
	vbox.add_child(current_rules_container)

	var div = ColorRect.new()
	div.custom_minimum_size = Vector2(0, 2)
	div.color = Color(0.3, 0.35, 0.45, 0.8)
	vbox.add_child(div)

	incoming_card_container = CenterContainer.new()
	vbox.add_child(incoming_card_container)

	cancel_btn = Button.new()
	cancel_btn.text = "CANCELAR E MANTER LEIS ATUAIS"
	cancel_btn.custom_minimum_size = Vector2(280, 42)
	cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.2, 0.15, 0.18), Color(0.7, 0.35, 0.4)))
	cancel_btn.pressed.connect(_on_cancel_pressed)
	vbox.add_child(cancel_btn)

	tooltip_ref = RuleCardTooltip.new()
	add_child(tooltip_ref)

func prompt_replace(new_rule: RuleCard) -> void:
	pending_new_rule = new_rule
	for child in current_rules_container.get_children():
		child.queue_free()
	for child in incoming_card_container.get_children():
		child.queue_free()

	# Mostra as 6 Leis atuais como botões de descarte
	if RunManager != null:
		for rule in RunManager.active_rules:
			current_rules_container.add_child(_build_discard_card(rule))

	# Mostra a nova regra proposta abaixo
	var preview_box = HBoxContainer.new()
	preview_box.add_theme_constant_override("separation", 10)
	var in_lbl = Label.new()
	in_lbl.text = "NOVA LEI: "
	in_lbl.add_theme_font_size_override("font_size", 16)
	in_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	preview_box.add_child(in_lbl)
	
	var in_card = _build_preview_badge(new_rule)
	preview_box.add_child(in_card)
	incoming_card_container.add_child(preview_box)

	visible = true

func _build_discard_card(rule: RuleCard) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(120, 160)
	card.add_theme_stylebox_override("panel", PixelUI.make_bevel_card(Color(0.12, 0.14, 0.18, 0.98), Color(0.85, 0.3, 0.35)))

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	var name_lbl = Label.new()
	name_lbl.text = rule.name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	vbox.add_child(name_lbl)

	var rev_btn = Button.new()
	rev_btn.text = "REVOGAR"
	rev_btn.custom_minimum_size = Vector2(90, 32)
	rev_btn.add_theme_font_size_override("font_size", 13)
	rev_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.25, 0.1, 0.12), Color(1.0, 0.3, 0.35)))
	rev_btn.pressed.connect(func(): _confirm_replacement(rule))
	vbox.add_child(rev_btn)

	card.mouse_entered.connect(func(): tooltip_ref.show_for_rule(rule, card.get_global_mouse_position()))
	card.mouse_exited.connect(func(): tooltip_ref.hide_tooltip())

	return card

func _build_preview_badge(rule: RuleCard) -> PanelContainer:
	var badge = PanelContainer.new()
	badge.custom_minimum_size = Vector2(180, 36)
	badge.add_theme_stylebox_override("panel", PixelUI.make_bevel_card(Color(0.14, 0.18, 0.24), Color(0.3, 0.8, 1.0)))
	var lbl = Label.new()
	lbl.text = rule.name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	badge.add_child(lbl)
	badge.mouse_entered.connect(func(): tooltip_ref.show_for_rule(rule, badge.get_global_mouse_position()))
	badge.mouse_exited.connect(func(): tooltip_ref.hide_tooltip())
	return badge

func _confirm_replacement(discarded: RuleCard) -> void:
	visible = false
	tooltip_ref.hide_tooltip()
	if RunManager != null:
		RunManager.remove_rule(discarded.id)
		RunManager.add_rule(pending_new_rule)
	rule_replaced.emit(discarded, pending_new_rule)

func _on_cancel_pressed() -> void:
	visible = false
	tooltip_ref.hide_tooltip()
	replacement_canceled.emit()
