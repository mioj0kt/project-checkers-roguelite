class_name CoinFlipView
extends Node2D

signal flip_completed(player_won_white: bool)

var is_animating: bool = false
var is_finished: bool = false
var show_coin: bool = false
var is_white_side: bool = true
var coin_center: Vector2 = Vector2.ZERO
var cell_size: float = 64.0

var flip_scale_x: float = 1.0
var toss_scale: float = 1.0

var active_tween: Tween
var active_timer: SceneTreeTimer
var result_label: Label

const WHITE_SPRITE_PATH = "res://assets/sprites/pieces/white-king.png"
const BLACK_SPRITE_PATH = "res://assets/sprites/pieces/black-king.png"

var white_texture: Texture2D
var black_texture: Texture2D

func _ready() -> void:
	if ResourceLoader.exists(WHITE_SPRITE_PATH):
		white_texture = load(WHITE_SPRITE_PATH)
	if ResourceLoader.exists(BLACK_SPRITE_PATH):
		black_texture = load(BLACK_SPRITE_PATH)

	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 42)
	result_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	result_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 1.0))
	result_label.add_theme_constant_override("outline_size", 8)
	result_label.visible = false
	add_child(result_label)

func play_toss(p_center: Vector2, p_cell_size: float) -> void:
	_kill_tweens()

	coin_center = p_center
	cell_size = p_cell_size
	is_animating = true
	is_finished = false
	show_coin = true
	flip_scale_x = 1.0
	toss_scale = 1.0
	result_label.visible = false

	var vp_size = get_viewport_rect().size
	result_label.position = Vector2((vp_size.x - 700) / 2.0, coin_center.y - cell_size * 2.2)
	result_label.size = Vector2(700, 60)

	active_tween = create_tween()
	active_tween.set_parallel(true)

	# 1. Efeito de Altura
	active_tween.tween_property(self, "toss_scale", 1.85, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(self, "toss_scale", 1.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(0.65)

	# 2. Giro da Moeda
	var total_flips = 9
	for i in range(total_flips):
		var delay = i * 0.14
		active_tween.tween_method(func(v): flip_scale_x = v; queue_redraw(), 1.0, 0.0, 0.07).set_delay(delay)
		active_tween.tween_callback(func(): is_white_side = not is_white_side).set_delay(delay + 0.07)
		active_tween.tween_method(func(v): flip_scale_x = v; queue_redraw(), 0.0, 1.0, 0.07).set_delay(delay + 0.07)

	var player_won = (randi() % 2 == 0)
	active_tween.chain().tween_callback(func(): _finish_flip(player_won))

func skip_spin() -> void:
	if not is_animating or is_finished:
		return

	_kill_tweens()
	var player_won = (randi() % 2 == 0)
	_finish_flip(player_won)

func _kill_tweens() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		active_tween = null

func _finish_flip(player_won: bool) -> void:
	if is_finished:
		return
	is_finished = true
	is_animating = false
	_kill_tweens()

	is_white_side = player_won
	flip_scale_x = 1.0
	toss_scale = 1.0

	result_label.text = "VOCE JOGA COM AS BRANCAS!" if player_won else "VOCE JOGA COM AS PRETAS!"
	result_label.visible = true
	queue_redraw()

	active_timer = get_tree().create_timer(1.4)
	await active_timer.timeout

	show_coin = false
	result_label.visible = false
	queue_redraw()

	flip_completed.emit(player_won)

func _draw() -> void:
	if not show_coin:
		return

	var current_tex = white_texture if is_white_side else black_texture
	var base_diameter = cell_size * 0.95 * toss_scale
	var w = base_diameter * abs(flip_scale_x)
	var h = base_diameter

	if w <= 1.0:
		return

	var dest_rect = Rect2(coin_center.x - (w / 2.0), coin_center.y - (h / 2.0), w, h)

	var height_factor = (toss_scale - 1.0) / 0.85
	var shadow_offset = Vector2(4 + height_factor * 12.0, 6 + height_factor * 20.0)
	var shadow_scale = 1.0 + (height_factor * 0.25)
	var shadow_w = w * shadow_scale
	var shadow_h = h * shadow_scale
	var shadow_rect = Rect2(
		coin_center.x - (shadow_w / 2.0) + shadow_offset.x,
		coin_center.y - (shadow_h / 2.0) + shadow_offset.y,
		shadow_w,
		shadow_h
	)
	var shadow_alpha = clamp(0.45 - (height_factor * 0.2), 0.2, 0.45)

	if current_tex != null:
		draw_texture_rect(current_tex, shadow_rect, false, Color(0, 0, 0, shadow_alpha))
		draw_texture_rect(current_tex, dest_rect, false, Color.WHITE)
	else:
		var bg_col = Color(0.92, 0.92, 0.95) if is_white_side else Color(0.18, 0.2, 0.24)
		draw_rect(shadow_rect, Color(0, 0, 0, shadow_alpha))
		draw_rect(dest_rect, bg_col)
		draw_rect(dest_rect, Color(0.08, 0.08, 0.1), false, 2.0)
