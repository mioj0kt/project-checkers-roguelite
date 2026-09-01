class_name ShopManager
extends RefCounted

const BASE_REROLL_COST: int = 4
var current_reroll_cost: int = 4

# Preços base por raridade (A SER BALANCEADO)
const RARITY_PRICES = {
	PieceData.Rarity.COMMON: 4,
	PieceData.Rarity.UNCOMMON: 7,
	PieceData.Rarity.RARE: 11,
	PieceData.Rarity.LEGENDARY: 16
}

# Pesos de sorteio padrão (A SER BALANCEADO)
const RARITY_WEIGHTS = {
	PieceData.Rarity.COMMON: 60,
	PieceData.Rarity.UNCOMMON: 28,
	PieceData.Rarity.RARE: 10,
	PieceData.Rarity.LEGENDARY: 2
}

func reset_reroll_cost() -> void:
	current_reroll_cost = BASE_REROLL_COST

func increase_reroll_cost() -> void:
	current_reroll_cost += 2

# Gera uma instância de peça aleatória baseada nas raridades
func generate_random_piece(force_min_rarity: PieceData.Rarity = PieceData.Rarity.COMMON) -> PieceData:
	var roll = randi() % 100
	var chosen_rarity = PieceData.Rarity.COMMON

	if force_min_rarity == PieceData.Rarity.RARE:
		chosen_rarity = PieceData.Rarity.RARE if roll < 80 else PieceData.Rarity.LEGENDARY
	else:
		if roll < RARITY_WEIGHTS[PieceData.Rarity.LEGENDARY]:
			chosen_rarity = PieceData.Rarity.LEGENDARY
		elif roll < RARITY_WEIGHTS[PieceData.Rarity.LEGENDARY] + RARITY_WEIGHTS[PieceData.Rarity.RARE]:
			chosen_rarity = PieceData.Rarity.RARE
		elif roll < RARITY_WEIGHTS[PieceData.Rarity.LEGENDARY] + RARITY_WEIGHTS[PieceData.Rarity.RARE] + RARITY_WEIGHTS[PieceData.Rarity.UNCOMMON]:
			chosen_rarity = PieceData.Rarity.UNCOMMON
		else:
			chosen_rarity = PieceData.Rarity.COMMON

	var pool: Array[PieceData] = []
	match chosen_rarity:
		PieceData.Rarity.COMMON:
			pool = [PieceData.new()]
		PieceData.Rarity.UNCOMMON:
			pool = [PieceCactus.new(), PieceSpring.new()]
		PieceData.Rarity.RARE:
			pool = [PieceTank.new(), PieceGhost.new(), PieceWeb.new(), PieceMidas.new()]
		PieceData.Rarity.LEGENDARY:
			pool = [PieceFire.new(), PieceFlyingKing.new()]

	return pool.pick_random().clone()

func get_piece_price(piece: PieceData) -> int:
	return RARITY_PRICES.get(piece.rarity, 5)

# Gera os Booster Packs da loja
func generate_booster_packs() -> Array[Dictionary]:
	return [
		{
			"id": "standard_pack",
			"name": "PACOTE BASICO",
			"price": 6,
			"desc": "Escolha 1 de 3 pecas variadas.",
			"min_rarity": PieceData.Rarity.COMMON
		},
		{
			"id": "rare_pack",
			"name": "PACOTE ARCANO",
			"price": 10,
			"desc": "Escolha 1 de 3 pecas raras ou superiores.",
			"min_rarity": PieceData.Rarity.RARE
		}
	]
