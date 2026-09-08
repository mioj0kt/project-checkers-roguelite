class_name RuleCardVisual
extends Control

signal flipped_face_up()

# Formato Quadrado
const CARD_SIZE: float = 180.0

var rule: RuleCard
var is_face_up: bool = false
var tooltip_ref: RuleCardTooltip

var card_root: Control
var back_view: Control
var front_view: Control
var flip_tween: Tween

func _init(p_rule: RuleCard, p_tooltip: RuleCardTooltip = null, start_face_up: bool = false) -> void:
	rule = p_rule
	tooltip_ref = p_tooltip
	is_face_up = start_face_up
	custom_minimum_size = Vector2(CARD_SIZE, CARD_SIZE)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_card()

func _build_card() -> void:
	card_root = Control.new()
	card_root.custom_minimum_size = Vector2(CARD_SIZE, CARD_SIZE)
	card_root.size = card_root.custom_minimum_size
	card_root.position = Vector2(CARD_SIZE / 2.0, CARD_SIZE / 2.0)
	card_root.pivot_offset = Vector2(CARD_SIZE / 2.0, CARD_SIZE / 2.0)
	card_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_root)

	# -------------------------------------------------------------
	# 1. VERSO DA CARTA (res://assets/sprites/rules/back_{color}.png)
	# -------------------------------------------------------------
	var cat_color_name = _get_category_slug(rule.category if rule != null else 0)
	var back_tex_path = "res://assets/sprites/rules/back_%s.png" % cat_color_name

	if ResourceLoader.exists(back_tex_path):
		var back_rect = TextureRect.new()
		back_rect.texture = load(back_tex_path)
		back_rect.position = -card_root.pivot_offset
		back_rect.custom_minimum_size = Vector2(CARD_SIZE, CARD_SIZE)
		back_rect.size = back_rect.custom_minimum_size
		back_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		back_rect.stretch_mode = TextureRect.STRETCH_SCALE
		back_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		back_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		back_view = back_rect
		card_root.add_child(back_view)
	else:
		var cat_color = RuleCard.get_category_color(rule.category if rule != null else 0)
		var p_back = PanelContainer.new()
		p_back.position = -card_root.pivot_offset
		p_back.custom_minimum_size = Vector2(CARD_SIZE, CARD_SIZE)
		p_back.size = p_back.custom_minimum_size
		p_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p_back.add_theme_stylebox_override("panel", PixelUI.make_pixel_panel(cat_color.darkened(0.5), cat_color, 16))
		back_view = p_back
		card_root.add_child(back_view)

	# -------------------------------------------------------------
	# 2. FRENTE DA CARTA (res://assets/sprites/rules/front_{id}.png)
	# -------------------------------------------------------------
	var rule_id = rule.id if rule != null else ""
	var front_tex_path = "res://assets/sprites/rules/front_%s.png" % rule_id

	if ResourceLoader.exists(front_tex_path):
		var front_rect = TextureRect.new()
		front_rect.texture = load(front_tex_path)
		front_rect.position = -card_root.pivot_offset
		front_rect.custom_minimum_size = Vector2(CARD_SIZE, CARD_SIZE)
		front_rect.size = front_rect.custom_minimum_size
		front_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		front_rect.stretch_mode = TextureRect.STRETCH_SCALE
		front_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		front_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		front_view = front_rect
		card_root.add_child(front_view)
	else:
		var cat_color = RuleCard.get_category_color(rule.category if rule != null else 0)
		var p_front = PanelContainer.new()
		p_front.position = -card_root.pivot_offset
		p_front.custom_minimum_size = Vector2(CARD_SIZE, CARD_SIZE)
		p_front.size = p_front.custom_minimum_size
		p_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p_front.add_theme_stylebox_override("panel", PixelUI.make_pixel_panel(Color(0.08, 0.1, 0.14, 0.98), cat_color, 16))
		front_view = p_front
		card_root.add_child(front_view)

	back_view.visible = not is_face_up
	front_view.visible = is_face_up

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _get_category_slug(cat: int) -> String:
	match cat:
		RuleCard.Category.MOVEMENT:  return "blue"
		RuleCard.Category.CAPTURE:   return "red"
		RuleCard.Category.PROMOTION: return "yellow"
		RuleCard.Category.TURN:      return "purple"
		RuleCard.Category.BOARD:     return "green"
		_:                           return "orange"

func play_flip_reveal(delay: float = 0.0) -> void:
	if flip_tween and flip_tween.is_valid():
		flip_tween.kill()

	is_face_up = false
	back_view.visible = true
	front_view.visible = false
	card_root.scale.x = 1.0

	flip_tween = create_tween()
	if delay > 0.0:
		flip_tween.tween_interval(delay)

	flip_tween.tween_property(card_root, "scale:x", 0.0, 0.18)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	flip_tween.tween_callback(func():
		back_view.visible = false
		front_view.visible = true
		is_face_up = true
	)

	flip_tween.tween_property(card_root, "scale:x", 1.0, 0.22)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	flip_tween.tween_callback(func(): flipped_face_up.emit())

func _on_mouse_entered() -> void:
	if not is_face_up or tooltip_ref == null or rule == null:
		return
	var screen_pos = global_position + Vector2(size.x + 16.0, 0.0)
	tooltip_ref.show_tooltip(rule, screen_pos)

func _on_mouse_exited() -> void:
	if tooltip_ref != null:
		tooltip_ref.hide_tooltip()
