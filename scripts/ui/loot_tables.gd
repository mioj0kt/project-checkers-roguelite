class_name LootTables

# =========================================================
# BANCO DE DADOS CENTRAL (Adicione novas cartas/regras AQUI)
# =========================================================

static func get_all_rules() -> Array[RuleCard]:
	var rules: Array[RuleCard] = [
		RuleReverseMovement.new(),
		RuleOptionalCapture.new(),
		RuleEarlyPromotion.new(),
		RuleCarnage.new(),
		RuleRevenge.new(),
		RuleAllyHop.new(),
		RuleSoulMirror.new(),
		RuleSecondMove.new(),
		RulePowerCenter.new(),
		RuleBlood.new()
	]
	return rules

static func get_all_action_cards() -> Array[ActionCard]:
	var cards: Array[ActionCard] = [
		CardExtraTurn.new(),
		CardCoronation.new(),
		CardRetreat.new(),
		CardSacrifice.new(),
		CardRecruit.new(),
		CardVision.new(),
		CardRetaliation.new(),
		CardRebuild.new()
	]
	return cards

# =========================================================
# MÉTODOS DE SORTEIO PONDERADO
# =========================================================

static func get_random_rules(count: int, exclude_ids: Array[String] = []) -> Array[RuleCard]:
	var pool = get_all_rules().filter(func(r: RuleCard): return not exclude_ids.has(r.id))
	return pick_weighted_rules(pool, count)

static func get_random_action_cards(count: int, exclude_ids: Array[String] = []) -> Array[ActionCard]:
	var pool = get_all_action_cards().filter(func(c: ActionCard): return not exclude_ids.has(c.id))
	return pick_weighted_actions(pool, count)

static func pick_weighted_rules(available_pool: Array[RuleCard], count: int) -> Array[RuleCard]:
	var result: Array[RuleCard] = []
	var pool = available_pool.duplicate()

	while result.size() < count and not pool.is_empty():
		var total_weight = 0
		for rule in pool:
			total_weight += RuleCard.get_rarity_weight(rule.rarity)

		var roll = randi_range(1, total_weight)
		var accum = 0
		var chosen_idx = 0

		for i in range(pool.size()):
			accum += RuleCard.get_rarity_weight(pool[i].rarity)
			if roll <= accum:
				chosen_idx = i
				break

		result.append(pool[chosen_idx])
		pool.remove_at(chosen_idx)

	return result

static func pick_weighted_actions(available_pool: Array[ActionCard], count: int) -> Array[ActionCard]:
	var result: Array[ActionCard] = []
	var pool = available_pool.duplicate()

	while result.size() < count and not pool.is_empty():
		var total_weight = 0
		for card in pool:
			total_weight += ActionCard.get_rarity_weight(card.rarity)

		var roll = randi_range(1, total_weight)
		var accum = 0
		var chosen_idx = 0

		for i in range(pool.size()):
			accum += ActionCard.get_rarity_weight(pool[i].rarity)
			if roll <= accum:
				chosen_idx = i
				break

		result.append(pool[chosen_idx])
		pool.remove_at(chosen_idx)

	return result
