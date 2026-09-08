extends Node

var current_board_size: Vector2i = Vector2i(8, 8)
var current_node_type: int = 1
var gold: int = 0

var map_data: Array[Array] = []
var current_node: MapNode = null
var visited_connections: Array[String] = []
var active_rules: Array[RuleCard] = []

var player_deck: Array[ActionCard] = []

signal rules_updated()

func _ready():
	start_new_run()
	active_rules.clear()
	if player_deck.is_empty():
		_init_default_deck()

func add_rule(rule: RuleCard) -> bool:
	if active_rules.size() >= 6:
		return false
	active_rules.append(rule)
	rules_updated.emit()
	return true

func remove_rule(rule_id: String) -> void:
	for i in range(active_rules.size() - 1, -1, -1):
		if active_rules[i].id == rule_id:
			active_rules.remove_at(i)
			break
	rules_updated.emit()

func start_new_run():
	gold = 10000
	current_board_size = Vector2i(8, 8)
	current_node_type = 1
	map_data = []
	current_node = null
	visited_connections = []
	_init_default_deck()
	

func _init_default_deck() -> void:
	player_deck.clear()
	player_deck.append(CardRecruit.new())
	player_deck.append(CardCoronation.new())
	player_deck.append(CardCoronation.new())
	player_deck.append(CardCoronation.new())
	player_deck.append(CardCoronation.new())
	player_deck.append(CardCoronation.new())
	player_deck.append(CardCoronation.new())

func add_gold(amount: int) -> void:
	gold += amount

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false
