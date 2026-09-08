class_name MapView
extends Node2D

# Configurações do Tabuleiro
const TILE_SIZE: float = 64.0
const BOARD_TILE_LIGHT: Color = Color(0.16, 0.18, 0.24)
const BOARD_TILE_DARK: Color = Color(0.10, 0.11, 0.16)
const BOARD_BORDER_COLOR: Color = Color(0.06, 0.07, 0.1, 0.6)

const TILES_PER_LAYER: int = 3
const TILES_BETWEEN_NODES: int = 2

@export_group("Linhas")
@export var default_line_color: Color = Color(0.3, 0.35, 0.45, 0.7)
@export var active_line_color: Color = Color(1.0, 0.84, 0.2, 1.0)
@export var active_line_width: float = 6.0

@onready var lines_container = $LinesContainer
@onready var nodes_container = $NodesContainer
@onready var camera: Camera2D = $Camera2D

var generator = MapGenerator.new()
var node_buttons: Dictionary = {}
var lines_dictionary: Dictionary = {}

var player_pawn: MapPlayerPawn
var is_traveling: bool = false

var inventory_ui: InventoryUI
var hud_bar: HUDBar

func _ready() -> void:
	randomize()
	z_index = 0
	_setup_map_ui()
	_setup_player_pawn()

	if RunManager.map_data.is_empty():
		RunManager.map_data = generator.generate_map()
		_position_nodes(RunManager.map_data)
		if not RunManager.map_data.is_empty() and not RunManager.map_data[0].is_empty():
			RunManager.current_node = RunManager.map_data[0][0]

	_draw_lines(RunManager.map_data)
	_instantiate_node_ui(RunManager.map_data)
	_restore_visited_connections()

	if RunManager.current_node != null:
		player_pawn.set_initial_position(RunManager.current_node.position, TILE_SIZE)
		_set_current_node(RunManager.current_node, false)

func _setup_player_pawn() -> void:
	player_pawn = MapPlayerPawn.new()
	add_child(player_pawn)

func _setup_map_ui() -> void:
	# Instancia a barra lateral padronizada
	hud_bar = HUDBar.new()
	add_child(hud_bar)
	hud_bar.open_laws_requested.connect(toggle_inventory)

	# Grimório de Leis (inventário)
	var canvas = CanvasLayer.new()
	canvas.name = "MapInventoryLayer"
	canvas.layer = 110
	add_child(canvas)

	inventory_ui = InventoryUI.new()
	canvas.add_child(inventory_ui)
	inventory_ui.setup()

func toggle_inventory() -> void:
	if inventory_ui:
		inventory_ui.toggle_visibility()

func _input(event: InputEvent) -> void:
	if is_traveling:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB or event.keycode == KEY_I:
			toggle_inventory()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			if inventory_ui and inventory_ui.visible:
				inventory_ui.visible = false
				get_viewport().set_input_as_handled()

func _position_nodes(layers: Array[Array]) -> void:
	for layer_index in range(layers.size()):
		var layer = layers[layer_index]
		var total_nodes = layer.size()
		var grid_row = -layer_index * TILES_PER_LAYER
		var start_col = -int((total_nodes - 1) * TILES_BETWEEN_NODES / 2.0)
		
		for node_index in range(total_nodes):
			var node: MapNode = layer[node_index]
			var grid_col = start_col + (node_index * TILES_BETWEEN_NODES)
			
			if (grid_row + grid_col) % 2 == 0:
				grid_col += 1

			node.position = Vector2(grid_col * TILE_SIZE, grid_row * TILE_SIZE)

func _draw_lines(layers: Array[Array]) -> void:
	for layer in layers:
		for node in layer:
			for child in node.children:
				var line = Line2D.new()
				line.add_point(node.position)
				line.add_point(child.position)
				line.width = 3.5
				line.default_color = default_line_color
				lines_container.add_child(line)
				var connection_key = _get_connection_key(node, child)
				lines_dictionary[connection_key] = line

func _restore_visited_connections() -> void:
	for key in RunManager.visited_connections:
		if lines_dictionary.has(key):
			var line: Line2D = lines_dictionary[key]
			line.default_color = active_line_color
			line.width = active_line_width

func _get_connection_key(parent: MapNode, child: MapNode) -> String:
	return str(parent.id) + "->" + str(child.id)

func _instantiate_node_ui(layers: Array[Array]) -> void:
	for layer in layers:
		for node in layer:
			var btn = Button.new()
			btn.text = node.get_display_title()

			if node.type == MapNode.NodeType.Chefe:
				btn.custom_minimum_size = Vector2(110, 60)
			elif node.type in [MapNode.NodeType.Duelo, MapNode.NodeType.DueloForte]:
				btn.custom_minimum_size = Vector2(100, 54)
			else:
				btn.custom_minimum_size = Vector2(90, 46)

			btn.size = btn.custom_minimum_size
			btn.position = node.position - (btn.size / 2.0)
			btn.add_theme_font_size_override("font_size", 16)
			btn.pressed.connect(_on_node_clicked.bind(node))
			nodes_container.add_child(btn)
			node_buttons[node] = btn

func _set_current_node(node: MapNode, animate_line: bool = true) -> void:
	if RunManager.current_node and RunManager.current_node != node:
		var key = _get_connection_key(RunManager.current_node, node)
		if not RunManager.visited_connections.has(key):
			RunManager.visited_connections.append(key)
		if animate_line:
			_highlight_connection(RunManager.current_node, node)

	RunManager.current_node = node
	_update_nodes_visual_state()
	_move_camera_to_node(node)

func _update_nodes_visual_state() -> void:
	for node in node_buttons:
		var btn: Button = node_buttons[node]
		var base_border = node.get_color()
		
		if node == RunManager.current_node:
			btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.12, 0.22, 0.16, 0.98), Color(0.3, 1.0, 0.5)))
			btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.modulate = Color.WHITE
		elif RunManager.current_node and node in RunManager.current_node.children:
			btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.12, 0.14, 0.2, 0.98), base_border))
			btn.add_theme_stylebox_override("hover", PixelUI.make_bevel_card(Color(0.18, 0.22, 0.3, 0.98), base_border.lightened(0.3)))
			btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			btn.modulate = Color.WHITE
		else:
			btn.add_theme_stylebox_override("normal", PixelUI.make_bevel_card(Color(0.08, 0.09, 0.12, 0.85), Color(0.25, 0.28, 0.35, 0.7)))
			btn.add_theme_color_override("font_color", Color(0.45, 0.48, 0.55))
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.modulate = Color(0.6, 0.6, 0.65, 0.75)

func _on_node_clicked(node: MapNode) -> void:
	if is_traveling:
		return

	if inventory_ui and inventory_ui.visible:
		inventory_ui.visible = false

	is_traveling = true
	_set_current_node(node, true)
	
	await player_pawn.jump_to_node(node.position, TILE_SIZE)
	
	RunManager.current_board_size = node.board_size
	RunManager.current_node_type = node.type
	
	match node.type:
		MapNode.NodeType.Duelo, MapNode.NodeType.DueloForte, MapNode.NodeType.Chefe:
			get_tree().call_deferred("change_scene_to_file", "res://main.tscn")
		MapNode.NodeType.Loja:
			get_tree().call_deferred("change_scene_to_file", "res://shop_view.tscn")
		_:
			is_traveling = false

func _highlight_connection(parent: MapNode, child: MapNode) -> void:
	var connection_key = _get_connection_key(parent, child)
	if lines_dictionary.has(connection_key):
		var line: Line2D = lines_dictionary[connection_key]
		var tween = create_tween().set_parallel(true)
		tween.tween_property(line, "default_color", active_line_color, 0.3)
		tween.tween_property(line, "width", active_line_width, 0.3)

func _move_camera_to_node(target_node: MapNode) -> void:
	var tween = create_tween()
	tween.tween_property(camera, "position:y", target_node.position.y, 0.85)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func _draw() -> void:
	var vp_size = get_viewport_rect().size
	var cam_y = camera.position.y if camera != null else 0.0
	
	var start_x = -vp_size.x * 1.5
	var end_x = vp_size.x * 1.5
	var start_y = cam_y - vp_size.y * 1.5
	var end_y = cam_y + vp_size.y * 1.5

	var col_start = int(floor(start_x / TILE_SIZE))
	var col_end = int(ceil(end_x / TILE_SIZE))
	var row_start = int(floor(start_y / TILE_SIZE))
	var row_end = int(ceil(end_y / TILE_SIZE))

	for r in range(row_start, row_end):
		for c in range(col_start, col_end):
			var tile_rect = Rect2((c * TILE_SIZE) - (TILE_SIZE / 2.0), (r * TILE_SIZE) - (TILE_SIZE / 2.0), TILE_SIZE, TILE_SIZE)
			var is_light = (r + c) % 2 == 0
			var col = BOARD_TILE_LIGHT if is_light else BOARD_TILE_DARK
			
			draw_rect(tile_rect, col)
			draw_rect(tile_rect, BOARD_BORDER_COLOR, false, 1.0)
