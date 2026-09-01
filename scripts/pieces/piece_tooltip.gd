class_name PieceTooltip
extends PanelContainer

var piece_preview: TextureRect
var fallback_panel: Panel
var fallback_label: Label
var name_label: Label
var rarity_label: Label
var desc_label: Label

const CARD_WIDTH: float = 320.0

func _init() -> void:
	visible = false
	z_index = 100
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(CARD_WIDTH, 0)

	_update_style(Color(0.28, 0.65, 1.0))

	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	var header_hbox = HBoxContainer.new()
	header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(header_hbox)

	var preview_container = Control.new()
	preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_container.custom_minimum_size = Vector2(44, 44)
	header_hbox.add_child(preview_container)

	piece_preview = TextureRect.new()
	piece_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	piece_preview.custom_minimum_size = Vector2(44, 44)
	piece_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	piece_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	piece_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview_container.add_child(piece_preview)

	fallback_panel = Panel.new()
	fallback_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fallback_panel.custom_minimum_size = Vector2(44, 44)
	preview_container.add_child(fallback_panel)

	fallback_label = Label.new()
	fallback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fallback_label.size = Vector2(44, 44)
	fallback_label.add_theme_font_size_override("font_size", 24)
	fallback_panel.add_child(fallback_label)

	var title_vbox = VBoxContainer.new()
	title_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_vbox.add_theme_constant_override("separation", 0)
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_vbox)

	name_label = Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override("font_size", 26)
	title_vbox.add_child(name_label)

	rarity_label = Label.new()
	rarity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rarity_label.add_theme_font_size_override("font_size", 20)
	title_vbox.add_child(rarity_label)

	var divider = ColorRect.new()
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(0.25, 0.28, 0.35, 0.8)
	vbox.add_child(divider)

	desc_label = Label.new()
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_label.custom_minimum_size = Vector2(CARD_WIDTH - 28, 0)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 20)
	desc_label.add_theme_color_override("font_color", Color(0.88, 0.9, 0.95))
	vbox.add_child(desc_label)

func _update_style(r_color: Color) -> void:
	var style = PixelUI.make_pixel_panel(Color(0.08, 0.09, 0.13, 0.98), r_color, 12)
	add_theme_stylebox_override("panel", style)

func show_for_piece(piece: PieceData, screen_pos: Vector2, owner_team: int = Board.WHITE) -> void:
	if piece == null:
		hide_tooltip()
		return

	var r_color = piece.get_rarity_color()
	_update_style(r_color)

	# Obtém o sprite com base no time correto da peça
	var tex = PixelRenderer.get_piece_texture(piece, owner_team)
	if tex != null:
		piece_preview.texture = tex
		piece_preview.visible = true
		fallback_panel.visible = false
	else:
		piece_preview.visible = false
		fallback_panel.visible = true
		var fb_style = StyleBoxFlat.new()
		fb_style.bg_color = piece.get_display_color()
		fb_style.border_color = Color.BLACK
		fb_style.set_border_width_all(2)
		fallback_panel.add_theme_stylebox_override("panel", fb_style)
		fallback_label.text = piece.name.left(1).to_upper()

	name_label.text = piece.name if piece.name != "" else piece.id.capitalize()
	name_label.add_theme_color_override("font_color", piece.get_display_color())

	rarity_label.text = "[" + piece.get_rarity_name().to_upper() + "]"
	rarity_label.add_theme_color_override("font_color", r_color)

	desc_label.text = piece.get_description()

	visible = true
	_adjust_position(screen_pos)

func _adjust_position(screen_pos: Vector2) -> void:
	reset_size()
	var vp_size = get_viewport_rect().size
	var target_pos = screen_pos + Vector2(20, 20)
	var real_h = max(size.y, 110.0)

	if target_pos.x + CARD_WIDTH > vp_size.x - 10:
		target_pos.x = screen_pos.x - CARD_WIDTH - 20
	if target_pos.y + real_h > vp_size.y - 10:
		target_pos.y = screen_pos.y - real_h - 20

	position = target_pos

func hide_tooltip() -> void:
	visible = false
