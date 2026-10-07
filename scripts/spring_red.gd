extends Area2D
@export var launch_speed: float = 400.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(func(b: Node2D) -> void:
		if b is CharacterBody2D:
			b.velocity.y = -launch_speed      # 向上为负
			b.flying = false                  # 若玩家正飞着，落地感更自然
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
