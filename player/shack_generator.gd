extends Node3D
@export var curve:Curve
@onready var player:CharacterBody3D = get_node("..")
var step:float = 1
var _speed:float = 1
var _magnitude:float = 10
var inv:PackedInt32Array = [-1,1]
var hx:int
var vx:int

func gen_random_points(Amount:int, dist_rand:float, amp_rand:float, max_amp:float) -> PackedVector2Array:
	var vector_array: PackedVector2Array
	vector_array.resize(Amount + 2)
	var dist:float = 1.0/(Amount + 1.0)
	var amp:float = max_amp/Amount
	var inv = 1
	for i in range(0, vector_array.size()):
		if i % 2 == 0: inv = 1
		else: inv = -1
		
		if i == 0:
			vector_array[0] = Vector2.ZERO
		else:
			vector_array[i] = Vector2(dist * i + randf_range(-dist_rand,dist_rand),inv * (1 - amp * (i - 1) + randf_range(-amp_rand,amp_rand)))
		
		vector_array[Amount + 1] = Vector2(1,0)
	return vector_array

func gen_curve(vector_array: PackedVector2Array) -> void:
	curve.clear_points()
	for i in range(0, vector_array.size()):
		curve.add_point(vector_array[i])
	
	curve.bake_resolution = 1000
	curve.bake()
	pass

func camera_shack(vector_array: PackedVector2Array, speed:float, magnitude:float):
	_speed = speed
	_magnitude = magnitude
	gen_curve(vector_array)
	hx = inv[randi_range(0,1)]
	vx = inv[randi_range(0,1)]
	step = 0
	
func _process(delta: float) -> void:
	step = move_toward(step, 1., delta * _speed)

	player.camera.h_offset = curve.sample(step) * _magnitude * hx
	player.camera.v_offset = curve.sample(step) * _magnitude * vx
