class_name PixelRenderer
extends RefCounted

static var texture_cache: Dictionary = {}

static func get_piece_texture(piece_data: PieceData, owner_team: int = Board.WHITE) -> Texture2D:
	if piece_data == null:
		return null

	var path = piece_data.get_texture_for_team(owner_team)
	if path != "" and ResourceLoader.exists(path):
		if not texture_cache.has(path):
			var tex = load(path) as Texture2D
			texture_cache[path] = tex
		return texture_cache[path]

	return null

# Desenha Cantoneiras Pixeladas
static func draw_pixel_corners(canvas: CanvasItem, rect: Rect2, color: Color, size_px: float = 8.0, thickness: float = 2.0) -> void:
	var l = rect.position.x + 2
	var r = rect.position.x + rect.size.x - 2
	var t = rect.position.y + 2
	var b = rect.position.y + rect.size.y - 2

	# Top-Left (Canto Superior Esquerdo)
	canvas.draw_line(Vector2(l, t), Vector2(l + size_px, t), color, thickness)
	canvas.draw_line(Vector2(l, t), Vector2(l, t + size_px), color, thickness)

	# Top-Right (Canto Superior Direito)
	canvas.draw_line(Vector2(r, t), Vector2(r - size_px, t), color, thickness)
	canvas.draw_line(Vector2(r, t), Vector2(r, t + size_px), color, thickness)

	# Bottom-Left (Canto Inferior Esquerdo)
	canvas.draw_line(Vector2(l, b), Vector2(l + size_px, b), color, thickness)
	canvas.draw_line(Vector2(l, b), Vector2(l, b - size_px), color, thickness)

	# Bottom-Right (Canto Inferior Direito)
	canvas.draw_line(Vector2(r, b), Vector2(r - size_px, b), color, thickness)
	canvas.draw_line(Vector2(r, b), Vector2(r, b - size_px), color, thickness)

# 1. VISUAL DA CASA SELECIONADA (Moldura Tática Pulsante)
static func draw_pixel_selected_tile(canvas: CanvasItem, tile_rect: Rect2, pulse: float) -> void:
	var pad = 2.0
	var inner_rect = Rect2(tile_rect.position.x + pad, tile_rect.position.y + pad, tile_rect.size.x - pad * 2, tile_rect.size.y - pad * 2)

	canvas.draw_rect(inner_rect, Color(0.15, 0.95, 0.45, 0.22))
	var border_col = Color(0.2, 1.0, 0.5, 0.9)
	canvas.draw_rect(inner_rect, border_col, false, 2.0)

	var corner_len = clamp(10.0 * pulse, 8.0, 14.0)
	draw_pixel_corners(canvas, inner_rect, Color(0.8, 1.0, 0.85, 1.0), corner_len, 3.0)

# 2. VISUAL DOS PONTOS INDICADORES DE MOVIMENTO E CAPTURA
static func draw_pixel_move_target(canvas: CanvasItem, dest_rect: Rect2, is_capture: bool, pulse: float) -> void:
	var center = dest_rect.position + (dest_rect.size / 2.0)
	var pad = 4.0
	var inner_tile = Rect2(dest_rect.position.x + pad, dest_rect.position.y + pad, dest_rect.size.x - pad * 2, dest_rect.size.y - pad * 2)

	if is_capture:
		var floor_alpha = clamp(0.18 + (pulse - 1.0) * 0.35, 0.15, 0.35)
		canvas.draw_rect(inner_tile, Color(1.0, 0.15, 0.22, floor_alpha))
		
		var corner_size = clamp(7.0 * pulse, 6.0, 10.0)
		draw_pixel_corners(canvas, inner_tile, Color(1.0, 0.35, 0.4, 0.95), corner_size, 2.0)

		var arm = 8.5 * pulse
		var red_light = Color(1.0, 0.3, 0.35)
		var red_dark = Color(0.65, 0.08, 0.12)
		var gold_core = Color(1.0, 0.9, 0.3)

		canvas.draw_line(center + Vector2(-arm + 1, -arm + 2), center + Vector2(arm + 1, arm + 2), Color(0, 0, 0, 0.5), 3.0)
		canvas.draw_line(center + Vector2(-arm + 1, arm + 2), center + Vector2(arm + 1, -arm + 2), Color(0, 0, 0, 0.5), 3.0)

		canvas.draw_line(center - Vector2(arm, arm), center + Vector2(arm, arm), red_dark, 3.5)
		canvas.draw_line(center - Vector2(arm, -arm), center + Vector2(arm, -arm), red_dark, 3.5)
		canvas.draw_line(center - Vector2(arm - 1, arm - 1), center + Vector2(arm - 1, arm - 1), red_light, 1.5)
		canvas.draw_line(center - Vector2(arm - 1, -arm + 1), center + Vector2(arm - 1, -arm + 1), red_light, 1.5)

		canvas.draw_rect(Rect2(center.x - 2, center.y - 2, 4, 4), Color(0.2, 0.02, 0.02))
		canvas.draw_rect(Rect2(center.x - 1, center.y - 1, 2, 2), gold_core)
	else:
		var glow_alpha = clamp(0.12 + (pulse - 1.0) * 0.25, 0.10, 0.25)
		canvas.draw_rect(inner_tile, Color(0.2, 0.85, 0.65, glow_alpha))

		var sz = 6.0 * pulse
		var shadow_offset = Vector2(0, 2.5)

		var top_pt = center + Vector2(0, -sz)
		var right_pt = center + Vector2(sz, 0)
		var bottom_pt = center + Vector2(0, sz)
		var left_pt = center + Vector2(-sz, 0)

		var shadow_poly = PackedVector2Array([
			top_pt + shadow_offset,
			right_pt + shadow_offset,
			bottom_pt + shadow_offset,
			left_pt + shadow_offset
		])
		canvas.draw_colored_polygon(shadow_poly, Color(0.02, 0.05, 0.04, 0.45))

		var top_facet = PackedVector2Array([left_pt, top_pt, right_pt, center])
		canvas.draw_colored_polygon(top_facet, Color(0.45, 1.0, 0.82, 0.95))

		var bottom_facet = PackedVector2Array([left_pt, center, right_pt, bottom_pt])
		canvas.draw_colored_polygon(bottom_facet, Color(0.12, 0.68, 0.48, 0.95))

		var outline_pts = PackedVector2Array([top_pt, right_pt, bottom_pt, left_pt, top_pt])
		canvas.draw_polyline(outline_pts, Color(0.04, 0.18, 0.12, 0.95), 1.5)

		canvas.draw_line(left_pt, right_pt, Color(0.75, 1.0, 0.92, 0.9), 1.0)
		canvas.draw_rect(Rect2(center.x - 1, center.y - 1, 2, 2), Color.WHITE)

# 3. AURA DO COMANDANTE
static func draw_commander_pixel_aura(canvas: CanvasItem, center: Vector2, radius: float, pulse: float) -> void:
	var aura_size = radius * pulse * 1.35
	var aura_rect = Rect2(center.x - aura_size, center.y - aura_size, aura_size * 2, aura_size * 2)
	var aura_color = Color(1.0, 0.15, 0.25, 0.35 * (pulse - 0.8) * 2.5)
	canvas.draw_rect(aura_rect, aura_color)
	draw_pixel_corners(canvas, aura_rect, Color(1.0, 0.2, 0.3, 0.85), 6.0, 2.0)

# 4. RENDERIZAÇÃO DA PEÇA (Totalmente orientada a sprites com fallback geométrico)
static func draw_piece(canvas: CanvasItem, piece_obj: BoardPiece, center: Vector2, cell_size: float, scale_factor: float) -> void:
	var data = piece_obj.data
	var is_white = (piece_obj.owner_team == Board.WHITE)
	var tex = get_piece_texture(data, piece_obj.owner_team)

	if tex != null:
		var dest_size = Vector2(cell_size * 0.82, cell_size * 0.82) * scale_factor
		var dest_rect = Rect2(center - (dest_size / 2.0), dest_size)
		
		# Sombra
		var shadow_rect = Rect2(dest_rect.position + Vector2(2, 3), dest_size)
		canvas.draw_texture_rect(tex, shadow_rect, false, Color(0, 0, 0, 0.35))
		
		# Sprite com modulação de estado (ex: congelado por teia)
		var tint = Color.WHITE
		if data.freeze_turns > 0:
			tint = Color(0.6, 1.0, 0.7)
		canvas.draw_texture_rect(tex, dest_rect, false, tint)
	else:
		# Fallback Procedural de Dama (Sem chamadas a get_icon/fontes)
		var base_radius = (cell_size * 0.36) * scale_factor
		var bg_color = Color(0.92, 0.92, 0.95) if is_white else Color(0.18, 0.2, 0.25)
		
		if data.color_override != Color.TRANSPARENT:
			bg_color = data.color_override
		if data.freeze_turns > 0:
			bg_color = Color(0.3, 0.85, 0.55)

		# Sombra
		canvas.draw_circle(center + Vector2(2, 4), base_radius, Color(0, 0, 0, 0.35))
		# Base da peça
		canvas.draw_circle(center, base_radius, bg_color)
		# Borda
		var border_color = Color(0.15, 0.15, 0.18) if is_white else Color(0.06, 0.06, 0.08)
		canvas.draw_arc(center, base_radius, 0, TAU, 24, border_color, 2.0)

		# Anel interno de relevo
		canvas.draw_arc(center, base_radius * 0.65, 0, TAU, 16, border_color, 1.5)

		# Distinção de Dama
		if data.is_king:
			var crown_col = Color(1.0, 0.84, 0.2) if is_white else Color(0.85, 0.2, 0.25)
			canvas.draw_circle(center, base_radius * 0.35, crown_col)
			canvas.draw_arc(center, base_radius * 0.35, 0, TAU, 12, Color(0.1, 0.1, 0.1, 0.8), 1.5)
