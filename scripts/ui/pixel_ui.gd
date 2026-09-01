class_name PixelUI
extends RefCounted

# Gera uma caixa de diálogo
static func make_pixel_panel(bg_color: Color = Color(0.08, 0.09, 0.12, 0.96), border_color: Color = Color(0.28, 0.65, 1.0), padding: int = 8) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	
	# Cantos estritamente retos
	style.set_corner_radius_all(0)
	
	# Borda principal espessa
	style.set_border_width_all(2)
	style.border_color = border_color
	
	# Padding interno
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding

	# Sombra dura (sem blur suave)
	style.shadow_color = Color(0, 0, 0, 0.8)
	style.shadow_size = 4
	style.shadow_offset = Vector2(3, 3)

	return style

# Gera caixas de cartas e botões com efeito
static func make_bevel_card(base_color: Color, border_color: Color, is_pressed_or_active: bool = false) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = base_color
	style.set_corner_radius_all(0)

	style.set_border_width_all(2)
	style.border_color = border_color

	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6

	if not is_pressed_or_active:
		# Luz no topo/esquerda e sombra embaixo/direita
		style.border_width_top = 2
		style.border_width_left = 2
		style.border_width_bottom = 3
		style.border_width_right = 3
		style.shadow_size = 2
		style.shadow_offset = Vector2(2, 2)
		style.shadow_color = Color(0, 0, 0, 0.7)
	else:
		# Efeito de botão pressionado / ativado
		style.border_width_top = 3
		style.border_width_left = 3
		style.border_width_bottom = 1
		style.border_width_right = 1

	return style
