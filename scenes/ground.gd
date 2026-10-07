extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		if body.has_method("add_death"):
			body.add_death()    # 增加死亡次数
		# 传送回重生点	
		body.global_position = body.get_meta("spawn_point", Vector2(102, 132))
		body.velocity = Vector2.ZERO
