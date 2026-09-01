# run_manager.gd
extends Node

var current_board_size: Vector2i = Vector2i(8, 8)
var current_node_type: int = 1
var inventory: InventoryManager = null
var gold: int = 0

var map_data: Array[Array] = []
var current_node: MapNode = null
var visited_connections: Array[String] = []

func _ready():
	start_new_run()

func start_new_run():
	gold = 0
	current_board_size = Vector2i(8, 8)
	current_node_type = 1
	inventory = InventoryManager.new()
	
	for i in range(8):
		inventory.add_piece_to_inventory(PieceData.new())

	# Adiciona todas as peças especiais para testar
	inventory.add_piece_to_inventory(PieceCactus.new())
	inventory.add_piece_to_inventory(PieceSpring.new())
	inventory.add_piece_to_inventory(PieceFire.new())
	inventory.add_piece_to_inventory(PieceFlyingKing.new())
	inventory.add_piece_to_inventory(PieceTank.new())
	inventory.add_piece_to_inventory(PieceGhost.new())
	inventory.add_piece_to_inventory(PieceWeb.new())
	inventory.add_piece_to_inventory(PieceMidas.new())

	map_data = []
	current_node = null
	visited_connections = []

func add_gold(amount: int) -> void:
	gold += amount

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false
