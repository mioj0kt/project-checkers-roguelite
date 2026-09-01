class_name PieceSpring
extends PieceData

func _init():
	id = "spring"
	name = "Mola"
	rarity = Rarity.UNCOMMON
	texture_white_path = "res://assets/pieces/spring-white.png"
	texture_black_path = "res://assets/pieces/spring-black.png"     
	texture_white_king_path = "res://assets/pieces/spring-white-king.png"
	texture_black_king_path = "res://assets/pieces/spring-black-king.png"
	description = "Salto Longo! Move-se avançando 2 casas de uma vez. Pode dar 1 passo para alcançar a última linha e virar dama."
	color_override = Color(0.3, 0.7, 1.0)

# Em GDScript, NÃO se usa 'override func', apenas declaramos a func diretamente
func get_step_distance() -> int:
	return 2
