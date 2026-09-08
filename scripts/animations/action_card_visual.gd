class_name ActionCardVisual
extends Control

signal flipped_face_up()

const CARD_WIDTH: float = 160.0
const CARD_HEIGHT: float = 224.0

var card: ActionCard
var is_face_up: bool = true

var card_root: Control
var back_view: Control
var front_view: Control
var flip_tween: Tween

func _init(p_card: ActionCard, start_face_up: bool = true) -> void:
	card = p_card
	is_face_up = start_face_up
	custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_card()

func _build_card() -> void:
	card_root = Control.new()
	card_root.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	card_root.size = card_root.custom_minimum_size
	card_root.position = Vector2(CARD_WIDTH / 2.0, CARD_HEIGHT / 2.0)
	card_root.pivot_offset = Vector2(CARD_WIDTH / 2.0, CARD_HEIGHT / 2.0)
	card_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_root)

	var rar_color: Color = get_rarity_color(card.rarity if card != null else 0)

	# -------------------------------------------------------------
	# 1. VERSO DA CARTA (res://assets/sprites/cards/back_{rarity}.png)
	# -------------------------------------------------------------
	var rarity_slug = _get_rarity_slug(card.rarity if card != null else 0)
	var back_tex_path = "res://assets/sprites/cards/back_%s.png" % rarity_slug

	if ResourceLoader.exists(back_tex_path):
		var back_rect = TextureRect.new()
		back_rect.texture = load(back_tex_path)
		back_rect.position = -card_root.pivot_offset
		back_rect.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		back_rect.size = back_rect.custom_minimum_size
		back_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		back_rect.stretch_mode = TextureRect.STRETCH_SCALE
		back_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		back_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		back_view = back_rect
		card_root.add_child(back_view)
	else:
		back_view = _build_back_frame(rar_color)
		back_view.position = -card_root.pivot_offset
		card_root.add_child(back_view)

	# -------------------------------------------------------------
	# 2. FRENTE DA CARTA
	# -------------------------------------------------------------
	var card_id = card.id if card != null else ""
	var front_tex_path = "res://assets/sprites/cards/front_%s.png" % card_id

	if ResourceLoader.exists(front_tex_path):
		var front_wrapper = Control.new()
		front_wrapper.position = -card_root.pivot_offset
		front_wrapper.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		front_wrapper.size = front_wrapper.custom_minimum_size
		front_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var front_rect = TextureRect.new()
		front_rect.texture = load(front_tex_path)
		front_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		front_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		front_rect.stretch_mode = TextureRect.STRETCH_SCALE
		front_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		front_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		front_wrapper.add_child(front_rect)

		var border_overlay = Panel.new()
		border_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		border_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border_overlay.add_theme_stylebox_override("panel", PixelUI.make_pixel_panel(Color(0, 0, 0, 0), rar_color, 16))
		front_wrapper.add_child(border_overlay)

		front_view = front_wrapper
		card_root.add_child(front_view)
	else:
		front_view = _build_card_face(rar_color)
		front_view.position = -card_root.pivot_offset
		card_root.add_child(front_view)

	back_view.visible = not is_face_up
	front_view.visible = is_face_up

func _build_back_frame(rar_color: Color) -> Control:
	var root = PanelContainer.new()
	root.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	root.size = root.custom_minimum_size
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_stylebox_override("panel", PixelUI.make_bevel_card(Color(0.06, 0.07, 0.10, 1.0), rar_color))

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var seal = UniversalCardSeal.new("", rar_color)
	seal.custom_minimum_size = Vector2(70, 70)
	center.add_child(seal)

	return root

func _build_card_face(rar_color: Color) -> Control:
	var root = PanelContainer.new()
	root.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	root.size = root.custom_minimum_size
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_stylebox_override("panel", PixelUI.make_bevel_card(Color(0.09, 0.10, 0.14, 1.0), rar_color))

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(margin)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vb)

	# --- 1. CABEÇALHO INTEGRADO (Ícone no Canto Esquerdo + Título Centralizado) ---
	var header_hbox = HBoxContainer.new()
	header_hbox.custom_minimum_size = Vector2(0, 36)
	header_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	header_hbox.add_theme_constant_override("separation", 6)
	header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(header_hbox)

	# Selo compacto alojado no canto
	var corner_seal = UniversalCardSeal.new(card.id if card != null else "", rar_color)
	corner_seal.custom_minimum_size = Vector2(34, 34)
	header_hbox.add_child(corner_seal)

	# Título ao lado do ícone ocupando todo o espaço superior
	var title = Label.new()
	title.text = card.name.to_upper() if card != null else ""
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.94, 0.55))
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04, 1.0))
	title.add_theme_constant_override("outline_size", 6)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_hbox.add_child(title)

	# Linha divisória fina sob o cabeçalho
	var div = ColorRect.new()
	div.custom_minimum_size = Vector2(0, 2)
	div.color = Color(rar_color.r, rar_color.g, rar_color.b, 0.6)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(div)

	# --- 2. PERGAMINHO PRINCIPAL EXPANDIDO (Ocupa o restante da carta) ---
	var desc_box = PanelContainer.new()
	desc_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_box.add_theme_stylebox_override("panel", PixelUI.make_bevel_card(Color(0.06, 0.07, 0.10, 0.95), Color(0.20, 0.24, 0.32, 0.5)))
	vb.add_child(desc_box)

	var scroll_margin = MarginContainer.new()
	scroll_margin.add_theme_constant_override("margin_left", 8)
	scroll_margin.add_theme_constant_override("margin_right", 8)
	scroll_margin.add_theme_constant_override("margin_top", 10)
	scroll_margin.add_theme_constant_override("margin_bottom", 10)
	scroll_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_box.add_child(scroll_margin)

	var desc = Label.new()
	desc.text = card.description if card != null else ""
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	desc.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04, 1.0))
	desc.add_theme_constant_override("outline_size", 4)
	desc.add_theme_constant_override("line_spacing", 4)
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll_margin.add_child(desc)

	return root

static func get_rarity_color(rar: int) -> Color:
	match rar:
		ActionCard.Rarity.COMMON:    return Color(0.72, 0.76, 0.82)
		ActionCard.Rarity.RARE:      return Color(0.25, 0.65, 1.00)
		ActionCard.Rarity.EPIC:      return Color(0.75, 0.32, 0.95)
		ActionCard.Rarity.LEGENDARY: return Color(1.00, 0.84, 0.20)
	return Color(0.72, 0.76, 0.82)

func _get_rarity_slug(rar: int) -> String:
	match rar:
		ActionCard.Rarity.COMMON:    return "common"
		ActionCard.Rarity.RARE:      return "rare"
		ActionCard.Rarity.EPIC:      return "epic"
		ActionCard.Rarity.LEGENDARY: return "legendary"
	return "common"

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

	flip_tween.tween_property(card_root, "scale:x", 0.0, 0.16)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	flip_tween.tween_callback(func():
		back_view.visible = false
		front_view.visible = true
		is_face_up = true
	)

	flip_tween.tween_property(card_root, "scale:x", 1.0, 0.20)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	flip_tween.tween_callback(func(): flipped_face_up.emit())


# ==============================================================================
# MEDALHÃO UNIVERSAL COMPACTO (Com losango completamente fechado)
# ==============================================================================
class UniversalCardSeal:
	extends Control

	var card_id: String
	var color: Color
	var icon_texture: Texture2D = null

	func _init(p_id: String, p_color: Color) -> void:
		card_id = p_id
		color = p_color
		mouse_filter = Control.MOUSE_FILTER_IGNORE

		var custom_icon_path = "res://assets/sprites/cards/icons/%s.png" % card_id
		var generic_icon_path = "res://assets/sprites/cards/icons/icon_action.png"

		if ResourceLoader.exists(custom_icon_path):
			icon_texture = load(custom_icon_path)
		elif ResourceLoader.exists(generic_icon_path):
			icon_texture = load(generic_icon_path)

	func _draw() -> void:
		var c = size / 2.0
		var r = minf(size.x, size.y) * 0.44

		# 1. Base do Selo: Círculo escuro com contorno
		draw_circle(c, r, Color(0.04, 0.05, 0.08, 0.95))
		draw_arc(c, r, 0, TAU, 32, Color(color.r, color.g, color.b, 0.7), 1.8)

		# 2. Ícone ou Losango Geométrico Fechado
		if icon_texture != null:
			var icon_size = Vector2(r * 1.3, r * 1.3)
			var dest_rect = Rect2(c - icon_size / 2.0, icon_size)
			draw_texture_rect(icon_texture, dest_rect, false)
		else:
			# Losango com 5 vértices (retornando ao ponto inicial) para fechar todos os 4 lados
			var p_top = c + Vector2(0, -r * 0.58)
			var p_right = c + Vector2(r * 0.52, 0)
			var p_bottom = c + Vector2(0, r * 0.58)
			var p_left = c + Vector2(-r * 0.52, 0)

			var diamond_poly = PackedVector2Array([p_top, p_right, p_bottom, p_left])
			var diamond_closed_outline = PackedVector2Array([p_top, p_right, p_bottom, p_left, p_top])

			draw_colored_polygon(diamond_poly, Color(color.r, color.g, color.b, 0.3))
			draw_polyline(diamond_closed_outline, color, 1.8)
			draw_circle(c, r * 0.16, color)
