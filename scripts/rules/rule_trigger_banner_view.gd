class_name RuleTriggerBannerView
extends Node2D

func pop_rule_trigger(world_pos: Vector2, rule_name: String, color: Color = Color(1.0, 0.85, 0.3)) -> void:
	var label = Label.new()
	label.text = "⚡ %s" % rule_name.to_upper()
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.04, 0.05, 0.08, 1.0))
	label.add_theme_constant_override("outline_size", 6)
	label.z_index = 80
	label.position = world_pos - Vector2(50, 20)
	add_child(label)

	var tween = create_tween().set_parallel(true)
	# Sobe flutuando
	tween.tween_property(label, "position:y", world_pos.y - 52.0, 0.65)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Fade out gradual
	tween.tween_property(label, "modulate:a", 0.0, 0.65)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	await tween.finished
	label.queue_free()
