class_name CardHandUI
extends CanvasLayer

signal card_clicked_for_target(card: ActionCard, card_index: int)
signal card_drag_started(card: ActionCard, card_index: int)
signal card_drag_released(card: ActionCard, card_index: int, screen_pos: Vector2)
signal card_selection_cancelled()

const CARD_WIDTH: float = ActionCardVisual.CARD_WIDTH
const CARD_HEIGHT: float = ActionCardVisual.CARD_HEIGHT
const DRAG_THRESHOLD: float = 8.0

var deck_mgr: CardDeckManager
var hud_bar_ref: HUDBar
var cards_hbox: HBoxContainer
var card_tooltip: ActionCardTooltip

var previous_hand_count: int = 0
var selected_card_idx: int = -1

var is_dragging: bool = false
var drag_potential_card: ActionCard = null
var drag_potential_idx: int = -1
var drag_origin_ctrl: Control = null
var drag_start_mouse_pos: Vector2 = Vector2.ZERO
var drag_preview_control: Control = null
var drag_offset: Vector2 = Vector2.ZERO

func _init() -> void:
	layer = 85
	_build_ui()

func _build_ui() -> void:
	visible = true

	var root_ctrl = Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_ctrl)

	card_tooltip = ActionCardTooltip.new()
	add_child(card_tooltip)

	# Mão de Cartas centralizada na base
	cards_hbox = HBoxContainer.new()
	cards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_hbox.add_theme_constant_override("separation", 16)
	cards_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	cards_hbox.anchor_top = 1.0
	cards_hbox.anchor_bottom = 1.0
	cards_hbox.anchor_left = 0.0
	cards_hbox.anchor_right = 1.0
	cards_hbox.offset_top = -(CARD_HEIGHT + 20.0)
	cards_hbox.offset_bottom = -16.0
	cards_hbox.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root_ctrl.add_child(cards_hbox)

func setup(p_deck_mgr: CardDeckManager, p_hud_bar: HUDBar = null) -> void:
	deck_mgr = p_deck_mgr
	hud_bar_ref = p_hud_bar
	deck_mgr.hand_updated.connect(refresh_hand)
	previous_hand_count = 0
	refresh_hand()

func refresh_hand() -> void:
	_cleanup_drag_state()
	selected_card_idx = -1
	if card_tooltip:
		card_tooltip.hide_tooltip()

	var previous_count = previous_hand_count
	var new_count = deck_mgr.hand.size() if deck_mgr != null else 0
	previous_hand_count = new_count

	for child in cards_hbox.get_children():
		child.queue_free()

	if deck_mgr == null:
		return

	var new_widgets: Array[Control] = []
	for i in range(deck_mgr.hand.size()):
		var card = deck_mgr.hand[i]
		var card_widget = _create_card_widget(card, i)
		cards_hbox.add_child(card_widget)

		if i >= previous_count:
			card_widget.modulate.a = 0.0
			new_widgets.append(card_widget)

	if not new_widgets.is_empty():
		_process_draw_animations(new_widgets)

func _process_draw_animations(widgets: Array[Control]) -> void:
	await get_tree().process_frame
	for i in range(widgets.size()):
		var target_widget = widgets[i]
		if is_instance_valid(target_widget):
			_animate_draw_fly_in(target_widget, i * 0.12)

func _animate_draw_fly_in(target_widget: Control, delay: float) -> void:
	var start_pos = hud_bar_ref.get_draw_pile_global_pos() if hud_bar_ref != null else (Vector2(40.0, 400.0))

	var card_visual = target_widget.get_child(0) as ActionCardVisual
	var card_ref = card_visual.card if card_visual != null else null

	var flying_card = ActionCardVisual.new(card_ref, false)
	flying_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flying_card)
	flying_card.global_position = start_pos
	flying_card.scale = Vector2(0.60, 0.60)

	await get_tree().create_timer(delay).timeout
	if not is_instance_valid(target_widget):
		flying_card.queue_free()
		return

	var end_pos = target_widget.global_position
	var tween = create_tween().set_parallel(true)
	tween.tween_property(flying_card, "global_position", end_pos, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(flying_card, "scale", Vector2(1.0, 1.0), 0.35)

	await tween.finished
	flying_card.play_flip_reveal()
	await flying_card.flipped_face_up
	flying_card.queue_free()

	if is_instance_valid(target_widget):
		target_widget.modulate.a = 1.0

func _create_card_widget(card: ActionCard, idx: int) -> Control:
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	_update_card_border(container, idx == selected_card_idx)

	var visual = ActionCardVisual.new(card, true)
	container.add_child(visual)

	container.mouse_entered.connect(func():
		if not is_dragging and card_tooltip != null:
			var card_pos = container.global_position + Vector2(CARD_WIDTH / 2.0, 0.0)
			card_tooltip.show_tooltip(card, card_pos)
	)

	container.mouse_exited.connect(func():
		if card_tooltip != null:
			card_tooltip.hide_tooltip()
	)

	container.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag_potential_card = card
				drag_potential_idx = idx
				drag_origin_ctrl = container
				drag_start_mouse_pos = event.global_position
			else:
				if not is_dragging and drag_potential_card != null:
					_handle_card_click(idx, card)
				drag_potential_card = null
				drag_potential_idx = -1
				drag_origin_ctrl = null
	)

	return container

func _update_card_border(container: PanelContainer, is_selected: bool) -> void:
	var border_col = Color(1.0, 0.85, 0.2, 1.0) if is_selected else Color(0.3, 0.75, 1.0, 0.0)
	var bg_col = Color(0.0, 0.0, 0.0, 0.0)
	container.add_theme_stylebox_override("panel", PixelUI.make_bevel_card(bg_col, border_col))

func _handle_card_click(idx: int, card: ActionCard) -> void:
	if selected_card_idx == idx:
		cancel_selection()
		return

	selected_card_idx = idx
	_refresh_all_card_borders()
	card_clicked_for_target.emit(card, idx)

func _refresh_all_card_borders() -> void:
	var children = cards_hbox.get_children()
	for i in range(children.size()):
		var c = children[i] as PanelContainer
		if c:
			_update_card_border(c, i == selected_card_idx)

func _input(event: InputEvent) -> void:
	if drag_potential_card != null and not is_dragging:
		if event is InputEventMouseMotion:
			if event.global_position.distance_to(drag_start_mouse_pos) > DRAG_THRESHOLD:
				if card_tooltip:
					card_tooltip.hide_tooltip()
				_start_dragging(drag_potential_card, drag_potential_idx, drag_origin_ctrl)

	if is_dragging:
		if event is InputEventMouseMotion and drag_preview_control:
			drag_preview_control.global_position = event.position - drag_offset

			var vp_h = get_viewport().get_visible_rect().size.y
			var hand_y = vp_h - (CARD_HEIGHT + 24.0)
			var board_y = vp_h * 0.45
			var t = clampf(inverse_lerp(hand_y, board_y, event.position.y), 0.0, 1.0)

			var cur_scale = lerpf(1.0, 0.55, t)
			drag_preview_control.scale = Vector2(cur_scale, cur_scale)
			drag_preview_control.modulate.a = lerpf(0.95, 0.40, t)

		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			var drop_pos = event.position
			var card = drag_potential_card
			var idx = drag_potential_idx
			_cleanup_drag_state()
			card_drag_released.emit(card, idx, drop_pos)

		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_selection()

func _start_dragging(card: ActionCard, idx: int, origin_ctrl: Control) -> void:
	is_dragging = true
	selected_card_idx = idx
	_refresh_all_card_borders()

	if origin_ctrl:
		origin_ctrl.modulate = Color(1.0, 1.0, 1.0, 0.25)

	drag_preview_control = ActionCardVisual.new(card, true)
	drag_preview_control.pivot_offset = Vector2(CARD_WIDTH / 2.0, CARD_HEIGHT / 2.0)
	add_child(drag_preview_control)

	drag_offset = Vector2(CARD_WIDTH, CARD_HEIGHT) / 2.0
	drag_preview_control.global_position = drag_start_mouse_pos - drag_offset

	card_drag_started.emit(card, idx)

func _cleanup_drag_state() -> void:
	if drag_preview_control:
		drag_preview_control.queue_free()
		drag_preview_control = null

	is_dragging = false
	drag_potential_card = null
	drag_potential_idx = -1
	drag_origin_ctrl = null

	for child in cards_hbox.get_children():
		child.modulate = Color.WHITE

func cancel_selection(emit_signal: bool = true) -> void:
	if selected_card_idx == -1 and not is_dragging and drag_potential_card == null:
		return

	_cleanup_drag_state()
	selected_card_idx = -1
	_refresh_all_card_borders()

	if card_tooltip:
		card_tooltip.hide_tooltip()

	if emit_signal:
		card_selection_cancelled.emit()
