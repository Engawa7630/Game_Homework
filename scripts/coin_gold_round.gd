extends Area2D
signal collected

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node2D) -> void:
	if body.has_method("add_coin"):
		body.add_coin()   # 增加金币计数
	queue_free() # 金币消失


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
