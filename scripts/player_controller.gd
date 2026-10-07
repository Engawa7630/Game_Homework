extends CharacterBody2D

@export_category("移动参数")
@export var double_press_interval := 0.3
@export var move_speed: float = 75.0
@export var acceleration: float = 600.0
@export var deceleration: float = 800.0
@export var jump_velocity: float = -190.0

@export var fly_duration: float = 0.5      # 最大飞行时间（秒）
@export var fly_cooldown: float = 5.0      # 飞行冷却时间（秒）

@export var dash_speed: float = 260.0     # 冲刺速度
@export var dash_time: float = 0.15       # 持续时间（秒）
@export var dash_cooldown: float = 0.6    # 冷却（秒）
# 结束显示标签
@onready var win_label = $"../../label/CanvasLayer/Label"
# 爬梯子参数
@export var climb_speed: float = 55.0
@onready var terrain_layer: TileMapLayer = get_tree().get_first_node_in_group("terrain")
var climbing := false


var coin_count: int = 0    # 金币计数
var death_count: int = 0   # 死亡计数

# 冲刺参数
var dashing : bool = false
var dash_dir := 1.0
var dash_timer := 0.0
var dash_cd := 0.0

@onready var sprite: Sprite2D = $Sprite2D

# 飞行参数
var flying : bool = false
var fly_timer: float = 0.0                 # 当前剩余飞行时间
var fly_cd: float = 0.0                    # 当前剩余冷却时间
var last_space_press_time := -1000

func _ready() -> void:
	# 游戏开始时隐藏通关Label
	if win_label:
		win_label.visible = false

# 两个计数
func add_coin() -> void:
	coin_count += 1
	
func add_death() -> void:
	death_count += 1


func _physics_process(delta: float) -> void:
	dash_cd = maxf(dash_cd - delta, 0.0)
	
	if fly_cd > 0.0:
		fly_cd = maxf(fly_cd - delta, 0.0)
	
	# 爬梯子检测
	climbing = false
	if !flying and is_on_ladder() and Input.get_axis("squat", "jump") != 0.0:
		climbing = true
	
	# 飞行计时与冷却处理
	if climbing:
		handle_ladder_movement()
	
	# 冲刺检测
	elif dashing:
		dash_timer -= delta
		velocity = Vector2(dash_dir * dash_speed, 0.0) 
		if dash_timer <= 0.0:
			dashing = false
			velocity.x *= 0.4
			
	elif flying:
		# 飞行中：先处理飞行倒计时
		fly_timer -= delta
		if fly_timer <= 0.0:
			# 飞行时间结束，进入冷却
			flying = false
			fly_cd = fly_cooldown
			velocity.y *= 0.5  # 缓和下落速度
			# 本帧立即应用重力和水平移动，避免突然悬空
			apply_gravity(delta)
			handle_jump()
			handle_horizontal_movement(delta)
		else:
			# 正常飞行中：处理飞行移动
			handle_vertical_movement(delta)
			handle_horizontal_movement(delta)
			
	else:
		# 普通状态（不飞、不冲刺、不爬梯）
		apply_gravity(delta)
		handle_jump()
		handle_horizontal_movement(delta)
		
	update_sprite_direction()
	move_and_slide()

# 实现重力
func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

# 飞行时的竖直控制
func handle_vertical_movement(delta:float) -> void:
	var direction := Input.get_axis("squat", "jump")  # s向下：-1，w向上：+1
	var target_speed := direction * jump_velocity    #乘以负值，实现正确的方向
	
	if direction != 0.0:
		velocity.y = move_toward(
				velocity.y,
				target_speed,
				acceleration * delta
		)
	else:
		velocity.y = move_toward(
				velocity.y,
				0.0,
				acceleration * delta
		)
	
# 实现左右移动
func handle_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := direction * move_speed
	#用move_toward实现平滑加速和减速
	if direction != 0.0:
		velocity.x = move_toward(
				velocity.x,
				target_speed,
				acceleration * delta
		)
	else:
		velocity.x = move_toward(
				velocity.x,
				0.0,
				deceleration * delta
		)

# 跳跃检测，只有在地面上按着跳跃键才给与向上速度
func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

# 根据水平速度正负性，改变自机图片方向
func update_sprite_direction() -> void:
	if velocity.x != 0.0:
		sprite.flip_h = velocity.x < 0.0
		
# 避免UI和系统拦截输入，避免长按按键会多次触发
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fly") and !event.is_echo():
		handle_space_pressed()
	if event.is_action_pressed("dash") and !event.is_echo():
		try_dash()
	
# 记录两次按空格的时间差，如果小于0.3秒，切换飞行模式
func handle_space_pressed() -> void:
	var current_time := Time.get_ticks_msec()
	var elapsed_time := current_time - last_space_press_time

	if elapsed_time <= double_press_interval * 1000.0:
		# 双击触发：只有不在飞行且冷却结束时才能起飞
		if not flying and fly_cd <= 0.0:
			flying = true
			fly_timer = fly_duration
			last_space_press_time = -1000  # 重置，防止连续触发
		else:
			# 冷却中或正在飞行，双击无效（可以在这里加音效或UI提示）
			print("飞行冷却中，剩余: ", fly_cd)
	else:
		last_space_press_time = current_time
		
# 冲刺：如果在冷却时间就返回，如果不在，就获取输入按键方向冲刺，或根据人物朝向冲刺
func try_dash() -> void:
	if dashing or dash_cd > 0.0:
		return
	var axis := Input.get_axis("move_left", "move_right")
	dash_dir = signf(axis) if axis != 0.0 else (-1.0 if sprite.flip_h else 1.0)
	dashing = true
	dash_timer = dash_time
	dash_cd = dash_cooldown
	
# 爬梯子
func handle_ladder_movement() -> void:
	velocity.y = Input.get_axis("jump", "squat") * climb_speed  
	velocity.x = 0.0   #锁定x轴不动

# 遍历检测玩家是否和梯子的Area2D重叠
func is_on_ladder() -> bool:
	for a in get_tree().get_nodes_in_group("ladder"):
		if (a as Area2D).overlaps_body(self):
			return true
	return false

# 结束游戏
func trigger_win() -> void:
	set_physics_process(false) # 停止玩家移动
	if win_label:
		# 设置文本并让Label显示出来
		win_label.text = "通关！\n获得金币数量: %d" % coin_count + "\n死亡次数: %d" % death_count
		win_label.visible = true
	print("通关！获得金币: ", coin_count)
