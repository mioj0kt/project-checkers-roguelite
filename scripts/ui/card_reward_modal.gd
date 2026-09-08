class_name ActionCardRewardModal
extends CanvasLayer

signal card_chosen(card: ActionCard)
signal skipped()

var cards_container: HBoxContainer
var root_ctrl: Control

func _init() -> void:
	layer = 120
	visible = false
	_build_ui()

func _build_ui() -> void:
	root_ctrl = Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_ctrl)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.08, 0.88)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(bg)

	var center_vbox = VBoxContainer.new()
	center_vbox.set_anchors_preset(Control.PRESET_CENTER)
	center_vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center_vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	center_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center_vbox.add_theme_constant_override("separation", 32)
	center_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(center_vbox)

	var header_vbox = VBoxContainer.new()
	header_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_vbox.add_theme_constant_override("separation", 6)
	center_vbox.add_child(header_vbox)

	var title = Label.new()
	title.text = "RECOMPENSA DE BATALHA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 1.0))
	title.add_theme_constant_override("outline_size", 10)
	header_vbox.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Escolha 1 Carta de Ação para adicionar ao seu Baralho"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95))
	header_vbox.add_child(subtitle)

	cards_container = HBoxContainer.new()
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 28)
	cards_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_vbox.add_child(cards_container)

	var skip_btn = Button.new()
	skip_btn.text = "IGNORAR RECOMPENSA"
	skip_btn.custom_minimum_size = Vector2(260, 52)
	skip_btn.add_theme_font_size_override("font_size", 20)
	skip_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.12, 0.14, 0.18), Color(0.35, 0.4, 0.5)))
	skip_btn.add_theme_stylebox_override("hover", PixelUI.make_bevel_card(Color(0.18, 0.20, 0.26), Color(0.55, 0.6, 0.7)))
	skip_btn.pressed.connect(func():
		visible = false
		skipped.emit()
	)
	center_vbox.add_child(skip_btn)

func prompt_reward() -> void:
	for child in cards_container.get_children():
		child.queue_free()

	var chosen_cards = LootTables.get_random_action_cards(3)

	for card in chosen_cards:
		var card_widget = _create_reward_card_widget(card)
		cards_container.add_child(card_widget)

	visible = true

func _create_reward_card_widget(card: ActionCard) -> Control:
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(280, 310)
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	container.add_theme_stylebox_override("panel", PixelUI.make_pixel_panel(Color(0.09, 0.11, 0.17, 0.98), Color(0.35, 0.75, 1.0), 18))

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(margin)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vb)

	var tag = Label.new()
	tag.text = "[ %s ]" % ActionCard.get_rarity_name(card.rarity)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 15)
	tag.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	vb.add_child(tag)

	var title = Label.new()
	title.text = card.name.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 1.0))
	title.add_theme_constant_override("outline_size", 8)
	vb.add_child(title)

	var div = ColorRect.new()
	div.custom_minimum_size = Vector2(0, 2)
	div.color = Color(0.28, 0.45, 0.7, 0.7)
	vb.add_child(div)

	var desc = Label.new()
	desc.text = card.description
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", Color(0.88, 0.92, 0.98))
	desc.add_theme_constant_override("line_spacing", 4)
	vb.add_child(desc)

	var pick_btn = Button.new()
	pick_btn.text = "ESCOLHER"
	pick_btn.custom_minimum_size = Vector2(0, 48)
	pick_btn.add_theme_font_size_override("font_size", 20)
	pick_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.12, 0.22, 0.16), Color(0.3, 0.9, 0.4)))
	pick_btn.add_theme_stylebox_override("hover", PixelUI.make_bevel_card(Color(0.18, 0.30, 0.22), Color(0.5, 1.0, 0.6)))
	pick_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.5))
	pick_btn.pressed.connect(func():
		RunManager.player_deck.append(card)
		visible = false
		card_chosen.emit(card)
	)
	vb.add_child(pick_btn)

	return container
