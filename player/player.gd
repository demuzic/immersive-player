extends CharacterBody3D

@onready var head:Node3D = get_node("Head")
@onready var camera:Camera3D = get_node("Head/camera")
@onready var shack_gen:Node3D = get_node("shack_generator")
@onready var ShapeCast:ShapeCast3D = get_node("CollisionShape3D/ShapeCast3D")
@onready var Shape:CollisionShape3D = get_node("CollisionShape3D")
@onready var step_interval:Timer = get_node("step_interval")
@onready var anim_headbob = get_node("Head/head_animation/AnimationTree")

@export var enable:bool = true
@export_category("KEYS")
@export var action:Dictionary = {"up": "ui_up", "down":"ui_down", "right":"ui_right","left":"ui_left", "run":"run","crough":"crough"}

@export_category("MOVEMENT")
@export var acceleration_coefficient:float = 7
@export var deceleration_coefficient:float = 10
@export var air_control = 5
@export var floor_control = 10
@export var mouse_sensibility:float = 500
@export var head_coefficient:Vector2 = Vector2(20,20)
var dir:Vector2 = Vector2.ZERO
var simple_dir:Vector2 = Vector2.ZERO
var relative_head:Vector3 = Vector3.ZERO
var speed = 4
var y_axis:float = 0
var motion:float = 0

@export_category("MOVEMENT MODE")
@export var run_speed:float = 6
@export var idle_speed:float = 4
@export var crough_speed:float = 2
@export var transition_speed:float = 10
@export var crough_transition_speed:float = 7
@export var crough_lock:bool = true
var state:int = 1 # 0 = run, 1 = idle, 2 = crough
var head_height:float
var headbob_blend:float = 0
var anim_state:float = 0

func _ready() -> void:
	unfocus()
func _process(delta: float) -> void:
	
	
	
	#translation
	var move_coe:float = 0.0
	
	if simple_dir == Vector2.ZERO: 
		move_coe = deceleration_coefficient
		
	else: 
		move_coe = acceleration_coefficient
		
		
		if step_interval.is_stopped():
			
			step()
			step_interval.start()
	dir = lerp(dir, simple_dir, move_coe * delta)
	
	if is_on_floor(): 
		y_axis = 0
	else:
		y_axis += get_gravity().y * delta
		
	var final_dir = Vector3(dir.x * speed, y_axis, dir.y * speed) * transform.basis * Vector3(-1,1,1)
	
	velocity = final_dir 
	move_and_slide()
	
	#rotation
	head.rotation.x = lerp_angle(head.rotation.x, relative_head.x, head_coefficient.y * delta)
	head.rotation.y = lerp_angle(head.rotation.y, relative_head.y, head_coefficient.x * delta)
	
	var head_control_coefficient:float = 0
	if is_on_floor(): head_control_coefficient = floor_control
	else: head_control_coefficient = air_control
	
	
	rotation.y = lerp_angle(rotation.y, head.rotation.y, head_control_coefficient * delta)
	
	
	#movement transition
	
	if enable:
		if crough_lock:
			if Input.is_action_pressed(action["run"]):
				state = 0
			elif Input.is_action_just_pressed(action["crough"]):
				if state != 2:
					state = 2
				else:
					if ShapeCast.get_collision_count() <= 2: state = 1
			if Input.is_action_just_released(action["run"]):
				if ShapeCast.get_collision_count() <= 2: state = 1
			
		else:
			if Input.is_action_pressed(action["run"]):
				state = 0
			elif Input.is_action_pressed(action["crough"]):
				state = 2
			else:
				if ShapeCast.get_collision_count() <= 2: state = 1
	
	match state:
		0:
			speed = move_toward(speed, run_speed, delta * transition_speed)
			
			Shape.shape.height = lerp(Shape.shape.height, 2., delta * crough_transition_speed)
			Shape.position.y = lerp(Shape.position.y, 1., delta * crough_transition_speed)
			head_height = lerp(head_height, 1.8, delta * crough_transition_speed)
		
			anim_state = -1
		1:
			speed = move_toward(speed, idle_speed, delta * transition_speed)
			
			Shape.shape.height = lerp(Shape.shape.height, 2., delta * crough_transition_speed)
			Shape.position.y = lerp(Shape.position.y, 1., delta * crough_transition_speed)
			head_height = lerp(head_height, 1.8, delta * crough_transition_speed)
			
			anim_state = 0
		
		2:
			speed = move_toward(speed, crough_speed, delta * transition_speed)
			
			Shape.shape.height = lerp(Shape.shape.height, 1.0, delta * crough_transition_speed)
			Shape.position.y = lerp(Shape.position.y, 0.6, delta * crough_transition_speed)
			head_height = lerp(head_height, 1., delta * crough_transition_speed)
			
	
	head.global_position = global_position + Vector3(0,head_height,0)
	ShapeCast.global_position = head.global_position
	
	#animation headbob
	
	if simple_dir == Vector2.ZERO:
		anim_state = 0
	else:
		match state:
			0: anim_state = 2
			1: anim_state = 1
			2: anim_state = -1
	

	headbob_blend = move_toward(headbob_blend, anim_state, delta)
	anim_headbob["parameters/blend/blend_position"] = headbob_blend
	print(anim_headbob["parameters/blend/blend_position"])
	
	
func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_3):
		shack_gen.camera_shack(shack_gen.gen_random_points(4,0.07,0.07,0.8),1.5,0.07)
	if Input.is_key_pressed(KEY_2):
		focus()
	if Input.is_key_pressed(KEY_1):
		unfocus()
	#basic input movement
	if Input.is_key_pressed(KEY_C):
		motion = 0.0
	if enable: 
		simple_dir = Vector2(-int(Input.is_action_pressed(action["right"])) + int(Input.is_action_pressed(action["left"])), \
	-int(Input.is_action_pressed(action["up"])) + int(Input.is_action_pressed(action["down"])) ).normalized()
	#head movement
		if event is InputEventMouseMotion:
			var movement = event.relative
			relative_head.x -= movement.y/mouse_sensibility
			relative_head.y -= movement.x/mouse_sensibility
			relative_head.x = clampf(relative_head.x,deg_to_rad(-90),deg_to_rad(90))

func step(): #when step_interval timeout (each time = one step)
	print("step")


func focus():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	enable = 1
func unfocus():
	simple_dir = Vector2(0,0)
	enable = 0
	
