class_name GameOverModal
extends CanvasLayer

signal action_confirmed(won: bool)

var is_won_state: bool = false
var is_counting: bool = false
var skip_requested: bool = false

var modal_panel: PanelContainer
var title_label: Label
var stats_container: VBoxContainer
var total_label: Label
var confirm_btn: Button

# Estrutura dos dados de recompensa
var reward_data: Dictionary = {}

func _ready() -> void:
	layer = 100
	visible = false
	_build_ui()

func _build_ui() -> void:
	# Fundo Escurecido
	var bg_overlay = ColorRect.new()
	bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_overlay.color = Color(0.02, 0.03, 0.05, 0.82)
	add_child(bg_overlay)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	modal_panel = PanelContainer.new()
	modal_panel.custom_minimum_size = Vector2(580, 420)
	center.add_child(modal_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	modal_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 1.0))
	title_label.add_theme_constant_override("outline_size", 8)
	vbox.add_child(title_label)

	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 3)
	divider.color = Color(0.25, 0.28, 0.35, 0.9)
	vbox.add_child(divider)

	stats_container = VBoxContainer.new()
	stats_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stats_container.add_theme_constant_override("separation", 14)
	vbox.add_child(stats_container)

	total_label = Label.new()
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	total_label.add_theme_font_size_override("font_size", 24)
	total_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	vbox.add_child(total_label)

	confirm_btn = Button.new()
	confirm_btn.custom_minimum_size = Vector2(260, 52)
	confirm_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm_btn.add_theme_font_size_override("font_size", 22)
	confirm_btn.pressed.connect(_on_confirm_pressed)
	vbox.add_child(confirm_btn)

func show_game_over(won: bool, rewards: Dictionary = {}, custom_title: String = "") -> void:
	is_won_state = won
	visible = true
	skip_requested = false
	reward_data = rewards

	for child in stats_container.get_children():
		child.queue_free()

	if won:
		var title_txt = custom_title if custom_title != "" else "VITORIA NO DUELO!"
		title_label.text = title_txt
		title_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.2))
		modal_panel.add_theme_stylebox_override("panel", PixelUI.make_pixel_panel(Color(0.08, 0.1, 0.14, 0.98), Color(1.0, 0.84, 0.2), 24))

		confirm_btn.text = "CONTINUAR ->"
		confirm_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.12, 0.22, 0.15), Color(0.3, 0.9, 0.45)))
		confirm_btn.disabled = true # Trava até o final das animações
		total_label.text = ""

		_run_rewards_animation()
	else:
		title_label.text = "GAME OVER"
		title_label.add_theme_color_override("font_color", Color(0.95, 0.2, 0.25))
		modal_panel.add_theme_stylebox_override("panel", PixelUI.make_pixel_panel(Color(0.12, 0.05, 0.06, 0.98), Color(0.85, 0.15, 0.2), 24))

		var defeat_lbl = Label.new()
		defeat_lbl.text = "Suas pecas foram eliminadas pelo exercito inimigo."
		defeat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		defeat_lbl.add_theme_font_size_override("font_size", 18)
		defeat_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
		stats_container.add_child(defeat_lbl)

		total_label.text = ""
		confirm_btn.text = "TENTAR NOVAMENTE"
		confirm_btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.25, 0.1, 0.12), Color(0.9, 0.25, 0.3)))
		confirm_btn.disabled = false

func _input(event: InputEvent) -> void:
	if not visible or not is_won_state:
		return

	# Clique esquerdo para pular animação
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_counting and not skip_requested:
			skip_requested = true

func _run_rewards_animation() -> void:
	is_counting = true

	var rows = [
		{"label": "VITORIA:", "amount": reward_data.get("base", 5)},
		{"label": "CAPTURAS:", "amount": reward_data.get("captures", 0)},
		{"label": "SOBREVIVENTES:", "amount": reward_data.get("survival", 0)}
	]

	if reward_data.get("midas", 0) > 0:
		rows.append({"label": "TOQUE DE MIDAS:", "amount": reward_data.get("midas", 0)})

	var total_gold_accum = 0

	for item in rows:
		var row_box = HBoxContainer.new()
		row_box.add_theme_constant_override("separation", 14)
		stats_container.add_child(row_box)

		var lbl = Label.new()
		lbl.text = item["label"]
		lbl.custom_minimum_size = Vector2(180, 0)
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
		row_box.add_child(lbl)

		var coins_container = HBoxContainer.new()
		coins_container.add_theme_constant_override("separation", 6)
		row_box.add_child(coins_container)

		var val_lbl = Label.new()
		val_lbl.text = ""
		val_lbl.add_theme_font_size_override("font_size", 20)
		val_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		row_box.add_child(val_lbl)

		var count: int = item["amount"]
		total_gold_accum += count

		# Spawna as moedas com aceleração
		var current_delay = 0.14
		for c in range(count):
			var coin = _create_coin_circle()
			coins_container.add_child(coin)
			val_lbl.text = "+%d" % (c + 1)

			if not skip_requested:
				# Efeito de pop-in na moeda
				var t = create_tween()
				coin.scale = Vector2(0.3, 0.3)
				t.tween_property(coin, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

				await get_tree().create_timer(current_delay).timeout
				# Acelera progressivamente a cada moeda
				current_delay = max(0.02, current_delay * 0.88)
			else:
				coin.scale = Vector2.ONE

		if count == 0:
			val_lbl.text = "+0"

		if not skip_requested:
			await get_tree().create_timer(0.12).timeout

	total_label.text = "TOTAL RECEBIDO: +%d OURO" % reward_data.get("total", total_gold_accum)
	is_counting = false
	confirm_btn.disabled = false

# Moeda
func _create_coin_circle() -> Control:
	var coin_ctrl = Control.new()
	coin_ctrl.custom_minimum_size = Vector2(22, 22)
	coin_ctrl.pivot_offset = Vector2(11, 11)

	var draw_node = Node2D.new()
	draw_node.draw.connect(func():
		var center = Vector2(11, 11)
		# Sombra
		draw_node.draw_circle(center + Vector2(1, 2), 9.0, Color(0.0, 0.0, 0.0, 0.35))
		# Borda escura
		draw_node.draw_circle(center, 9.0, Color(0.45, 0.32, 0.08))
		# Corpo Dourado
		draw_node.draw_circle(center, 7.5, Color(1.0, 0.84, 0.2))
		# Brilho Superior
		draw_node.draw_circle(center - Vector2(2, 2), 3.0, Color(1.0, 0.95, 0.6, 0.9))
		# Núcleo
		draw_node.draw_rect(Rect2(center.x - 2, center.y - 2, 4, 4), Color(0.85, 0.65, 0.15))
	)
	coin_ctrl.add_child(draw_node)
	return coin_ctrl

func _on_confirm_pressed() -> void:
	if is_counting:
		return
	action_confirmed.emit(is_won_state)
