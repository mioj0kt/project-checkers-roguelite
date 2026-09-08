class_name MapNode
extends RefCounted

enum NodeType {
	Começo,
	Duelo,
	DueloForte,
	Evento,
	Loja,
	Melhoria,
	Chefe
}

var id: Vector2i
var type: NodeType = NodeType.Duelo
var position: Vector2 = Vector2.ZERO
var parents: Array[MapNode] = []
var children: Array[MapNode] = []

# Armazena Vector2i(linhas, colunas)
var board_size: Vector2i = Vector2i(8, 8)

func get_size_text() -> String:
	return "%dx%d" % [board_size.x, board_size.y]

func get_color() -> Color:
	match type:
		NodeType.Começo:
			return Color(0.18, 0.45, 0.28)
		NodeType.Duelo:
			return Color(0.24, 0.42, 0.65)
		NodeType.DueloForte, NodeType.Chefe:
			return Color(0.85, 0.22, 0.25)
		NodeType.Loja:
			return Color(0.9, 0.68, 0.18)
		NodeType.Evento:
			return Color(0.25, 0.75, 0.85)
		NodeType.Melhoria:
			return Color(0.65, 0.35, 0.85)
	return Color(0.5, 0.5, 0.5)

func get_display_title() -> String:
	var type_text = NodeType.keys()[type].to_upper()
	if type == NodeType.Chefe:
		return "CHEFAO\n[%s]" % get_size_text()
	elif type in [NodeType.Duelo, NodeType.DueloForte]:
		return "%s\n[%s]" % [type_text, get_size_text()]
	return type_text
